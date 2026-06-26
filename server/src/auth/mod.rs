pub mod base_idp;
pub mod handlers;
pub mod idp_handler;
pub mod service;

use crate::error::AppError;
use axum::{async_trait, extract::FromRequestParts, http::request::Parts};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub role: String,
    pub exp: usize,
    pub iat: usize,
}

#[derive(Debug, Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub role: String,
}

#[derive(Clone)]
pub struct JwtSecret(pub String);

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get("Authorization")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "))
            .ok_or_else(|| {
                AppError::Unauthorized("Missing or invalid Authorization header".to_string())
            })?;

        let jwt_secret = parts
            .extensions
            .get::<JwtSecret>()
            .ok_or_else(|| AppError::Internal(anyhow::anyhow!("JWT secret not configured")))?;

        let token_data = decode::<Claims>(
            auth_header,
            &DecodingKey::from_secret(jwt_secret.0.as_bytes()),
            &Validation::new(Algorithm::HS256),
        )
        .map_err(|e| AppError::Unauthorized(format!("Invalid token: {}", e)))?;

        Ok(AuthUser {
            id: token_data.claims.sub,
            role: token_data.claims.role,
        })
    }
}

pub struct RequireRole(pub &'static str);

impl AuthUser {
    pub fn require_role(&self, role: &str) -> Result<(), AppError> {
        if self.role != role && self.role != "admin" {
            return Err(AppError::Forbidden(format!("Role '{}' required", role)));
        }
        Ok(())
    }

    pub fn require_admin(&self) -> Result<(), AppError> {
        if self.role != "admin" {
            return Err(AppError::Forbidden("Admin role required".to_string()));
        }
        Ok(())
    }

    pub fn require_operator(&self) -> Result<(), AppError> {
        if self.role != "operator" && self.role != "admin" {
            return Err(AppError::Forbidden("Operator role required".to_string()));
        }
        Ok(())
    }
}
