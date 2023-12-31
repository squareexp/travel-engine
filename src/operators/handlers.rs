use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::FromRow;
use uuid::Uuid;

use crate::{
    app::AppState,
    auth::AuthUser,
    error::{AppError, AppResult},
};

#[derive(Deserialize)]
pub struct OperatorProfileUpdate {
    pub business_name: Option<String>,
    pub business_description: Option<String>,
    pub phone: Option<String>,
    pub website: Option<String>,
    pub address: Option<String>,
    pub business_registration_number: Option<String>,
}

#[derive(Deserialize)]
pub struct PaginationParams {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(FromRow, Serialize)]
struct OperatorRow {
    user_id: Uuid,
    email: String,
    full_name: String,
    phone: Option<String>,
    business_name: Option<String>,
    business_description: Option<String>,
    website: Option<String>,
    address: Option<String>,
    business_registration_number: Option<String>,
    verification_status: String,
    verified_at: Option<String>,
}

pub async fn get_my_profile(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let row = sqlx::query(
        r#"SELECT u.id as user_id, u.email, u.full_name, u.phone,
                  op.business_name, op.business_description, op.website, op.address,
                  op.business_registration_number,
                  COALESCE(op.verification_status::text, 'pending') as verification_status,
                  op.verified_at::text as verified_at
           FROM users u
           LEFT JOIN operator_profiles op ON op.user_id = u.id
           WHERE u.id = $1 AND u.deleted_at IS NULL"#,
    )
    .bind(auth.id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Operator not found".to_string()))?;

    use sqlx::Row;
    Ok(Json(json!({
        "user_id": row.try_get::<Uuid, _>("user_id").ok(),
        "email": row.try_get::<String, _>("email").unwrap_or_default(),
        "full_name": row.try_get::<String, _>("full_name").unwrap_or_default(),
        "phone": row.try_get::<Option<String>, _>("phone").unwrap_or_default(),
        "business_name": row.try_get::<Option<String>, _>("business_name").unwrap_or_default(),
        "business_description": row.try_get::<Option<String>, _>("business_description").unwrap_or_default(),
        "website": row.try_get::<Option<String>, _>("website").unwrap_or_default(),
        "address": row.try_get::<Option<String>, _>("address").unwrap_or_default(),
        "business_registration_number": row.try_get::<Option<String>, _>("business_registration_number").unwrap_or_default(),
        "verification_status": row.try_get::<String, _>("verification_status").unwrap_or_else(|_| "pending".to_string()),
        "verified_at": row.try_get::<Option<String>, _>("verified_at").unwrap_or_default()
    })))
}

pub async fn update_my_profile(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<OperatorProfileUpdate>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    sqlx::query(
        "INSERT INTO operator_profiles (user_id, business_name, business_description, phone, website, address, business_registration_number)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (user_id) DO UPDATE SET
           business_name = COALESCE($2, operator_profiles.business_name),
           business_description = COALESCE($3, operator_profiles.business_description),
           phone = COALESCE($4, operator_profiles.phone),
           website = COALESCE($5, operator_profiles.website),
           address = COALESCE($6, operator_profiles.address),
           business_registration_number = COALESCE($7, operator_profiles.business_registration_number),
           updated_at = now()",
    )
    .bind(auth.id)
    .bind(req.business_name.as_deref())
    .bind(req.business_description.as_deref())
    .bind(req.phone.as_deref())
    .bind(req.website.as_deref())
    .bind(req.address.as_deref())
    .bind(req.business_registration_number.as_deref())
    .execute(&state.db)
    .await?;

    get_my_profile(State(state), auth).await
}

pub async fn admin_list_operators(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<PaginationParams>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT u.id, u.email, u.full_name, u.phone, u.created_at::text as created_at,
                  op.business_name, op.business_description,
                  COALESCE(op.verification_status::text, 'pending') as verification_status,
                  op.verified_at::text as verified_at
           FROM users u
           LEFT JOIN operator_profiles op ON op.user_id = u.id
           WHERE u.role = 'operator' AND u.deleted_at IS NULL
           ORDER BY u.created_at DESC
           LIMIT $1 OFFSET $2"#,
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM users WHERE role = 'operator' AND deleted_at IS NULL",
    )
    .fetch_one(&state.db)
    .await?;

    use sqlx::Row;
    let operators: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "email": r.try_get::<String, _>("email").unwrap_or_default(),
                "full_name": r.try_get::<String, _>("full_name").unwrap_or_default(),
                "phone": r.try_get::<Option<String>, _>("phone").unwrap_or_default(),
                "business_name": r.try_get::<Option<String>, _>("business_name").unwrap_or_default(),
                "verification_status": r.try_get::<String, _>("verification_status").unwrap_or_else(|_| "pending".into()),
                "verified_at": r.try_get::<Option<String>, _>("verified_at").unwrap_or_default(),
                "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
            })
        })
        .collect();

    Ok(Json(
        json!({ "data": operators, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn admin_get_operator(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(operator_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let row = sqlx::query(
        r#"SELECT u.id, u.email, u.full_name, u.phone, u.created_at::text as created_at,
                  op.business_name, op.business_description, op.website, op.address,
                  op.business_registration_number,
                  COALESCE(op.verification_status::text, 'pending') as verification_status,
                  op.verified_at::text as verified_at, op.verified_by
           FROM users u
           LEFT JOIN operator_profiles op ON op.user_id = u.id
           WHERE u.id = $1 AND u.role = 'operator' AND u.deleted_at IS NULL"#,
    )
    .bind(operator_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Operator not found".to_string()))?;

    use sqlx::Row;
    Ok(Json(json!({
        "id": row.try_get::<Uuid, _>("id").ok(),
        "email": row.try_get::<String, _>("email").unwrap_or_default(),
        "full_name": row.try_get::<String, _>("full_name").unwrap_or_default(),
        "phone": row.try_get::<Option<String>, _>("phone").unwrap_or_default(),
        "business_name": row.try_get::<Option<String>, _>("business_name").unwrap_or_default(),
        "business_description": row.try_get::<Option<String>, _>("business_description").unwrap_or_default(),
        "website": row.try_get::<Option<String>, _>("website").unwrap_or_default(),
        "address": row.try_get::<Option<String>, _>("address").unwrap_or_default(),
        "business_registration_number": row.try_get::<Option<String>, _>("business_registration_number").unwrap_or_default(),
        "verification_status": row.try_get::<String, _>("verification_status").unwrap_or_else(|_| "pending".into()),
        "verified_at": row.try_get::<Option<String>, _>("verified_at").unwrap_or_default(),
        "verified_by": row.try_get::<Option<Uuid>, _>("verified_by").ok().flatten(),
        "created_at": row.try_get::<String, _>("created_at").unwrap_or_default()
    })))
}

#[derive(Deserialize)]
pub struct VerifyRequest {
    pub status: String,
    pub rejection_reason: Option<String>,
}

pub async fn admin_verify_operator(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(operator_id): Path<Uuid>,
    Json(req): Json<VerifyRequest>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    if !["verified", "rejected", "under_review", "suspended"].contains(&req.status.as_str()) {
        return Err(AppError::BadRequest(
            "Status must be: verified, rejected, under_review, or suspended".to_string(),
        ));
    }

    // Ensure operator exists
    let exists: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM users WHERE id = $1 AND role = 'operator'")
            .bind(operator_id)
            .fetch_one(&state.db)
            .await?;

    if exists == 0 {
        return Err(AppError::NotFound("Operator not found".to_string()));
    }

    sqlx::query(
        "INSERT INTO operator_profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING",
    )
    .bind(operator_id)
    .execute(&state.db)
    .await?;

    sqlx::query(
        r#"UPDATE operator_profiles
           SET verification_status = $1::operator_verification_status,
               verified_by = $2,
               verified_at = CASE WHEN $1 = 'verified' THEN now() ELSE NULL END,
               rejection_reason = $3,
               updated_at = now()
           WHERE user_id = $4"#,
    )
    .bind(&req.status)
    .bind(auth.id)
    .bind(req.rejection_reason.as_deref())
    .bind(operator_id)
    .execute(&state.db)
    .await?;

    sqlx::query(
        "INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id) VALUES ($1, $2, 'operator', $3)",
    )
    .bind(auth.id)
    .bind(format!("operator_{}", req.status))
    .bind(operator_id)
    .execute(&state.db)
    .await?;

    Ok(Json(json!({
        "message": format!("Operator {}", req.status),
        "operator_id": operator_id,
        "status": req.status
    })))
}
