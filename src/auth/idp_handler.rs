use axum::{extract::State, Json};
use serde::Deserialize;
use sqlx::FromRow;
use uuid::Uuid;

use super::{handlers::AuthResponse, handlers::UserInfo, service};
use crate::{
    app::AppState,
    error::{AppError, AppResult},
};

#[derive(Deserialize)]
pub struct IdpExchangeRequest {
    pub code: String,
    pub code_verifier: Option<String>,
    pub redirect_uri: Option<String>,
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
/// 1. App does PKCE in-browser → gets `code`
/// 2. App POSTs `{code, code_verifier, redirect_uri}` here
/// 3. We exchange the code for a Base-IdP PASETO token (using our client secret)
/// 4. We verify the PASETO signature against the IdP's published Ed25519 keys
/// 5. We upsert a Twende user keyed by (idp_issuer, idp_subject)
/// 6. We return our own Twende JWT pair so the mobile app uses the same auth as
///    the email/password flow downstream.
pub async fn idp_exchange(
    State(state): State<AppState>,
    Json(req): Json<IdpExchangeRequest>,
) -> AppResult<Json<AuthResponse>> {
    let idp = state
        .base_idp
        .as_ref()
        .ok_or_else(|| AppError::Internal(anyhow::anyhow!("Base-IdP not configured")))?;

    if req.code.trim().is_empty() {
        return Err(AppError::BadRequest("code is required".into()));
    }

    let redirect_uri = req
        .redirect_uri
        .as_deref()
        .unwrap_or(&state.config.base_idp.mobile_redirect_uri);

    let token_pair = idp
        .exchange_code(&req.code, req.code_verifier.as_deref(), Some(redirect_uri))
        .await
        .map_err(|e| AppError::Unauthorized(format!("IdP token exchange failed: {e}")))?;

    let principal = idp
        .verify_access_token(&token_pair.access_token)
        .await
        .map_err(|e| AppError::Unauthorized(format!("IdP token verification failed: {e}")))?;

    let email = principal
        .email
        .clone()
        .unwrap_or_else(|| format!("{}@idp.local", principal.subject));
    let full_name = principal
        .name
        .clone()
        .unwrap_or_else(|| email.split('@').next().unwrap_or("Traveler").to_string());

    // Upsert: match by (idp_issuer, idp_subject) first; fall back to email.
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
    .await?;

    let user = if let Some(row) = existing {
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
        .await?;

        row
    } else {
        sqlx::query_as::<_, UserRow>(
            "INSERT INTO users (id, email, full_name, role, idp_issuer, idp_subject, is_verified)
             VALUES ($1, $2, $3, 'traveler'::user_role, $4, $5, TRUE)
             RETURNING id, email, full_name, phone, role::text as role",
        )
        .bind(Uuid::new_v4())
        .bind(&email)
        .bind(&full_name)
        .bind(&state.config.base_idp.issuer)
        .bind(&principal.subject)
        .fetch_one(&state.db)
        .await?
    };

    let access_token =
        service::generate_access_token(user.id, &user.role, &state.config.jwt.secret)?;
    let refresh_token =
        service::generate_refresh_token(user.id, &user.role, &state.config.jwt.refresh_secret)?;

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

/// GET /api/v1/auth/idp/authorize-url
///
/// Helper for mobile clients: returns the constructed authorize URL given the
/// client-supplied PKCE challenge. Optional — mobile can also build it locally
/// using the publicly-known issuer + client_id.
#[derive(Deserialize)]
pub struct AuthorizeUrlQuery {
    pub code_challenge: String,
    #[serde(default)]
    pub state: Option<String>,
    #[serde(default)]
    pub redirect_uri: Option<String>,
}

pub async fn authorize_url(
    State(state): State<AppState>,
    axum::extract::Query(q): axum::extract::Query<AuthorizeUrlQuery>,
) -> AppResult<Json<serde_json::Value>> {
    let redirect = q
        .redirect_uri
        .unwrap_or_else(|| state.config.base_idp.mobile_redirect_uri.clone());
    let state_param = q.state.unwrap_or_else(|| Uuid::new_v4().to_string());

    let mut url = url::Url::parse(&format!(
        "{}/oauth2/authorize",
        state.config.base_idp.issuer
    ))
    .map_err(|e| AppError::Internal(anyhow::anyhow!("bad issuer url: {e}")))?;
    {
        let mut q_mut = url.query_pairs_mut();
        q_mut.append_pair("response_type", "code");
        q_mut.append_pair(
            "client_id",
            state
                .config
                .base_idp
                .client_id
                .as_deref()
                .unwrap_or_default(),
        );
        q_mut.append_pair("redirect_uri", &redirect);
        q_mut.append_pair("scope", "openid profile");
        q_mut.append_pair("state", &state_param);
        q_mut.append_pair("code_challenge", &q.code_challenge);
        q_mut.append_pair("code_challenge_method", "S256");
    }

    Ok(Json(serde_json::json!({
        "authorize_url": url.to_string(),
        "state": state_param,
        "redirect_uri": redirect,
        "client_id": state.config.base_idp.client_id.as_deref().unwrap_or_default(),
    })))
}
