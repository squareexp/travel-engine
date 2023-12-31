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
pub struct CreateDestinationRequest {
    pub name: String,
    pub country: String,
    pub region: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub description: Option<String>,
    pub image_urls: Option<Vec<String>>,
}

#[derive(Deserialize)]
pub struct UpdateDestinationRequest {
    pub name: Option<String>,
    pub country: Option<String>,
    pub region: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub description: Option<String>,
    pub image_urls: Option<Vec<String>>,
    pub is_active: Option<bool>,
}

#[derive(Deserialize)]
pub struct ListParams {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
    pub country: Option<String>,
    pub search: Option<String>,
}

fn row_to_destination(r: &sqlx::postgres::PgRow) -> Value {
    json!({
        "id": r.try_get::<Uuid, _>("id").ok(),
        "name": r.try_get::<String, _>("name").unwrap_or_default(),
        "country": r.try_get::<String, _>("country").unwrap_or_default(),
        "region": r.try_get::<Option<String>, _>("region").unwrap_or_default(),
        "latitude": r.try_get::<Option<f64>, _>("latitude").unwrap_or_default(),
        "longitude": r.try_get::<Option<f64>, _>("longitude").unwrap_or_default(),
        "description": r.try_get::<Option<String>, _>("description").unwrap_or_default(),
        "image_urls": r.try_get::<Option<Vec<String>>, _>("image_urls").unwrap_or_default().unwrap_or_default(),
        "is_active": r.try_get::<bool, _>("is_active").unwrap_or(true),
        "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
    })
}

pub async fn list_destinations(
    State(state): State<AppState>,
    Query(params): Query<ListParams>,
) -> AppResult<Json<Value>> {
    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT id, name, country, region, latitude, longitude, description, image_urls,
                  is_active, created_at::text as created_at
           FROM destinations
           WHERE is_active = true
             AND ($1::text IS NULL OR country ILIKE '%' || $1 || '%')
             AND ($2::text IS NULL OR name ILIKE '%' || $2 || '%' OR description ILIKE '%' || $2 || '%')
           ORDER BY name
           LIMIT $3 OFFSET $4"#,
    )
    .bind(params.country.as_deref())
    .bind(params.search.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        r#"SELECT COUNT(*) FROM destinations WHERE is_active = true
           AND ($1::text IS NULL OR country ILIKE '%' || $1 || '%')
           AND ($2::text IS NULL OR name ILIKE '%' || $2 || '%')"#,
    )
    .bind(params.country.as_deref())
    .bind(params.search.as_deref())
    .fetch_one(&state.db)
    .await?;

    let data: Vec<Value> = rows.iter().map(row_to_destination).collect();
    Ok(Json(
        json!({ "data": data, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn get_destination(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    let row = sqlx::query(
        "SELECT id, name, country, region, latitude, longitude, description, image_urls,
                is_active, created_at::text as created_at
         FROM destinations WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Destination not found".to_string()))?;

    Ok(Json(row_to_destination(&row)))
}

pub async fn create_destination(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreateDestinationRequest>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let id = Uuid::new_v4();
    let image_urls = req.image_urls.unwrap_or_default();

    let row = sqlx::query(
        "INSERT INTO destinations (id, name, country, region, latitude, longitude, description, image_urls)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id, name, country, region, latitude, longitude, description, image_urls,
                   is_active, created_at::text as created_at",
    )
    .bind(id)
    .bind(&req.name)
    .bind(&req.country)
    .bind(req.region.as_deref())
    .bind(req.latitude)
    .bind(req.longitude)
    .bind(req.description.as_deref())
    .bind(&image_urls)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(row_to_destination(&row)))
}

pub async fn update_destination(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdateDestinationRequest>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let row = sqlx::query(
        r#"UPDATE destinations SET
             name = COALESCE($2, name),
             country = COALESCE($3, country),
             region = COALESCE($4, region),
             latitude = COALESCE($5, latitude),
             longitude = COALESCE($6, longitude),
             description = COALESCE($7, description),
             image_urls = COALESCE($8, image_urls),
             is_active = COALESCE($9, is_active),
             updated_at = now()
           WHERE id = $1
           RETURNING id, name, country, region, latitude, longitude, description, image_urls,
                     is_active, created_at::text as created_at"#,
    )
    .bind(id)
    .bind(req.name.as_deref())
    .bind(req.country.as_deref())
    .bind(req.region.as_deref())
    .bind(req.latitude)
    .bind(req.longitude)
    .bind(req.description.as_deref())
    .bind(req.image_urls.as_deref())
    .bind(req.is_active)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Destination not found".to_string()))?;

    Ok(Json(row_to_destination(&row)))
}

pub async fn delete_destination(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let result =
        sqlx::query("UPDATE destinations SET is_active = false, updated_at = now() WHERE id = $1")
            .bind(id)
            .execute(&state.db)
            .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("Destination not found".to_string()));
    }

    Ok(Json(
        json!({ "message": "Destination deactivated", "id": id }),
    ))
}
