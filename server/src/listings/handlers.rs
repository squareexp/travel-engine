use std::convert::Infallible;

use axum::{
    extract::{Path, Query, State},
    response::sse::{Event, KeepAlive, Sse},
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
pub struct ListingsQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
    pub listing_type: Option<String>,
    pub destination_id: Option<Uuid>,
    pub min_price: Option<f64>,
    pub max_price: Option<f64>,
    pub search: Option<String>,
    pub status: Option<String>,
}

#[derive(Deserialize)]
pub struct SiteDetails {
    pub address: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub duration_hours: Option<f64>,
    pub max_capacity: Option<i32>,
    pub includes_transport: Option<bool>,
    pub highlights: Option<Vec<String>>,
}

#[derive(Deserialize)]
pub struct ExperienceDetails {
    pub theme: Option<String>,
    pub duration_hours: Option<f64>,
    pub min_participants: Option<i32>,
    pub max_participants: Option<i32>,
    pub site_ids: Option<Vec<Uuid>>,
}

#[derive(Deserialize)]
pub struct TripDetails {
    pub duration_days: Option<i32>,
    pub max_participants: Option<i32>,
    pub difficulty_level: Option<String>,
}

#[derive(Deserialize)]
pub struct SafariDetails {
    pub park_name: Option<String>,
    pub vehicle_class: Option<String>,
    pub game_drive_window: Option<String>,
    pub park_fee_amount: Option<f64>,
    pub park_fee_currency: Option<String>,
}

#[derive(Deserialize)]
pub struct CreateListingRequest {
    pub destination_id: Uuid,
    pub listing_type: String,
    pub title: String,
    pub description: Option<String>,
    pub base_price: f64,
    pub currency: Option<String>,
    pub image_urls: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub site_details: Option<SiteDetails>,
    pub experience_details: Option<ExperienceDetails>,
    pub trip_details: Option<TripDetails>,
    pub safari_details: Option<SafariDetails>,
}

#[derive(Deserialize)]
pub struct UpdateListingRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub base_price: Option<f64>,
    pub status: Option<String>,
    pub image_urls: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub capacity: Option<i32>,
    pub duration_hours: Option<f64>,
}

fn row_to_listing(r: &sqlx::postgres::PgRow) -> Value {
    json!({
        "id": r.try_get::<Uuid, _>("id").ok(),
        "operator_id": r.try_get::<Uuid, _>("operator_id").ok(),
        "operator_name": r.try_get::<String, _>("operator_name").unwrap_or_default(),
        "destination_id": r.try_get::<Uuid, _>("destination_id").ok(),
        "destination_name": r.try_get::<String, _>("destination_name").unwrap_or_default(),
        "destination_country": r.try_get::<String, _>("destination_country").unwrap_or_default(),
        "listing_type": r.try_get::<String, _>("listing_type").unwrap_or_default(),
        "title": r.try_get::<String, _>("title").unwrap_or_default(),
        "description": r.try_get::<Option<String>, _>("description").unwrap_or_default(),
        "base_price": r.try_get::<sqlx::types::BigDecimal, _>("base_price")
            .map(|v| v.to_string()).ok(),
        "currency": r.try_get::<String, _>("currency").unwrap_or_else(|_| "USD".into()),
        "status": r.try_get::<String, _>("status").unwrap_or_default(),
        "image_urls": r.try_get::<Option<Vec<String>>, _>("image_urls").unwrap_or_default().unwrap_or_default(),
        "tags": r.try_get::<Option<Vec<String>>, _>("tags").unwrap_or_default().unwrap_or_default(),
        "capacity": r.try_get::<Option<i32>, _>("capacity").unwrap_or_default(),
        "duration_hours": r.try_get::<Option<f64>, _>("duration_hours").unwrap_or_default(),
        "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
    })
}

pub async fn list_listings(
    State(state): State<AppState>,
    Query(params): Query<ListingsQuery>,
) -> AppResult<Json<Value>> {
    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);
    let status = params.status.as_deref().unwrap_or("active");

    let rows = sqlx::query(
        r#"SELECT l.id, l.operator_id, l.destination_id, l.listing_type::text as listing_type,
                  l.title, l.description, l.base_price, l.currency,
                  l.status::text as status, l.image_urls, l.tags, l.created_at::text as created_at,
                  d.name as destination_name, d.country as destination_country,
                  u.full_name as operator_name,
                  COALESCE(sd.max_capacity, ed.max_participants, td.max_participants) as capacity,
                  COALESCE(sd.duration_hours, ed.duration_hours, td.duration_days::float * 24.0) as duration_hours
           FROM listings l
           JOIN destinations d ON d.id = l.destination_id
           JOIN users u ON u.id = l.operator_id
           LEFT JOIN site_details sd ON sd.listing_id = l.id
           LEFT JOIN experience_details ed ON ed.listing_id = l.id
           LEFT JOIN trip_details td ON td.listing_id = l.id
           WHERE l.deleted_at IS NULL
             AND l.status = $1::listing_status
             AND ($2::text IS NULL OR l.listing_type::text = $2)
             AND ($3::uuid IS NULL OR l.destination_id = $3)
             AND ($4::numeric IS NULL OR l.base_price >= $4)
             AND ($5::numeric IS NULL OR l.base_price <= $5)
             AND ($6::text IS NULL OR l.title ILIKE '%' || $6 || '%' OR l.description ILIKE '%' || $6 || '%')
           ORDER BY l.created_at DESC
           LIMIT $7 OFFSET $8"#,
    )
    .bind(status)
    .bind(params.listing_type.as_deref())
    .bind(params.destination_id)
    .bind(params.min_price)
    .bind(params.max_price)
    .bind(params.search.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM listings l WHERE l.deleted_at IS NULL AND l.status = $1::listing_status
         AND ($2::text IS NULL OR l.listing_type::text = $2)",
    )
    .bind(status)
    .bind(params.listing_type.as_deref())
    .fetch_one(&state.db)
    .await?;

    let listings: Vec<Value> = rows.iter().map(row_to_listing).collect();
    Ok(Json(
        json!({ "data": listings, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn get_listing(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    let row = sqlx::query(
        r#"SELECT l.id, l.operator_id, l.destination_id, l.listing_type::text as listing_type,
                  l.title, l.description, l.base_price, l.currency,
                  l.status::text as status, l.image_urls, l.tags, l.created_at::text as created_at,
                  d.name as destination_name, d.country as destination_country,
                  u.full_name as operator_name,
                  COALESCE(sd.max_capacity, ed.max_participants, td.max_participants) as capacity,
                  COALESCE(sd.duration_hours, ed.duration_hours, td.duration_days::float * 24.0) as duration_hours
           FROM listings l
           JOIN destinations d ON d.id = l.destination_id
           JOIN users u ON u.id = l.operator_id
           LEFT JOIN site_details sd ON sd.listing_id = l.id
           LEFT JOIN experience_details ed ON ed.listing_id = l.id
           LEFT JOIN trip_details td ON td.listing_id = l.id
           WHERE l.id = $1 AND l.deleted_at IS NULL"#,
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Listing not found".to_string()))?;

    let listing_type = row.try_get::<String, _>("listing_type").unwrap_or_default();
    let mut result = row_to_listing(&row);

    match listing_type.as_str() {
        "site" => {
            if let Ok(d) = sqlx::query(
                "SELECT address, latitude, longitude, duration_hours, max_capacity, includes_transport, highlights
                 FROM site_details WHERE listing_id = $1",
            )
            .bind(id)
            .fetch_optional(&state.db)
            .await
            {
                if let Some(d) = d {
                    result["details"] = json!({
                        "address": d.try_get::<Option<String>, _>("address").unwrap_or_default(),
                        "latitude": d.try_get::<Option<f64>, _>("latitude").unwrap_or_default(),
                        "longitude": d.try_get::<Option<f64>, _>("longitude").unwrap_or_default(),
                        "duration_hours": d.try_get::<Option<f64>, _>("duration_hours").unwrap_or_default(),
                        "max_capacity": d.try_get::<Option<i32>, _>("max_capacity").unwrap_or_default(),
                        "includes_transport": d.try_get::<bool, _>("includes_transport").unwrap_or(false),
                        "highlights": d.try_get::<Option<Vec<String>>, _>("highlights").unwrap_or_default().unwrap_or_default()
                    });
                }
            }
        }
        "experience" => {
            if let Ok(Some(d)) = sqlx::query(
                "SELECT theme, duration_hours, min_participants, max_participants
                 FROM experience_details WHERE listing_id = $1",
            )
            .bind(id)
            .fetch_optional(&state.db)
            .await
            {
                let sites = sqlx::query(
                    "SELECT es.site_id, es.sequence_order, l.title
                     FROM experience_sites es
                     JOIN listings l ON l.id = es.site_id
                     WHERE es.experience_id = $1 ORDER BY es.sequence_order",
                )
                .bind(id)
                .fetch_all(&state.db)
                .await
                .unwrap_or_default();

                result["details"] = json!({
                    "theme": d.try_get::<Option<String>, _>("theme").unwrap_or_default(),
                    "duration_hours": d.try_get::<Option<f64>, _>("duration_hours").unwrap_or_default(),
                    "min_participants": d.try_get::<Option<i32>, _>("min_participants").unwrap_or_default(),
                    "max_participants": d.try_get::<Option<i32>, _>("max_participants").unwrap_or_default(),
                    "sites": sites.iter().map(|s| json!({
                        "site_id": s.try_get::<Uuid, _>("site_id").ok(),
                        "title": s.try_get::<String, _>("title").unwrap_or_default(),
                        "sequence_order": s.try_get::<i32, _>("sequence_order").unwrap_or(0)
                    })).collect::<Vec<_>>()
                });
            }
        }
        "trip" => {
            if let Ok(Some(d)) = sqlx::query(
                "SELECT duration_days, max_participants, difficulty_level
                 FROM trip_details WHERE listing_id = $1",
            )
            .bind(id)
            .fetch_optional(&state.db)
            .await
            {
                result["details"] = json!({
                    "duration_days": d.try_get::<Option<i32>, _>("duration_days").unwrap_or_default(),
                    "max_participants": d.try_get::<Option<i32>, _>("max_participants").unwrap_or_default(),
                    "difficulty_level": d.try_get::<Option<String>, _>("difficulty_level").unwrap_or_default()
                });
            }
        }
        "safari" => {
            if let Ok(Some(d)) = sqlx::query(
                "SELECT park_name, vehicle_class, game_drive_window, park_fee_amount, park_fee_currency
                 FROM safari_details WHERE listing_id = $1",
            )
            .bind(id)
            .fetch_optional(&state.db)
            .await
            {
                result["details"] = json!({
                    "park_name": d.try_get::<Option<String>, _>("park_name").unwrap_or_default(),
                    "vehicle_class": d.try_get::<Option<String>, _>("vehicle_class").unwrap_or_default(),
                    "game_drive_window": d.try_get::<Option<String>, _>("game_drive_window").unwrap_or_default(),
                    "park_fee_amount": d.try_get::<Option<sqlx::types::BigDecimal>, _>("park_fee_amount")
                        .ok().flatten().map(|v| v.to_string()),
                    "park_fee_currency": d.try_get::<Option<String>, _>("park_fee_currency").unwrap_or_default()
                });
            }
        }
        _ => {}
    }

    Ok(Json(result))
}

pub async fn create_listing(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreateListingRequest>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let valid_types = ["site", "experience", "trip", "safari"];
    if !valid_types.contains(&req.listing_type.as_str()) {
        return Err(AppError::BadRequest(
            "listing_type must be one of: site, experience, trip, safari".to_string(),
        ));
    }

    // Input validation — the endpoint cannot trust the client to have
    // enforced these (a compromised or third-party client can send anything).
    let title = req.title.trim();
    if title.is_empty() {
        return Err(AppError::BadRequest("title is required".to_string()));
    }
    if title.chars().count() > 200 {
        return Err(AppError::BadRequest(
            "title is too long (max 200 characters)".to_string(),
        ));
    }
    if !req.base_price.is_finite() || req.base_price < 0.0 {
        return Err(AppError::BadRequest(
            "base_price must be a non-negative number".to_string(),
        ));
    }

    // The destination FK would otherwise surface a bad id as a 500 with a raw
    // database error; validate it up front for a clean 400.
    let destination_exists: bool =
        sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM destinations WHERE id = $1)")
            .bind(req.destination_id)
            .fetch_one(&state.db)
            .await?;
    if !destination_exists {
        return Err(AppError::BadRequest(
            "destination_id does not reference a known destination".to_string(),
        ));
    }

    // Constrained "enum-like" detail fields are plain TEXT columns, so the DB
    // won't reject a bogus value — validate against the allowed set here.
    if let Some(level) = req
        .trip_details
        .as_ref()
        .and_then(|d| d.difficulty_level.as_deref())
    {
        const LEVELS: &[&str] = &["easy", "moderate", "challenging", "expert"];
        if !LEVELS.contains(&level) {
            return Err(AppError::BadRequest(format!(
                "difficulty_level must be one of: {}",
                LEVELS.join(", ")
            )));
        }
    }
    if let Some(class) = req
        .safari_details
        .as_ref()
        .and_then(|d| d.vehicle_class.as_deref())
    {
        const CLASSES: &[&str] = &["shared_jeep", "private_jeep", "luxury_4wd"];
        if !CLASSES.contains(&class) {
            return Err(AppError::BadRequest(format!(
                "vehicle_class must be one of: {}",
                CLASSES.join(", ")
            )));
        }
    }

    if auth.role != "admin" {
        let exists: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM operator_profiles WHERE user_id = $1")
                .bind(auth.id)
                .fetch_one(&state.db)
                .await?;
        if exists == 0 {
            return Err(AppError::Forbidden(
                "Operator profile not set up".to_string(),
            ));
        }

        // Listing quota is driven by document-completion percentage, not by
        // admin approval — operators can start posting before manual review.
        let compliance = crate::operators::handlers::compute_compliance(&state, auth.id).await?;
        let quota = compliance["listing_quota"].as_i64();
        if let Some(quota) = quota {
            let listings_used = compliance["listings_used"].as_i64().unwrap_or(0);
            if listings_used >= quota {
                return Err(AppError::Forbidden(format!(
                    "Listing limit reached ({listings_used}/{quota}). Upload more compliance documents to unlock more listings."
                )));
            }
        }
    }

    let listing_id = Uuid::new_v4();
    let image_urls = req.image_urls.unwrap_or_default();
    let tags = req.tags.unwrap_or_default();
    let currency = req.currency.unwrap_or_else(|| "USD".to_string());

    let mut tx = state.db.begin().await?;

    sqlx::query(
        "INSERT INTO listings (id, operator_id, destination_id, listing_type, title, description, base_price, currency, image_urls, tags)
         VALUES ($1, $2, $3, $4::listing_type, $5, $6, $7, $8, $9, $10)",
    )
    .bind(listing_id)
    .bind(auth.id)
    .bind(req.destination_id)
    .bind(&req.listing_type)
    .bind(title)
    .bind(req.description.as_deref())
    .bind(req.base_price)
    .bind(&currency)
    .bind(&image_urls)
    .bind(&tags)
    .execute(&mut *tx)
    .await?;

    match req.listing_type.as_str() {
        "site" => {
            if let Some(d) = req.site_details {
                let highlights = d.highlights.unwrap_or_default();
                sqlx::query(
                    "INSERT INTO site_details (listing_id, address, latitude, longitude, duration_hours, max_capacity, includes_transport, highlights)
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
                )
                .bind(listing_id)
                .bind(d.address.as_deref())
                .bind(d.latitude)
                .bind(d.longitude)
                .bind(d.duration_hours)
                .bind(d.max_capacity)
                .bind(d.includes_transport.unwrap_or(false))
                .bind(&highlights)
                .execute(&mut *tx)
                .await?;
            } else {
                sqlx::query("INSERT INTO site_details (listing_id) VALUES ($1)")
                    .bind(listing_id)
                    .execute(&mut *tx)
                    .await?;
            }
        }
        "experience" => {
            if let Some(d) = req.experience_details {
                sqlx::query(
                    "INSERT INTO experience_details (listing_id, theme, duration_hours, min_participants, max_participants)
                     VALUES ($1, $2, $3, $4, $5)",
                )
                .bind(listing_id)
                .bind(d.theme.as_deref())
                .bind(d.duration_hours)
                .bind(d.min_participants)
                .bind(d.max_participants)
                .execute(&mut *tx)
                .await?;

                if let Some(site_ids) = d.site_ids {
                    for (i, site_id) in site_ids.iter().enumerate() {
                        sqlx::query(
                            "INSERT INTO experience_sites (experience_id, site_id, sequence_order) VALUES ($1, $2, $3)",
                        )
                        .bind(listing_id)
                        .bind(site_id)
                        .bind((i + 1) as i32)
                        .execute(&mut *tx)
                        .await?;
                    }
                }
            } else {
                sqlx::query("INSERT INTO experience_details (listing_id) VALUES ($1)")
                    .bind(listing_id)
                    .execute(&mut *tx)
                    .await?;
            }
        }
        "trip" => {
            if let Some(d) = req.trip_details {
                sqlx::query(
                    "INSERT INTO trip_details (listing_id, duration_days, max_participants, difficulty_level)
                     VALUES ($1, $2, $3, $4)",
                )
                .bind(listing_id)
                .bind(d.duration_days)
                .bind(d.max_participants)
                .bind(d.difficulty_level.as_deref())
                .execute(&mut *tx)
                .await?;
            } else {
                sqlx::query("INSERT INTO trip_details (listing_id) VALUES ($1)")
                    .bind(listing_id)
                    .execute(&mut *tx)
                    .await?;
            }
        }
        "safari" => {
            if let Some(d) = req.safari_details {
                sqlx::query(
                    "INSERT INTO safari_details (listing_id, park_name, vehicle_class, game_drive_window, park_fee_amount, park_fee_currency)
                     VALUES ($1, $2, $3, $4, $5, $6)",
                )
                .bind(listing_id)
                .bind(d.park_name.as_deref())
                .bind(d.vehicle_class.as_deref())
                .bind(d.game_drive_window.as_deref())
                .bind(d.park_fee_amount)
                .bind(d.park_fee_currency.as_deref())
                .execute(&mut *tx)
                .await?;
            } else {
                sqlx::query("INSERT INTO safari_details (listing_id) VALUES ($1)")
                    .bind(listing_id)
                    .execute(&mut *tx)
                    .await?;
            }
        }
        _ => {}
    }

    tx.commit().await?;

    get_listing(State(state), Path(listing_id)).await
}

pub async fn update_listing(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdateListingRequest>,
) -> AppResult<Json<Value>> {
    if auth.role != "admin" {
        let owner: Option<Uuid> = sqlx::query_scalar(
            "SELECT operator_id FROM listings WHERE id = $1 AND deleted_at IS NULL",
        )
        .bind(id)
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

    if let Some(s) = &req.status {
        if !["draft", "active", "paused", "archived"].contains(&s.as_str()) {
            return Err(AppError::BadRequest(format!("Invalid status: {}", s)));
        }
    }

    let listing_type: String = sqlx::query_scalar(
        "SELECT listing_type::text FROM listings WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Listing not found".to_string()))?;

    sqlx::query(
        r#"UPDATE listings SET
             title = COALESCE($2, title),
             description = COALESCE($3, description),
             base_price = COALESCE($4, base_price),
             status = COALESCE($5::listing_status, status),
             image_urls = COALESCE($6, image_urls),
             tags = COALESCE($7, tags),
             updated_at = now()
           WHERE id = $1 AND deleted_at IS NULL"#,
    )
    .bind(id)
    .bind(req.title.as_deref())
    .bind(req.description.as_deref())
    .bind(req.base_price)
    .bind(req.status.as_deref())
    .bind(req.image_urls.as_deref())
    .bind(req.tags.as_deref())
    .execute(&state.db)
    .await?;

    if req.capacity.is_some() || req.duration_hours.is_some() {
        match listing_type.as_str() {
            "site" => {
                sqlx::query(
                    r#"UPDATE site_details SET
                         max_capacity = COALESCE($2, max_capacity),
                         duration_hours = COALESCE($3, duration_hours)
                       WHERE listing_id = $1"#,
                )
                .bind(id)
                .bind(req.capacity)
                .bind(req.duration_hours)
                .execute(&state.db)
                .await?;
            }
            "experience" => {
                sqlx::query(
                    r#"UPDATE experience_details SET
                         max_participants = COALESCE($2, max_participants),
                         duration_hours = COALESCE($3, duration_hours)
                       WHERE listing_id = $1"#,
                )
                .bind(id)
                .bind(req.capacity)
                .bind(req.duration_hours)
                .execute(&state.db)
                .await?;
            }
            "trip" => {
                let duration_days = req
                    .duration_hours
                    .map(|h| (h / 24.0).ceil().max(1.0) as i32);
                sqlx::query(
                    r#"UPDATE trip_details SET
                         max_participants = COALESCE($2, max_participants),
                         duration_days = COALESCE($3, duration_days)
                       WHERE listing_id = $1"#,
                )
                .bind(id)
                .bind(req.capacity)
                .bind(duration_days)
                .execute(&state.db)
                .await?;
            }
            _ => {}
        }
    }

    get_listing(State(state), Path(id)).await
}

pub async fn delete_listing(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    if auth.role != "admin" {
        let owner: Option<Uuid> = sqlx::query_scalar(
            "SELECT operator_id FROM listings WHERE id = $1 AND deleted_at IS NULL",
        )
        .bind(id)
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

    let result =
        sqlx::query("UPDATE listings SET deleted_at = now(), updated_at = now() WHERE id = $1")
            .bind(id)
            .execute(&state.db)
            .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("Listing not found".to_string()));
    }

    Ok(Json(json!({ "message": "Listing deleted", "id": id })))
}

async fn fetch_operator_listings(
    db: &sqlx::PgPool,
    operator_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Value> {
    let rows = sqlx::query(
        r#"SELECT l.id, l.operator_id, l.listing_type::text as listing_type, l.title,
                  l.base_price, l.currency, l.status::text as status,
                  l.image_urls, l.created_at::text as created_at,
                  d.name as destination_name, d.country as destination_country,
                  u.full_name as operator_name, l.destination_id, l.tags, l.description,
                  COALESCE(sd.max_capacity, ed.max_participants, td.max_participants) as capacity,
                  COALESCE(sd.duration_hours, ed.duration_hours, td.duration_days::float * 24.0) as duration_hours
           FROM listings l
           JOIN destinations d ON d.id = l.destination_id
           JOIN users u ON u.id = l.operator_id
           LEFT JOIN site_details sd ON sd.listing_id = l.id
           LEFT JOIN experience_details ed ON ed.listing_id = l.id
           LEFT JOIN trip_details td ON td.listing_id = l.id
           WHERE l.operator_id = $1 AND l.deleted_at IS NULL
           ORDER BY l.created_at DESC
           LIMIT $2 OFFSET $3"#,
    )
    .bind(operator_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM listings WHERE operator_id = $1 AND deleted_at IS NULL",
    )
    .bind(operator_id)
    .fetch_one(db)
    .await?;

    let listings: Vec<Value> = rows.iter().map(row_to_listing).collect();
    Ok(json!({ "data": listings, "total": total, "limit": limit, "offset": offset }))
}

pub async fn operator_listings(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<ListingsQuery>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let body = fetch_operator_listings(&state.db, auth.id, limit, offset).await?;
    Ok(Json(body))
}

/// Same data as [`operator_listings`], but pushed over Server-Sent Events:
/// one immediate snapshot, then a fresh snapshot every time the `listings`
/// table changes (via the `axiomdb_notify_change` trigger from migration
/// 019, relayed through `AppState::db_changes`). Auth and query-scoping
/// mirror `operator_listings` exactly — this is the same data, just live.
pub async fn operator_listings_stream(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<ListingsQuery>,
) -> AppResult<Sse<impl futures::Stream<Item = Result<Event, Infallible>>>> {
    auth.require_operator()?;

    let operator_id = auth.id;
    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);
    let db = state.db.clone();
    let mut changes = state.db_changes.subscribe();

    let stream = async_stream::stream! {
        match fetch_operator_listings(&db, operator_id, limit, offset).await {
            Ok(snapshot) => yield Ok(Event::default().event("listings").data(snapshot.to_string())),
            Err(e) => tracing::warn!("operator_listings_stream: initial snapshot failed: {e}"),
        }

        loop {
            match changes.recv().await {
                Ok(table) if table == "listings" => {
                    match fetch_operator_listings(&db, operator_id, limit, offset).await {
                        Ok(snapshot) => {
                            yield Ok(Event::default().event("listings").data(snapshot.to_string()))
                        }
                        Err(e) => {
                            tracing::warn!("operator_listings_stream: refetch failed: {e}");
                        }
                    }
                }
                Ok(_) => continue,
                Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
                Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
            }
        }
    };

    Ok(Sse::new(stream).keep_alive(KeepAlive::default()))
}

pub async fn admin_moderate_listing(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let status = body["status"]
        .as_str()
        .ok_or_else(|| AppError::BadRequest("status field required".to_string()))?;

    sqlx::query(
        "UPDATE listings SET status = $1::listing_status, updated_at = now() WHERE id = $2",
    )
    .bind(status)
    .bind(id)
    .execute(&state.db)
    .await?;

    sqlx::query(
        "INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id) VALUES ($1, $2, 'listing', $3)",
    )
    .bind(auth.id)
    .bind(format!("listing_{}", status))
    .bind(id)
    .execute(&state.db)
    .await?;

    Ok(Json(
        json!({ "message": "Listing status updated", "id": id, "status": status }),
    ))
}
