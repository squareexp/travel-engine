use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use serde_json::{json, Value};
use uuid::Uuid;

use super::client::PistoniClient;
use crate::{
    app::AppState,
    auth::AuthUser,
    error::{AppError, AppResult},
};

#[derive(Deserialize)]
pub struct CarsQuery {
    pub status: Option<String>,
    pub skip: Option<i32>,
    pub take: Option<i32>,
}

/// GET /api/v1/transport/cars — list available cars from Pistoni
pub async fn list_cars(
    State(state): State<AppState>,
    _auth: AuthUser,
    Query(params): Query<CarsQuery>,
) -> AppResult<Json<Value>> {
    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);
    let result = client
        .list_cars(
            params.status.as_deref(),
            params.skip.unwrap_or(0),
            params.take.unwrap_or(20),
        )
        .await
        .map_err(|e| AppError::ExternalService(e.to_string()))?;
    Ok(Json(result))
}

/// GET /api/v1/transport/cars/:id
pub async fn get_car(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(car_id): Path<String>,
) -> AppResult<Json<Value>> {
    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);
    let result = client
        .get_car(&car_id)
        .await
        .map_err(|e| AppError::ExternalService(e.to_string()))?;
    Ok(Json(result))
}

/// POST /api/v1/transport/calculate-fare
pub async fn calculate_fare(
    State(state): State<AppState>,
    _auth: AuthUser,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);
    let result = client
        .calculate_price(&body)
        .await
        .map_err(|e| AppError::ExternalService(e.to_string()))?;
    Ok(Json(result))
}

/// POST /api/v1/transport/calculate-route-fare
pub async fn calculate_route_fare(
    State(state): State<AppState>,
    _auth: AuthUser,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);
    let result = client
        .calculate_route_price(&body)
        .await
        .map_err(|e| AppError::ExternalService(e.to_string()))?;
    Ok(Json(result))
}

/// POST /api/v1/transport/book — book a car via Pistoni and record the transport leg
pub async fn book_transport(
    State(state): State<AppState>,
    _auth: AuthUser,
    Json(body): Json<Value>,
) -> AppResult<Json<Value>> {
    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);
    let booking_id: Option<Uuid> = body["booking_id"].as_str().and_then(|s| s.parse().ok());

    let rental_result = client
        .create_rental(&body)
        .await
        .map_err(|e| AppError::ExternalService(e.to_string()))?;

    let external_id = rental_result["id"].as_str().unwrap_or("").to_string();
    let fare = rental_result["totalPrice"]
        .as_f64()
        .or_else(|| body["totalPrice"].as_f64())
        .unwrap_or(0.0);

    let leg_id = Uuid::new_v4();
    sqlx::query(
        "INSERT INTO transport_legs
           (id, booking_id, external_ride_id, pickup_address, dropoff_address,
            fare_amount, currency, status, pistoni_response)
         VALUES ($1, $2, $3, $4, $5, $6, 'USD', 'pending', $7)",
    )
    .bind(leg_id)
    .bind(booking_id)
    .bind(&external_id)
    .bind(body["pickupAddress"].as_str().unwrap_or(""))
    .bind(body["dropoffAddress"].as_str().unwrap_or(""))
    .bind(fare)
    .bind(&rental_result)
    .execute(&state.db)
    .await?;

    Ok(Json(json!({
        "transport_leg_id": leg_id,
        "external_rental_id": external_id,
        "fare_amount": fare,
        "pistoni_response": rental_result
    })))
}

/// GET /api/v1/transport/rides/:id — get rental status from Pistoni
pub async fn get_ride_status(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(rental_id): Path<String>,
) -> AppResult<Json<Value>> {
    let client = PistoniClient::new(&state.config.transport.pistoni_api_url);
    let result = client
        .get_rental(&rental_id)
        .await
        .map_err(|e| AppError::ExternalService(e.to_string()))?;

    if let Some(status) = result["status"].as_str() {
        sqlx::query(
            "UPDATE transport_legs SET status = $1, updated_at = now() WHERE external_ride_id = $2",
        )
        .bind(status)
        .bind(&rental_id)
        .execute(&state.db)
        .await
        .ok();
    }

    Ok(Json(result))
}
