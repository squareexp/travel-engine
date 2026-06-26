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
pub struct CreateReviewRequest {
    pub rating: i32,
    pub comment: Option<String>,
}

#[derive(Deserialize)]
pub struct ReviewsQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

pub async fn create_review(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(booking_id): Path<Uuid>,
    Json(req): Json<CreateReviewRequest>,
) -> AppResult<Json<Value>> {
    if req.rating < 1 || req.rating > 5 {
        return Err(AppError::BadRequest(
            "Rating must be between 1 and 5".to_string(),
        ));
    }

    let booking = sqlx::query(
        "SELECT user_id, listing_id, status::text as status FROM bookings WHERE id = $1",
    )
    .bind(booking_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Booking not found".to_string()))?;

    let user_id = booking
        .try_get::<Uuid, _>("user_id")
        .ok()
        .unwrap_or(Uuid::nil());
    if user_id != auth.id {
        return Err(AppError::Forbidden(
            "Can only review your own bookings".to_string(),
        ));
    }

    let status = booking.try_get::<String, _>("status").unwrap_or_default();
    if status != "completed" && status != "confirmed" {
        return Err(AppError::BadRequest(
            "Can only review completed or confirmed bookings".to_string(),
        ));
    }

    let listing_id = booking
        .try_get::<Uuid, _>("listing_id")
        .ok()
        .unwrap_or(Uuid::nil());
    let review_id = Uuid::new_v4();

    let row = sqlx::query(
        r#"INSERT INTO reviews (id, booking_id, user_id, listing_id, rating, comment)
           VALUES ($1, $2, $3, $4, $5, $6)
           RETURNING id, booking_id, user_id, listing_id, rating, comment,
                     moderation_status::text as moderation_status, created_at::text as created_at"#,
    )
    .bind(review_id)
    .bind(booking_id)
    .bind(auth.id)
    .bind(listing_id)
    .bind(req.rating as i16)
    .bind(req.comment.as_deref())
    .fetch_one(&state.db)
    .await?;

    Ok(Json(json!({
        "id": row.try_get::<Uuid, _>("id").ok(),
        "booking_id": row.try_get::<Uuid, _>("booking_id").ok(),
        "user_id": row.try_get::<Uuid, _>("user_id").ok(),
        "listing_id": row.try_get::<Uuid, _>("listing_id").ok(),
        "rating": row.try_get::<i16, _>("rating").unwrap_or(0),
        "comment": row.try_get::<Option<String>, _>("comment").unwrap_or_default(),
        "moderation_status": row.try_get::<String, _>("moderation_status").unwrap_or_default(),
        "created_at": row.try_get::<String, _>("created_at").unwrap_or_default()
    })))
}

pub async fn listing_reviews(
    State(state): State<AppState>,
    Path(listing_id): Path<Uuid>,
    Query(params): Query<ReviewsQuery>,
) -> AppResult<Json<Value>> {
    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT r.id, r.rating, r.comment,
                  r.moderation_status::text as moderation_status,
                  r.created_at::text as created_at,
                  u.full_name as reviewer_name
           FROM reviews r
           JOIN users u ON u.id = r.user_id
           WHERE r.listing_id = $1 AND r.moderation_status = 'approved'
           ORDER BY r.created_at DESC LIMIT $2 OFFSET $3"#,
    )
    .bind(listing_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let avg: Option<f64> = sqlx::query_scalar(
        "SELECT AVG(rating::float) FROM reviews WHERE listing_id = $1 AND moderation_status = 'approved'",
    )
    .bind(listing_id)
    .fetch_one(&state.db)
    .await?;

    let count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM reviews WHERE listing_id = $1 AND moderation_status = 'approved'",
    )
    .bind(listing_id)
    .fetch_one(&state.db)
    .await?;

    let reviews: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "rating": r.try_get::<i16, _>("rating").unwrap_or(0),
                "comment": r.try_get::<Option<String>, _>("comment").unwrap_or_default(),
                "reviewer_name": r.try_get::<String, _>("reviewer_name").unwrap_or_default(),
                "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
            })
        })
        .collect();

    Ok(Json(json!({
        "data": reviews,
        "total": count,
        "average_rating": avg.map(|v| (v * 10.0).round() / 10.0),
        "limit": limit,
        "offset": offset
    })))
}

pub async fn admin_moderate_review(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(review_id): Path<Uuid>,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let status = body["status"]
        .as_str()
        .ok_or_else(|| AppError::BadRequest("status field required".to_string()))?;

    if !["approved", "rejected", "pending"].contains(&status) {
        return Err(AppError::BadRequest(
            "Invalid moderation status".to_string(),
        ));
    }

    sqlx::query(
        "UPDATE reviews SET moderation_status = $1::review_moderation_status, updated_at = now() WHERE id = $2",
    )
    .bind(status)
    .bind(review_id)
    .execute(&state.db)
    .await?;

    Ok(Json(json!({
        "message": "Review moderation status updated",
        "id": review_id,
        "status": status
    })))
}
