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
pub struct CreateBookingRequest {
    pub listing_id: Uuid,
    pub availability_id: Option<Uuid>,
    pub travel_date: Option<String>,
    pub guests: i32,
    pub special_requests: Option<String>,
    pub transport_request: Option<TransportRequest>,
}

#[derive(Deserialize)]
pub struct TransportRequest {
    pub car_id: String,
    pub pickup_address: String,
    pub dropoff_address: String,
    pub pickup_lat: Option<f64>,
    pub pickup_lng: Option<f64>,
    pub dropoff_lat: Option<f64>,
    pub dropoff_lng: Option<f64>,
    pub start_date: String,
    pub end_date: String,
    pub distance_km: Option<f64>,
}

#[derive(Deserialize)]
pub struct BookingListQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
    pub status: Option<String>,
}

fn row_to_booking(r: &sqlx::postgres::PgRow) -> Value {
    json!({
        "id": r.try_get::<Uuid, _>("id").ok(),
        "user_id": r.try_get::<Uuid, _>("user_id").ok(),
        "user_email": r.try_get::<String, _>("user_email").unwrap_or_default(),
        "user_name": r.try_get::<String, _>("user_name").unwrap_or_default(),
        "listing_id": r.try_get::<Uuid, _>("listing_id").ok(),
        "listing_title": r.try_get::<String, _>("listing_title").unwrap_or_default(),
        "availability_id": r.try_get::<Option<Uuid>, _>("availability_id").unwrap_or_default(),
        "guests": r.try_get::<i32, _>("guests").unwrap_or(0),
        "total_amount": r.try_get::<sqlx::types::BigDecimal, _>("total_amount")
            .map(|v| v.to_string()).ok(),
        "currency": r.try_get::<String, _>("currency").unwrap_or_else(|_| "USD".into()),
        "status": r.try_get::<String, _>("status").unwrap_or_default(),
        "special_requests": r.try_get::<Option<String>, _>("special_requests").unwrap_or_default(),
        "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
    })
}

pub async fn create_booking_full(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreateBookingRequest>,
) -> AppResult<Json<Value>> {
    if req.guests < 1 {
        return Err(AppError::BadRequest(
            "guests must be at least 1".to_string(),
        ));
    }

    let listing_row = sqlx::query(
        "SELECT id, operator_id, base_price::text as price_str, currency, title, status::text as status
         FROM listings WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(req.listing_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Listing not found".to_string()))?;

    let listing_status = listing_row
        .try_get::<String, _>("status")
        .unwrap_or_default();
    if listing_status != "active" {
        return Err(AppError::BadRequest(
            "Listing is not available for booking".to_string(),
        ));
    }

    let price_str = listing_row
        .try_get::<String, _>("price_str")
        .unwrap_or_default();
    let base_price: f64 = price_str.parse().unwrap_or(0.0);
    let currency = listing_row
        .try_get::<String, _>("currency")
        .unwrap_or_else(|_| "USD".into());
    let listing_title = listing_row
        .try_get::<String, _>("title")
        .unwrap_or_default();

    // Resolve availability_id
    let avail_id = if let Some(aid) = req.availability_id {
        Some(aid)
    } else if let Some(ref date) = req.travel_date {
        sqlx::query_scalar(
            "SELECT id FROM availability WHERE listing_id = $1 AND travel_date = $2::date",
        )
        .bind(req.listing_id)
        .bind(date.as_str())
        .fetch_optional(&state.db)
        .await?
    } else {
        None
    };

    let total_amount = base_price * req.guests as f64;
    let booking_id = Uuid::new_v4();

    let mut tx = state.db.begin().await?;

    // Reserve capacity (with row-level lock to prevent oversell)
    if let Some(aid) = avail_id {
        let updated = sqlx::query(
            r#"UPDATE availability
               SET capacity_booked = capacity_booked + $1, updated_at = now()
               WHERE id = $2 AND (capacity - capacity_booked) >= $1
               RETURNING id"#,
        )
        .bind(req.guests)
        .bind(aid)
        .fetch_optional(&mut *tx)
        .await?;

        if updated.is_none() {
            tx.rollback().await?;
            return Err(AppError::Conflict(
                "Not enough availability for requested guest count".to_string(),
            ));
        }
    }

    sqlx::query(
        "INSERT INTO bookings (id, user_id, listing_id, availability_id, guests, total_amount, currency, special_requests, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending')",
    )
    .bind(booking_id)
    .bind(auth.id)
    .bind(req.listing_id)
    .bind(avail_id)
    .bind(req.guests)
    .bind(total_amount)
    .bind(&currency)
    .bind(req.special_requests.as_deref())
    .execute(&mut *tx)
    .await?;

    let mut transport_leg_id: Option<Uuid> = None;
    if let Some(tr) = req.transport_request {
        match create_pistoni_transport(&state, &tr, booking_id).await {
            Ok(leg_id) => transport_leg_id = Some(leg_id),
            Err(e) => {
                tx.rollback().await?;
                return Err(AppError::ExternalService(format!(
                    "Transport booking failed: {}",
                    e
                )));
            }
        }
    }

    tx.commit().await?;

    Ok(Json(json!({
        "id": booking_id,
        "listing_id": req.listing_id,
        "listing_title": listing_title,
        "user_id": auth.id,
        "availability_id": avail_id,
        "guests": req.guests,
        "total_amount": total_amount,
        "currency": currency,
        "status": "pending",
        "transport_leg_id": transport_leg_id,
        "message": "Booking created. Please proceed with payment."
    })))
}

async fn create_pistoni_transport(
    state: &AppState,
    tr: &TransportRequest,
    booking_id: Uuid,
) -> anyhow::Result<Uuid> {
    use crate::transport::client::PistoniClient;

    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);

    let price_req = json!({
        "carId": tr.car_id,
        "startDate": tr.start_date,
        "endDate": tr.end_date,
        "distanceKm": tr.distance_km.unwrap_or(10.0)
    });

    let price_resp = client.calculate_price(&price_req).await?;
    let fare = price_resp["totalPrice"].as_f64().unwrap_or(0.0);

    let rental_req = json!({
        "carId": tr.car_id,
        "userId": booking_id.to_string(),
        "startDate": tr.start_date,
        "endDate": tr.end_date,
        "totalPrice": fare,
        "pickupLocationId": "twende-pickup",
        "dropoffLocationId": "twende-dropoff",
        "distanceKm": tr.distance_km.unwrap_or(10.0)
    });

    let rental_resp = client.create_rental(&rental_req).await?;
    let external_id = rental_resp["id"].as_str().unwrap_or("").to_string();

    let leg_id = Uuid::new_v4();
    sqlx::query(
        "INSERT INTO transport_legs (id, booking_id, external_ride_id, pickup_address, dropoff_address,
           pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, fare_amount, currency, status, pistoni_response)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'USD', 'pending', $11)",
    )
    .bind(leg_id)
    .bind(booking_id)
    .bind(&external_id)
    .bind(&tr.pickup_address)
    .bind(&tr.dropoff_address)
    .bind(tr.pickup_lat)
    .bind(tr.pickup_lng)
    .bind(tr.dropoff_lat)
    .bind(tr.dropoff_lng)
    .bind(fare)
    .bind(&rental_resp)
    .execute(&state.db)
    .await?;

    Ok(leg_id)
}

pub async fn list_bookings(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<BookingListQuery>,
) -> AppResult<Json<Value>> {
    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = if auth.role == "admin" {
        sqlx::query(
            r#"SELECT b.id, b.user_id, b.listing_id, b.availability_id, b.guests,
                      b.total_amount, b.currency, b.status::text as status,
                      b.special_requests, b.created_at::text as created_at,
                      l.title as listing_title,
                      u.email as user_email, u.full_name as user_name
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
        .await?
    } else {
        sqlx::query(
            r#"SELECT b.id, b.user_id, b.listing_id, b.availability_id, b.guests,
                      b.total_amount, b.currency, b.status::text as status,
                      b.special_requests, b.created_at::text as created_at,
                      l.title as listing_title,
                      u.email as user_email, u.full_name as user_name
               FROM bookings b
               JOIN listings l ON l.id = b.listing_id
               JOIN users u ON u.id = b.user_id
               WHERE b.user_id = $1 AND ($2::text IS NULL OR b.status::text = $2)
               ORDER BY b.created_at DESC LIMIT $3 OFFSET $4"#,
        )
        .bind(auth.id)
        .bind(params.status.as_deref())
        .bind(limit)
        .bind(offset)
        .fetch_all(&state.db)
        .await?
    };

    let total: i64 = if auth.role == "admin" {
        sqlx::query_scalar(
            "SELECT COUNT(*) FROM bookings WHERE ($1::text IS NULL OR status::text = $1)",
        )
        .bind(params.status.as_deref())
        .fetch_one(&state.db)
        .await?
    } else {
        sqlx::query_scalar(
            "SELECT COUNT(*) FROM bookings WHERE user_id = $1 AND ($2::text IS NULL OR status::text = $2)",
        )
        .bind(auth.id)
        .bind(params.status.as_deref())
        .fetch_one(&state.db)
        .await?
    };

    let bookings: Vec<Value> = rows.iter().map(row_to_booking).collect();
    Ok(Json(
        json!({ "data": bookings, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn get_booking(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    let row = sqlx::query(
        r#"SELECT b.id, b.user_id, b.listing_id, b.availability_id, b.guests,
                  b.total_amount, b.currency, b.status::text as status,
                  b.special_requests, b.created_at::text as created_at,
                  l.title as listing_title, l.operator_id,
                  u.email as user_email, u.full_name as user_name
           FROM bookings b
           JOIN listings l ON l.id = b.listing_id
           JOIN users u ON u.id = b.user_id
           WHERE b.id = $1"#,
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Booking not found".to_string()))?;

    let user_id = row
        .try_get::<Uuid, _>("user_id")
        .ok()
        .unwrap_or(Uuid::nil());
    let operator_id = row
        .try_get::<Uuid, _>("operator_id")
        .ok()
        .unwrap_or(Uuid::nil());

    if auth.role != "admin" && user_id != auth.id && operator_id != auth.id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let transport = sqlx::query(
        r#"SELECT id, external_ride_id, pickup_address, dropoff_address,
                  fare_amount, currency as leg_currency, status
           FROM transport_legs WHERE booking_id = $1"#,
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .map(|t| {
        json!({
            "id": t.try_get::<Uuid, _>("id").ok(),
            "external_ride_id": t.try_get::<String, _>("external_ride_id").unwrap_or_default(),
            "pickup_address": t.try_get::<String, _>("pickup_address").unwrap_or_default(),
            "dropoff_address": t.try_get::<String, _>("dropoff_address").unwrap_or_default(),
            "fare_amount": t.try_get::<Option<sqlx::types::BigDecimal>, _>("fare_amount")
                .ok().flatten().map(|v| v.to_string()),
            "currency": t.try_get::<Option<String>, _>("leg_currency").unwrap_or_default(),
            "status": t.try_get::<String, _>("status").unwrap_or_default()
        })
    });

    let mut result = row_to_booking(&row);
    result["transport"] = json!(transport);
    Ok(Json(result))
}

pub async fn cancel_booking(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    let row = sqlx::query(
        r#"SELECT b.user_id, b.listing_id, b.availability_id, b.guests,
                  b.status::text as status, l.operator_id
           FROM bookings b
           JOIN listings l ON l.id = b.listing_id
           WHERE b.id = $1"#,
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Booking not found".to_string()))?;

    let user_id = row
        .try_get::<Uuid, _>("user_id")
        .ok()
        .unwrap_or(Uuid::nil());
    let operator_id = row
        .try_get::<Uuid, _>("operator_id")
        .ok()
        .unwrap_or(Uuid::nil());
    if auth.role != "admin" && user_id != auth.id && operator_id != auth.id {
        return Err(AppError::Forbidden("Not your booking".to_string()));
    }

    let status = row.try_get::<String, _>("status").unwrap_or_default();
    if status == "cancelled" {
        return Err(AppError::BadRequest(
            "Booking is already cancelled".to_string(),
        ));
    }
    if status == "completed" {
        return Err(AppError::BadRequest(
            "Cannot cancel a completed booking".to_string(),
        ));
    }

    let guests = row.try_get::<i32, _>("guests").unwrap_or(0);
    let avail_id = row
        .try_get::<Option<Uuid>, _>("availability_id")
        .unwrap_or_default();

    let mut tx = state.db.begin().await?;
    sqlx::query("UPDATE bookings SET status = 'cancelled', updated_at = now() WHERE id = $1")
        .bind(id)
        .execute(&mut *tx)
        .await?;

    if let Some(aid) = avail_id {
        sqlx::query(
            "UPDATE availability SET capacity_booked = capacity_booked - $1, updated_at = now() WHERE id = $2",
        )
        .bind(guests)
        .bind(aid)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;
    Ok(Json(json!({ "message": "Booking cancelled", "id": id })))
}

pub async fn operator_bookings(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<BookingListQuery>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT b.id, b.user_id, b.listing_id, b.availability_id, b.guests,
                  b.total_amount, b.currency, b.status::text as status,
                  b.special_requests, b.created_at::text as created_at,
                  l.title as listing_title, l.operator_id,
                  u.email as user_email, u.full_name as user_name
           FROM bookings b
           JOIN listings l ON l.id = b.listing_id
           JOIN users u ON u.id = b.user_id
           WHERE l.operator_id = $1
             AND ($2::text IS NULL OR b.status::text = $2)
           ORDER BY b.created_at DESC LIMIT $3 OFFSET $4"#,
    )
    .bind(auth.id)
    .bind(params.status.as_deref())
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        r#"SELECT COUNT(*) FROM bookings b JOIN listings l ON l.id = b.listing_id
           WHERE l.operator_id = $1 AND ($2::text IS NULL OR b.status::text = $2)"#,
    )
    .bind(auth.id)
    .bind(params.status.as_deref())
    .fetch_one(&state.db)
    .await?;

    let bookings: Vec<Value> = rows.iter().map(row_to_booking).collect();
    Ok(Json(
        json!({ "data": bookings, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn operator_confirm_booking(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let row = sqlx::query(
        "SELECT b.id, b.status::text as status, l.operator_id
         FROM bookings b JOIN listings l ON l.id = b.listing_id WHERE b.id = $1",
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Booking not found".to_string()))?;

    let operator_id = row
        .try_get::<Uuid, _>("operator_id")
        .ok()
        .unwrap_or(Uuid::nil());
    if auth.role != "admin" && operator_id != auth.id {
        return Err(AppError::Forbidden("Not your booking".to_string()));
    }

    let status = row.try_get::<String, _>("status").unwrap_or_default();
    if status != "pending" {
        return Err(AppError::BadRequest(format!(
            "Cannot confirm booking in status '{}'",
            status
        )));
    }

    sqlx::query("UPDATE bookings SET status = 'confirmed', updated_at = now() WHERE id = $1")
        .bind(id)
        .execute(&state.db)
        .await?;

    Ok(Json(
        json!({ "message": "Booking confirmed", "id": id, "status": "confirmed" }),
    ))
}
