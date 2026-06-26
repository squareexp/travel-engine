use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use super::{service, AuthUser};
use crate::{
    app::AppState,
    error::{AppError, AppResult},
};

#[derive(Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub full_name: String,
    pub phone: Option<String>,
    pub role: Option<String>,
}

#[derive(Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user: UserInfo,
}

#[derive(Serialize, FromRow)]
pub struct UserInfo {
    pub id: Uuid,
    pub email: String,
    pub full_name: String,
    pub role: String,
    pub phone: Option<String>,
}

pub async fn register(
    State(state): State<AppState>,
    Json(req): Json<RegisterRequest>,
) -> AppResult<Json<AuthResponse>> {
    let role = req.role.as_deref().unwrap_or("traveler");
    if !["traveler", "operator"].contains(&role) {
        return Err(AppError::BadRequest(
            "Role must be 'traveler' or 'operator'".to_string(),
        ));
    }

    let existing: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM users WHERE email = $1 AND deleted_at IS NULL")
            .bind(&req.email)
            .fetch_one(&state.db)
            .await?;

    if existing > 0 {
        return Err(AppError::Conflict("Email already registered".to_string()));
    }

    let password_hash = service::hash_password(&req.password)?;
    let user_id = Uuid::new_v4();

    let row = sqlx::query_as::<_, UserInfo>(
        "INSERT INTO users (id, email, password_hash, full_name, phone, role)
         VALUES ($1, $2, $3, $4, $5, $6::user_role)
         RETURNING id, email, full_name, phone, role::text as role",
    )
    .bind(user_id)
    .bind(&req.email)
    .bind(&password_hash)
    .bind(&req.full_name)
    .bind(req.phone.as_deref())
    .bind(role)
    .fetch_one(&state.db)
    .await?;

    let access_token = service::generate_access_token(row.id, &row.role, &state.config.jwt.secret)?;
    let refresh_token =
        service::generate_refresh_token(row.id, &row.role, &state.config.jwt.refresh_secret)?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user: row,
    }))
}

pub async fn login(
    State(state): State<AppState>,
    Json(req): Json<LoginRequest>,
) -> AppResult<Json<AuthResponse>> {
    #[derive(FromRow)]
    struct LoginRow {
        id: Uuid,
        email: String,
        full_name: String,
        phone: Option<String>,
        password_hash: Option<String>,
        role: String,
    }

    let row = sqlx::query_as::<_, LoginRow>(
        "SELECT id, email, full_name, phone, password_hash, role::text as role
         FROM users WHERE email = $1 AND deleted_at IS NULL",
    )
    .bind(&req.email)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::Unauthorized("Invalid email or password".to_string()))?;

    let hash = row
        .password_hash
        .as_deref()
        .ok_or_else(|| AppError::Unauthorized("Account uses OAuth login".to_string()))?;

    if !service::verify_password(&req.password, hash)? {
        return Err(AppError::Unauthorized(
            "Invalid email or password".to_string(),
        ));
    }

    let access_token = service::generate_access_token(row.id, &row.role, &state.config.jwt.secret)?;
    let refresh_token =
        service::generate_refresh_token(row.id, &row.role, &state.config.jwt.refresh_secret)?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user: UserInfo {
            id: row.id,
            email: row.email,
            full_name: row.full_name,
            role: row.role,
            phone: row.phone,
        },
    }))
}

pub async fn refresh(
    State(state): State<AppState>,
    Json(req): Json<RefreshRequest>,
) -> AppResult<Json<AuthResponse>> {
    let claims =
        service::verify_refresh_token(&req.refresh_token, &state.config.jwt.refresh_secret)?;

    let row = sqlx::query_as::<_, UserInfo>(
        "SELECT id, email, full_name, phone, role::text as role
         FROM users WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(claims.sub)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::Unauthorized("User not found".to_string()))?;

    let access_token = service::generate_access_token(row.id, &row.role, &state.config.jwt.secret)?;
    let refresh_token =
        service::generate_refresh_token(row.id, &row.role, &state.config.jwt.refresh_secret)?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user: row,
    }))
}

pub async fn me(State(state): State<AppState>, auth: AuthUser) -> AppResult<Json<UserInfo>> {
    let row = sqlx::query_as::<_, UserInfo>(
        "SELECT id, email, full_name, phone, role::text as role
         FROM users WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(auth.id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    Ok(Json(row))
}
