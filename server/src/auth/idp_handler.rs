use axum::{extract::State, Json};
use serde::Deserialize;
use sqlx::FromRow;
use tracing::{debug, error, info, warn};
use uuid::Uuid;

use super::{handlers::AuthResponse, handlers::UserInfo, service};
use crate::{
    app::AppState,
    error::{AppError, AppResult},
};

#[derive(Deserialize)]
pub struct IdpExchangeRequest {
    pub access_token: String,
    #[allow(dead_code)]
    pub refresh_token: Option<String>,
    #[allow(dead_code)]
    pub token_type: Option<String>,
    #[allow(dead_code)]
    pub expires_in: Option<i64>,
    #[allow(dead_code)]
    pub principal: Option<serde_json::Value>,
}

#[derive(FromRow)]
struct UserRow {
    id: Uuid,
    email: String,
    full_name: String,
    phone: Option<String>,
    role: String,
}

/// POST /api/v1/auth/idp-exchange
///
/// Mobile flow:
/// 1. App uses the official Base IdP Flutter SDK hosted-login flow.
/// 2. SDK exchanges the code with PKCE and fetches `/v1/me`.
/// 3. App POSTs `session.toServerPayload().toJson()` here.
/// 4. We verify the Base IdP PASETO signature against published Ed25519 keys.
/// 5. We upsert a Twende user keyed by (idp_issuer, idp_subject).
/// 6. We return our own Twende JWT pair for product API access.
pub async fn idp_exchange(
    State(state): State<AppState>,
    Json(req): Json<IdpExchangeRequest>,
) -> AppResult<Json<AuthResponse>> {
    info!(
        has_refresh_token = req
            .refresh_token
            .as_ref()
            .is_some_and(|v| !v.trim().is_empty()),
        token_type = req.token_type.as_deref().unwrap_or(""),
        expires_in = req.expires_in.unwrap_or_default(),
        principal_present = req.principal.is_some(),
        "idp exchange payload received"
    );

    let idp = state
        .base_idp
        .as_ref()
        .ok_or_else(|| AppError::Internal(anyhow::anyhow!("Base-IdP not configured")))?;

    if req.access_token.trim().is_empty() {
        warn!("idp exchange rejected: missing access_token");
        return Err(AppError::BadRequest("access_token is required".into()));
    }

    debug!("idp exchange verifying access token");
    let principal = idp
        .verify_access_token(&req.access_token)
        .await
        .map_err(|e| {
            warn!(error = %e, "idp exchange token verification failed");
            AppError::Unauthorized(format!("IdP token verification failed: {e}"))
        })?;

    let email = principal
        .email
        .clone()
        .unwrap_or_else(|| format!("{}@idp.local", principal.subject));
    let full_name = principal
        .name
        .clone()
        .unwrap_or_else(|| email.split('@').next().unwrap_or("Traveler").to_string());
    info!(
        idp_subject = %principal.subject,
        email = %email,
        "idp exchange principal verified"
    );

    // Upsert: match by (idp_issuer, idp_subject) first; fall back to email.
    debug!("idp exchange querying existing Twende user");
    let existing = sqlx::query_as::<_, UserRow>(
        "SELECT id, email, full_name, phone, role::text as role
         FROM users
         WHERE deleted_at IS NULL
           AND ((idp_issuer = $1 AND idp_subject = $2) OR email = $3)
         LIMIT 1",
    )
    .bind(&state.config.base_idp.issuer)
    .bind(&principal.subject)
    .bind(&email)
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        error!(error = %e, "idp exchange failed while querying Twende user");
        e
    })?;

    let user = if let Some(row) = existing {
        info!(user_id = %row.id, "idp exchange updating existing Twende user");
        sqlx::query(
            "UPDATE users
                SET idp_issuer = $1,
                    idp_subject = $2,
                    full_name = COALESCE(NULLIF($3, ''), full_name),
                    is_verified = TRUE,
                    updated_at = now()
              WHERE id = $4",
        )
        .bind(&state.config.base_idp.issuer)
        .bind(&principal.subject)
        .bind(&full_name)
        .bind(row.id)
        .execute(&state.db)
        .await
        .map_err(|e| {
            error!(user_id = %row.id, error = %e, "idp exchange failed to update Twende user");
            e
        })?;

        row
    } else {
        info!("idp exchange creating Twende user");
        sqlx::query_as::<_, UserRow>(
            "INSERT INTO users (id, email, full_name, role, idp_issuer, idp_subject, is_verified)
             VALUES ($1, $2, $3, 'operator'::user_role, $4, $5, TRUE)
             RETURNING id, email, full_name, phone, role::text as role",
        )
        .bind(Uuid::new_v4())
        .bind(&email)
        .bind(&full_name)
        .bind(&state.config.base_idp.issuer)
        .bind(&principal.subject)
        .fetch_one(&state.db)
        .await
        .map_err(|e| {
            error!(error = %e, "idp exchange failed to create Twende user");
            e
        })?
    };

    debug!(user_id = %user.id, role = %user.role, "idp exchange issuing Twende tokens");
    let access_token = service::generate_access_token(
        user.id,
        &user.role,
        &state.config.jwt.secret,
    )
    .map_err(|e| {
        error!(user_id = %user.id, error = %e, "idp exchange failed to issue Twende access token");
        e
    })?;
    let refresh_token = service::generate_refresh_token(
        user.id,
        &user.role,
        &state.config.jwt.refresh_secret,
    )
    .map_err(|e| {
        error!(user_id = %user.id, error = %e, "idp exchange failed to issue Twende refresh token");
        e
    })?;

    info!(user_id = %user.id, "idp exchange succeeded");
    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user: UserInfo {
            id: user.id,
            email: user.email,
            full_name: user.full_name,
            role: user.role,
            phone: user.phone,
        },
    }))
}
