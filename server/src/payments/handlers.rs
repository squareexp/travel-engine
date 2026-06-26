use axum::{
    extract::{Path, State},
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
pub struct CreatePaymentRequest {
    pub booking_id: Uuid,
    pub gateway: String,
    pub gateway_reference: String,
    pub currency: String,
    pub amount: f64,
}

#[derive(Deserialize)]
pub struct WebhookPayload {
    pub gateway_reference: String,
    pub status: String,
    pub gateway: String,
    pub metadata: Option<Value>,
}

fn row_to_payment(r: &sqlx::postgres::PgRow) -> Value {
    json!({
        "id": r.try_get::<Uuid, _>("id").ok(),
        "booking_id": r.try_get::<Uuid, _>("booking_id").ok(),
        "gateway": r.try_get::<String, _>("gateway").unwrap_or_default(),
        "gateway_reference": r.try_get::<String, _>("gateway_reference").unwrap_or_default(),
        "currency": r.try_get::<String, _>("currency").unwrap_or_default(),
        "amount": r.try_get::<sqlx::types::BigDecimal, _>("amount")
            .map(|v| v.to_string()).ok(),
        "status": r.try_get::<String, _>("status").unwrap_or_default(),
        "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
    })
}

pub async fn create_payment(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreatePaymentRequest>,
) -> AppResult<Json<Value>> {
    let booking = sqlx::query(
        "SELECT id, user_id, total_amount, currency, status::text as status FROM bookings WHERE id = $1",
    )
    .bind(req.booking_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Booking not found".to_string()))?;

    let user_id = booking
        .try_get::<Uuid, _>("user_id")
        .ok()
        .unwrap_or(Uuid::nil());
    if auth.role != "admin" && user_id != auth.id {
        return Err(AppError::Forbidden("Not your booking".to_string()));
    }

    let bstatus = booking.try_get::<String, _>("status").unwrap_or_default();
    if bstatus == "cancelled" {
        return Err(AppError::BadRequest(
            "Cannot pay for a cancelled booking".to_string(),
        ));
    }

    let payment_id = Uuid::new_v4();

    let row = sqlx::query(
        r#"INSERT INTO payments (id, booking_id, gateway, gateway_reference, currency, amount, status)
           VALUES ($1, $2, $3, $4, $5, $6, 'pending')
           ON CONFLICT (gateway_reference) DO NOTHING
           RETURNING id, booking_id, gateway, gateway_reference, currency, amount,
                     status::text as status, created_at::text as created_at"#,
    )
    .bind(payment_id)
    .bind(req.booking_id)
    .bind(&req.gateway)
    .bind(&req.gateway_reference)
    .bind(&req.currency)
    .bind(req.amount)
    .fetch_optional(&state.db)
    .await?;

    match row {
        None => {
            let existing = sqlx::query(
                "SELECT id, booking_id, gateway, gateway_reference, currency, amount,
                        status::text as status, created_at::text as created_at
                 FROM payments WHERE gateway_reference = $1",
            )
            .bind(&req.gateway_reference)
            .fetch_one(&state.db)
            .await?;
            let mut r = row_to_payment(&existing);
            r["note"] = json!("existing payment returned (idempotent)");
            Ok(Json(r))
        }
        Some(r) => Ok(Json(row_to_payment(&r))),
    }
}

pub async fn get_payment(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    let row = sqlx::query(
        r#"SELECT p.id, p.booking_id, p.gateway, p.gateway_reference, p.currency, p.amount,
                  p.status::text as status, p.created_at::text as created_at, b.user_id
           FROM payments p JOIN bookings b ON b.id = p.booking_id WHERE p.id = $1"#,
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Payment not found".to_string()))?;

    let uid = row
        .try_get::<Uuid, _>("user_id")
        .ok()
        .unwrap_or(Uuid::nil());
    if auth.role != "admin" && uid != auth.id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    Ok(Json(row_to_payment(&row)))
}

pub async fn payment_webhook(
    State(state): State<AppState>,
    Json(payload): Json<WebhookPayload>,
) -> AppResult<Json<Value>> {
    if !["succeeded", "failed", "refunded"].contains(&payload.status.as_str()) {
        return Err(AppError::BadRequest(format!(
            "Unknown status: {}",
            payload.status
        )));
    }

    let meta = payload.metadata.as_ref().unwrap_or(&json!({})).clone();

    let row = sqlx::query(
        r#"UPDATE payments
           SET status = $1::payment_status, gateway_metadata = $2, updated_at = now()
           WHERE gateway_reference = $3
           RETURNING id, booking_id, status::text as status"#,
    )
    .bind(&payload.status)
    .bind(&meta)
    .bind(&payload.gateway_reference)
    .fetch_optional(&state.db)
    .await?;

    let row = match row {
        None => return Ok(Json(json!({ "message": "Payment not found, ignored" }))),
        Some(r) => r,
    };

    let booking_id = row
        .try_get::<Uuid, _>("booking_id")
        .ok()
        .unwrap_or(Uuid::nil());

    if payload.status == "succeeded" {
        sqlx::query(
            "UPDATE bookings SET status = 'confirmed', updated_at = now() WHERE id = $1 AND status = 'pending'",
        )
        .bind(booking_id)
        .execute(&state.db)
        .await?;
    }

    Ok(Json(json!({
        "payment_id": row.try_get::<Uuid, _>("id").ok(),
        "booking_id": booking_id,
        "status": row.try_get::<String, _>("status").unwrap_or_default()
    })))
}

pub async fn admin_refund(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(payment_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let row = sqlx::query(
        "SELECT id, booking_id, status::text as status, amount FROM payments WHERE id = $1",
    )
    .bind(payment_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Payment not found".to_string()))?;

    let status = row.try_get::<String, _>("status").unwrap_or_default();
    if status != "succeeded" {
        return Err(AppError::BadRequest(format!(
            "Cannot refund payment in status '{}'",
            status
        )));
    }

    let booking_id = row
        .try_get::<Uuid, _>("booking_id")
        .ok()
        .unwrap_or(Uuid::nil());
    let amount = row
        .try_get::<sqlx::types::BigDecimal, _>("amount")
        .map(|v| v.to_string())
        .ok();

    let mut tx = state.db.begin().await?;
    sqlx::query("UPDATE payments SET status = 'refunded', updated_at = now() WHERE id = $1")
        .bind(payment_id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE bookings SET status = 'cancelled', updated_at = now() WHERE id = $1")
        .bind(booking_id)
        .execute(&mut *tx)
        .await?;
    sqlx::query(
        "INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id) VALUES ($1, 'payment_refunded', 'payment', $2)",
    )
    .bind(auth.id)
    .bind(payment_id)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;

    Ok(Json(
        json!({ "message": "Payment refunded", "payment_id": payment_id, "amount": amount }),
    ))
}

pub async fn booking_payments(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(booking_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    let booking = sqlx::query("SELECT user_id FROM bookings WHERE id = $1")
        .bind(booking_id)
        .fetch_optional(&state.db)
        .await?
        .ok_or_else(|| AppError::NotFound("Booking not found".to_string()))?;

    let uid = booking
        .try_get::<Uuid, _>("user_id")
        .ok()
        .unwrap_or(Uuid::nil());
    if auth.role != "admin" && uid != auth.id {
        return Err(AppError::Forbidden("Access denied".to_string()));
    }

    let rows = sqlx::query(
        "SELECT id, booking_id, gateway, gateway_reference, currency, amount,
                status::text as status, created_at::text as created_at
         FROM payments WHERE booking_id = $1 ORDER BY created_at DESC",
    )
    .bind(booking_id)
    .fetch_all(&state.db)
    .await?;

    let payments: Vec<Value> = rows.iter().map(row_to_payment).collect();
    Ok(Json(json!({ "data": payments })))
}
