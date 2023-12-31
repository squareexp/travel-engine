use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use time::OffsetDateTime;
use uuid::Uuid;

use super::Claims;
use crate::error::{AppError, AppResult};

pub fn hash_password(password: &str) -> AppResult<String> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("Password hash error: {}", e)))
}

pub fn verify_password(password: &str, hash: &str) -> AppResult<bool> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("Hash parse error: {}", e)))?;
    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

pub fn generate_access_token(user_id: Uuid, role: &str, secret: &str) -> AppResult<String> {
    let now = OffsetDateTime::now_utc();
    let claims = Claims {
        sub: user_id,
        role: role.to_string(),
        iat: now.unix_timestamp() as usize,
        exp: (now + time::Duration::hours(1)).unix_timestamp() as usize,
    };
    encode(
        &Header::new(Algorithm::HS256),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(anyhow::anyhow!("Token encode error: {}", e)))
}

pub fn generate_refresh_token(user_id: Uuid, role: &str, secret: &str) -> AppResult<String> {
    let now = OffsetDateTime::now_utc();
    let claims = Claims {
        sub: user_id,
        role: role.to_string(),
        iat: now.unix_timestamp() as usize,
        exp: (now + time::Duration::days(30)).unix_timestamp() as usize,
    };
    encode(
        &Header::new(Algorithm::HS256),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(anyhow::anyhow!("Refresh token encode error: {}", e)))
}

pub fn verify_refresh_token(token: &str, secret: &str) -> AppResult<Claims> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
    .map(|d| d.claims)
    .map_err(|e| AppError::Unauthorized(format!("Invalid refresh token: {}", e)))
}
