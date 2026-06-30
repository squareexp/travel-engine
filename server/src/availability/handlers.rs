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
pub struct CreateAvailabilityRequest {
    pub travel_date: String,
    pub capacity: i32,
}

#[derive(Deserialize)]
pub struct AvailabilityQuery {
    pub from_date: Option<String>,
    pub to_date: Option<String>,
}

fn row_to_avail(r: &sqlx::postgres::PgRow) -> Value {
    let capacity = r.try_get::<i32, _>("capacity").unwrap_or(0);
    let capacity_booked = r.try_get::<i32, _>("capacity_booked").unwrap_or(0);
    json!({
        "id": r.try_get::<Uuid, _>("id").ok(),
        "listing_id": r.try_get::<Uuid, _>("listing_id").ok(),
        "travel_date": r.try_get::<String, _>("travel_date").unwrap_or_default(),
        "capacity": capacity,
        "capacity_booked": capacity_booked,
        "available_spots": capacity - capacity_booked,
        "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
    })
}

pub async fn list_availability(
    State(state): State<AppState>,
    Path(listing_id): Path<Uuid>,
    Query(params): Query<AvailabilityQuery>,
) -> AppResult<Json<Value>> {
    let rows = sqlx::query(
        r#"SELECT id, listing_id, travel_date::text as travel_date, capacity, capacity_booked,
                  created_at::text as created_at
           FROM availability
           WHERE listing_id = $1
             AND ($2::date IS NULL OR travel_date >= $2::date)
             AND ($3::date IS NULL OR travel_date <= $3::date)
             AND travel_date >= CURRENT_DATE
           ORDER BY travel_date"#,
    )
    .bind(listing_id)
    .bind(params.from_date.as_deref())
    .bind(params.to_date.as_deref())
    .fetch_all(&state.db)
    .await?;

    let data: Vec<Value> = rows.iter().map(row_to_avail).collect();
    Ok(Json(json!({ "data": data })))
}

pub async fn create_availability(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(listing_id): Path<Uuid>,
    Json(req): Json<CreateAvailabilityRequest>,
) -> AppResult<Json<Value>> {
    if auth.role != "admin" {
        let owner: Option<Uuid> = sqlx::query_scalar(
            "SELECT operator_id FROM listings WHERE id = $1 AND deleted_at IS NULL",
        )
        .bind(listing_id)
        .fetch_optional(&state.db)
        .await?;
        match owner {
            None => return Err(AppError::NotFound("Listing not found".to_string())),
            Some(oid) if oid != auth.id => {
                return Err(AppError::Forbidden("Not your listing".to_string()))
            }
            _ => {}
        }
    }

    if req.capacity < 1 {
        return Err(AppError::BadRequest(
            "Capacity must be at least 1".to_string(),
        ));
    }

    let id = Uuid::new_v4();
    let row = sqlx::query(
        r#"INSERT INTO availability (id, listing_id, travel_date, capacity)
           VALUES ($1, $2, $3::date, $4)
           ON CONFLICT (listing_id, travel_date) DO UPDATE
             SET capacity = EXCLUDED.capacity, updated_at = now()
           RETURNING id, listing_id, travel_date::text as travel_date,
                     capacity, capacity_booked, created_at::text as created_at"#,
    )
    .bind(id)
    .bind(listing_id)
    .bind(&req.travel_date)
    .bind(req.capacity)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(row_to_avail(&row)))
}

pub async fn update_availability(
    State(state): State<AppState>,
    auth: AuthUser,
    Path((listing_id, avail_id)): Path<(Uuid, Uuid)>,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    if auth.role != "admin" {
        let owner: Option<Uuid> = sqlx::query_scalar(
            "SELECT operator_id FROM listings WHERE id = $1 AND deleted_at IS NULL",
        )
        .bind(listing_id)
        .fetch_optional(&state.db)
        .await?;
        match owner {
            None => return Err(AppError::NotFound("Listing not found".to_string())),
            Some(oid) if oid != auth.id => {
                return Err(AppError::Forbidden("Not your listing".to_string()))
            }
            _ => {}
        }
    }

    let capacity = body["capacity"].as_i64().map(|c| c as i32);

    let row = sqlx::query(
        r#"UPDATE availability
           SET capacity = COALESCE($3, capacity), updated_at = now()
           WHERE id = $1 AND listing_id = $2
           RETURNING id, listing_id, travel_date::text as travel_date,
                     capacity, capacity_booked, created_at::text as created_at"#,
    )
    .bind(avail_id)
    .bind(listing_id)
    .bind(capacity)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Availability slot not found".to_string()))?;

    Ok(Json(row_to_avail(&row)))
}

pub async fn delete_availability(
    State(state): State<AppState>,
    auth: AuthUser,
    Path((listing_id, avail_id)): Path<(Uuid, Uuid)>,
) -> AppResult<Json<Value>> {
    if auth.role != "admin" {
        let owner: Option<Uuid> = sqlx::query_scalar(
            "SELECT operator_id FROM listings WHERE id = $1 AND deleted_at IS NULL",
        )
        .bind(listing_id)
        .fetch_optional(&state.db)
        .await?;
        match owner {
            None => return Err(AppError::NotFound("Listing not found".to_string())),
            Some(oid) if oid != auth.id => {
                return Err(AppError::Forbidden("Not your listing".to_string()))
            }
            _ => {}
        }
    }

    let row =
        sqlx::query("SELECT capacity_booked FROM availability WHERE id = $1 AND listing_id = $2")
            .bind(avail_id)
            .bind(listing_id)
            .fetch_optional(&state.db)
            .await?
            .ok_or_else(|| AppError::NotFound("Availability slot not found".to_string()))?;

    let capacity_booked = row.try_get::<i32, _>("capacity_booked").unwrap_or(0);
    if capacity_booked > 0 {
        return Err(AppError::BadRequest(
            "Cannot delete a slot with existing bookings".to_string(),
        ));
    }

    sqlx::query("DELETE FROM availability WHERE id = $1 AND listing_id = $2")
        .bind(avail_id)
        .bind(listing_id)
        .execute(&state.db)
        .await?;

    Ok(Json(json!({
        "message": "Availability slot deleted",
        "id": avail_id
    })))
}
