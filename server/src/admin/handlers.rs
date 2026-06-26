use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use serde_json::{json, Value};
use sqlx::Row;
use uuid::Uuid;

use crate::{
    app::AppState,
    auth::AuthUser,
    error::{AppError, AppResult},
};

#[derive(Deserialize)]
pub struct ListQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
    pub role: Option<String>,
    pub status: Option<String>,
}

pub async fn list_users(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<ListQuery>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT id, email, full_name, phone, role::text as role, is_verified, created_at::text as created_at
           FROM users WHERE deleted_at IS NULL AND ($1::text IS NULL OR role::text = $1)
           ORDER BY created_at DESC LIMIT $2 OFFSET $3"#,
    )
    .bind(params.role.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM users WHERE deleted_at IS NULL AND ($1::text IS NULL OR role::text = $1)",
    )
    .bind(params.role.as_deref())
    .fetch_one(&state.db)
    .await?;

    let users: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "email": r.try_get::<String, _>("email").unwrap_or_default(),
                "full_name": r.try_get::<String, _>("full_name").unwrap_or_default(),
                "phone": r.try_get::<Option<String>, _>("phone").unwrap_or_default(),
                "role": r.try_get::<String, _>("role").unwrap_or_default(),
                "is_verified": r.try_get::<bool, _>("is_verified").unwrap_or(false),
                "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
            })
        })
        .collect();

    Ok(Json(
        json!({ "data": users, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn get_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let row = sqlx::query(
        "SELECT id, email, full_name, phone, role::text as role, is_verified, created_at::text as created_at
         FROM users WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    Ok(Json(json!({
        "id": row.try_get::<Uuid, _>("id").ok(),
        "email": row.try_get::<String, _>("email").unwrap_or_default(),
        "full_name": row.try_get::<String, _>("full_name").unwrap_or_default(),
        "phone": row.try_get::<Option<String>, _>("phone").unwrap_or_default(),
        "role": row.try_get::<String, _>("role").unwrap_or_default(),
        "is_verified": row.try_get::<bool, _>("is_verified").unwrap_or(false),
        "created_at": row.try_get::<String, _>("created_at").unwrap_or_default()
    })))
}

pub async fn update_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let full_name = body["full_name"].as_str();
    let phone = body["phone"].as_str();
    let is_verified = body["is_verified"].as_bool();

    sqlx::query(
        r#"UPDATE users SET
             full_name = COALESCE($2, full_name),
             phone = COALESCE($3, phone),
             is_verified = COALESCE($4, is_verified),
             updated_at = now()
           WHERE id = $1 AND deleted_at IS NULL"#,
    )
    .bind(id)
    .bind(full_name)
    .bind(phone)
    .bind(is_verified)
    .execute(&state.db)
    .await?;

    get_user(State(state), auth, Path(id)).await
}

pub async fn delete_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    if id == auth.id {
        return Err(AppError::BadRequest(
            "Cannot delete your own admin account".to_string(),
        ));
    }

    let result = sqlx::query(
        "UPDATE users SET deleted_at = now(), updated_at = now() WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(id)
    .execute(&state.db)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("User not found".to_string()));
    }

    sqlx::query(
        "INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id) VALUES ($1, 'user_deleted', 'user', $2)",
    )
    .bind(auth.id)
    .bind(id)
    .execute(&state.db)
    .await?;

    Ok(Json(json!({ "message": "User soft-deleted", "id": id })))
}

pub async fn analytics(State(state): State<AppState>, auth: AuthUser) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let total_users: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM users WHERE deleted_at IS NULL")
            .fetch_one(&state.db)
            .await?;

    let total_operators: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM users WHERE role = 'operator' AND deleted_at IS NULL",
    )
    .fetch_one(&state.db)
    .await?;

    let verified_operators: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM operator_profiles WHERE verification_status = 'verified'",
    )
    .fetch_one(&state.db)
    .await?;

    let total_listings: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM listings WHERE deleted_at IS NULL")
            .fetch_one(&state.db)
            .await?;

    let active_listings: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM listings WHERE status = 'active' AND deleted_at IS NULL",
    )
    .fetch_one(&state.db)
    .await?;

    let total_bookings: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM bookings")
        .fetch_one(&state.db)
        .await?;

    let confirmed_bookings: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM bookings WHERE status IN ('confirmed', 'completed')",
    )
    .fetch_one(&state.db)
    .await?;

    let total_gmv: f64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(amount::float), 0) FROM payments WHERE status = 'succeeded'",
    )
    .fetch_one(&state.db)
    .await?;

    let avg_order_value: f64 = sqlx::query_scalar(
        "SELECT COALESCE(AVG(amount::float), 0) FROM payments WHERE status = 'succeeded'",
    )
    .fetch_one(&state.db)
    .await?;

    Ok(Json(json!({
        "users": {
            "total": total_users,
            "operators": total_operators,
            "verified_operators": verified_operators
        },
        "listings": { "total": total_listings, "active": active_listings },
        "bookings": { "total": total_bookings, "confirmed_or_completed": confirmed_bookings },
        "revenue": {
            "total_gmv_usd": total_gmv,
            "commission_revenue_usd": total_gmv * 0.15,
            "average_order_value_usd": avg_order_value,
            "commission_rate": "15%"
        }
    })))
}

pub async fn audit_logs(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<ListQuery>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let limit = params.limit.unwrap_or(50).min(200);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT a.id, a.actor_user_id, a.action, a.entity_type,
                  a.entity_id, a.before_state, a.after_state, a.created_at::text as created_at,
                  u.email as actor_email
           FROM audit_logs a
           LEFT JOIN users u ON u.id = a.actor_user_id
           ORDER BY a.created_at DESC LIMIT $1 OFFSET $2"#,
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let logs: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "actor_user_id": r.try_get::<Option<Uuid>, _>("actor_user_id").unwrap_or_default(),
                "actor_email": r.try_get::<Option<String>, _>("actor_email").unwrap_or_default(),
                "action": r.try_get::<String, _>("action").unwrap_or_default(),
                "entity_type": r.try_get::<String, _>("entity_type").unwrap_or_default(),
                "entity_id": r.try_get::<Option<Uuid>, _>("entity_id").unwrap_or_default(),
                "before_state": r.try_get::<Option<Value>, _>("before_state").unwrap_or_default(),
                "after_state": r.try_get::<Option<Value>, _>("after_state").unwrap_or_default(),
                "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
            })
        })
        .collect();

    let total: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM audit_logs")
        .fetch_one(&state.db)
        .await?;

    Ok(Json(
        json!({ "data": logs, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn admin_list_bookings(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<ListQuery>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT b.id, b.user_id, b.listing_id, b.guests, b.total_amount, b.currency,
                  b.status::text as status, b.created_at::text as created_at,
                  l.title as listing_title,
                  u.email as user_email, u.full_name as user_name,
                  b.availability_id, b.special_requests
           FROM bookings b
           JOIN listings l ON l.id = b.listing_id
           JOIN users u ON u.id = b.user_id
           WHERE ($1::text IS NULL OR b.status::text = $1)
           ORDER BY b.created_at DESC LIMIT $2 OFFSET $3"#,
    )
    .bind(params.status.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM bookings WHERE ($1::text IS NULL OR status::text = $1)",
    )
    .bind(params.status.as_deref())
    .fetch_one(&state.db)
    .await?;

    let bookings: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "user_id": r.try_get::<Uuid, _>("user_id").ok(),
                "user_email": r.try_get::<String, _>("user_email").unwrap_or_default(),
                "user_name": r.try_get::<String, _>("user_name").unwrap_or_default(),
                "listing_id": r.try_get::<Uuid, _>("listing_id").ok(),
                "listing_title": r.try_get::<String, _>("listing_title").unwrap_or_default(),
                "guests": r.try_get::<i32, _>("guests").unwrap_or(0),
                "total_amount": r.try_get::<sqlx::types::BigDecimal, _>("total_amount")
                    .map(|v| v.to_string()).ok(),
                "currency": r.try_get::<String, _>("currency").unwrap_or_default(),
                "status": r.try_get::<String, _>("status").unwrap_or_default(),
                "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
            })
        })
        .collect();

    Ok(Json(
        json!({ "data": bookings, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn admin_complete_booking(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    sqlx::query("UPDATE bookings SET status = 'completed', updated_at = now() WHERE id = $1")
        .bind(id)
        .execute(&state.db)
        .await?;

    Ok(Json(
        json!({ "message": "Booking marked as completed", "id": id }),
    ))
}
