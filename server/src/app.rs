use axum::{
    extract::DefaultBodyLimit,
    http::Method,
    routing::{delete, get, patch, post},
    Extension, Router,
};
use sqlx::PgPool;
use std::sync::Arc;
use tower_http::{
    cors::{Any, CorsLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};

use crate::{
    auth::{base_idp::BaseIdpClient, handlers as auth_handlers, idp_handler, JwtSecret},
    config::Config,
    storage::GcsClient,
};

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub config: Arc<Config>,
    pub base_idp: Option<BaseIdpClient>,
    pub gcs: Option<Arc<GcsClient>>,
    /// Fan-out of Postgres `axiomdb_changes` notifications (table name per
    /// message), fed by a single dedicated LISTEN connection spawned in
    /// `main.rs`. SSE handlers subscribe and filter for their own table.
    pub db_changes: Arc<tokio::sync::broadcast::Sender<String>>,
}

pub fn build_router(state: AppState) -> Router {
    let jwt_secret = JwtSecret(state.config.jwt.secret.clone());

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PATCH,
            Method::DELETE,
            Method::PUT,
            Method::OPTIONS,
        ])
        .allow_headers(Any);

    Router::new()
        // Health
        .route("/healthz", get(healthz))
        // Auth
        .route("/api/v1/auth/register", post(auth_handlers::register))
        .route("/api/v1/auth/login", post(auth_handlers::login))
        .route("/api/v1/auth/refresh", post(auth_handlers::refresh))
        .route("/api/v1/auth/me", get(auth_handlers::me))
        .route("/api/v1/auth/idp-exchange", post(idp_handler::idp_exchange))
        // Destinations (public read, admin write)
        .route(
            "/api/v1/destinations",
            get(crate::destinations::handlers::list_destinations),
        )
        .route(
            "/api/v1/destinations/:id",
            get(crate::destinations::handlers::get_destination),
        )
        .route(
            "/api/v1/admin/destinations",
            post(crate::destinations::handlers::create_destination),
        )
        .route(
            "/api/v1/admin/destinations/:id",
            patch(crate::destinations::handlers::update_destination),
        )
        .route(
            "/api/v1/admin/destinations/:id",
            delete(crate::destinations::handlers::delete_destination),
        )
        // Listings (public read, operator/admin write)
        .route(
            "/api/v1/listings",
            get(crate::listings::handlers::list_listings),
        )
        .route(
            "/api/v1/listings/:id",
            get(crate::listings::handlers::get_listing),
        )
        .route(
            "/api/v1/listings",
            post(crate::listings::handlers::create_listing),
        )
        .route(
            "/api/v1/listings/:id",
            patch(crate::listings::handlers::update_listing),
        )
        .route(
            "/api/v1/listings/:id",
            delete(crate::listings::handlers::delete_listing),
        )
        .route(
            "/api/v1/listings/:id/reviews",
            get(crate::reviews::handlers::listing_reviews),
        )
        .route(
            "/api/v1/listings/:listing_id/reviews/:review_id/reply",
            post(crate::reviews::handlers::operator_reply_review),
        )
        .route(
            "/api/v1/admin/listings/:id/moderate",
            post(crate::listings::handlers::admin_moderate_listing),
        )
        // Operator portal
        .route(
            "/api/v1/operators/me",
            get(crate::operators::handlers::get_my_profile),
        )
        .route(
            "/api/v1/operators/me",
            patch(crate::operators::handlers::update_my_profile),
        )
        .route(
            "/api/v1/operators/me/identity",
            patch(crate::operators::handlers::update_my_identity),
        )
        .route(
            "/api/v1/operators/me/compliance",
            get(crate::operators::handlers::get_my_compliance),
        )
        .route(
            "/api/v1/operators/listings",
            get(crate::listings::handlers::operator_listings),
        )
        .route(
            "/api/v1/operators/listings/stream",
            get(crate::listings::handlers::operator_listings_stream),
        )
        .route(
            "/api/v1/operators/bookings",
            get(crate::bookings::handlers::operator_bookings),
        )
        .route(
            "/api/v1/operators/bookings/:id/confirm",
            post(crate::bookings::handlers::operator_confirm_booking),
        )
        .route(
            "/api/v1/operators/analytics",
            get(crate::operators::handlers::operator_analytics),
        )
        .route(
            "/api/v1/operators/me/documents",
            post(crate::operators::handlers::upload_document),
        )
        // Availability
        .route(
            "/api/v1/listings/:listing_id/availability",
            get(crate::availability::handlers::list_availability),
        )
        .route(
            "/api/v1/listings/:listing_id/availability",
            post(crate::availability::handlers::create_availability),
        )
        .route(
            "/api/v1/listings/:listing_id/availability/:avail_id",
            patch(crate::availability::handlers::update_availability),
        )
        .route(
            "/api/v1/listings/:listing_id/availability/:avail_id",
            delete(crate::availability::handlers::delete_availability),
        )
        // Bookings
        .route(
            "/api/v1/bookings",
            post(crate::bookings::handlers::create_booking_full),
        )
        .route(
            "/api/v1/bookings",
            get(crate::bookings::handlers::list_bookings),
        )
        .route(
            "/api/v1/bookings/:id",
            get(crate::bookings::handlers::get_booking),
        )
        .route(
            "/api/v1/bookings/:id/cancel",
            post(crate::bookings::handlers::cancel_booking),
        )
        .route(
            "/api/v1/bookings/:id/review",
            post(crate::reviews::handlers::create_review),
        )
        .route(
            "/api/v1/bookings/:id/payments",
            get(crate::payments::handlers::booking_payments),
        )
        // Payments
        .route(
            "/api/v1/payments",
            post(crate::payments::handlers::create_payment),
        )
        .route(
            "/api/v1/payments/:id",
            get(crate::payments::handlers::get_payment),
        )
        .route(
            "/api/v1/payments/webhook",
            post(crate::payments::handlers::payment_webhook),
        )
        .route(
            "/api/v1/admin/payments/:id/refund",
            post(crate::payments::handlers::admin_refund),
        )
        // Transport (Pistoni integration)
        .route(
            "/api/v1/transport/cars",
            get(crate::transport::handlers::list_cars),
        )
        .route(
            "/api/v1/transport/cars/:id",
            get(crate::transport::handlers::get_car),
        )
        .route(
            "/api/v1/transport/calculate-fare",
            post(crate::transport::handlers::calculate_fare),
        )
        .route(
            "/api/v1/transport/calculate-route-fare",
            post(crate::transport::handlers::calculate_route_fare),
        )
        .route(
            "/api/v1/transport/book",
            post(crate::transport::handlers::book_transport),
        )
        .route(
            "/api/v1/transport/rides/:id",
            get(crate::transport::handlers::get_ride_status),
        )
        // Admin
        .route(
            "/api/v1/admin/users",
            get(crate::admin::handlers::list_users),
        )
        .route(
            "/api/v1/admin/users/:id",
            get(crate::admin::handlers::get_user),
        )
        .route(
            "/api/v1/admin/users/:id",
            patch(crate::admin::handlers::update_user),
        )
        .route(
            "/api/v1/admin/users/:id",
            delete(crate::admin::handlers::delete_user),
        )
        .route(
            "/api/v1/admin/operators",
            get(crate::operators::handlers::admin_list_operators),
        )
        .route(
            "/api/v1/admin/operators/:id",
            get(crate::operators::handlers::admin_get_operator),
        )
        .route(
            "/api/v1/admin/operators/:id/verify",
            post(crate::operators::handlers::admin_verify_operator),
        )
        .route(
            "/api/v1/admin/bookings",
            get(crate::admin::handlers::admin_list_bookings),
        )
        .route(
            "/api/v1/admin/bookings/:id/complete",
            post(crate::admin::handlers::admin_complete_booking),
        )
        .route(
            "/api/v1/admin/reviews/:id/moderate",
            post(crate::reviews::handlers::admin_moderate_review),
        )
        .route(
            "/api/v1/admin/analytics",
            get(crate::admin::handlers::analytics),
        )
        .route(
            "/api/v1/admin/audit-logs",
            get(crate::admin::handlers::audit_logs),
        )
        .layer(Extension(jwt_secret))
        .layer(cors)
        .layer(TraceLayer::new_for_http())
        .layer(TimeoutLayer::new(std::time::Duration::from_secs(60)))
        // Axum's implicit default is 2MB, too small for phone photos/scans of
        // license & insurance documents. Raise it for the whole API.
        .layer(DefaultBodyLimit::max(25 * 1024 * 1024))
        .with_state(state)
}

async fn healthz(
    axum::extract::State(state): axum::extract::State<AppState>,
) -> axum::Json<serde_json::Value> {
    let db_ok = sqlx::query("SELECT 1").execute(&state.db).await.is_ok();

    axum::Json(serde_json::json!({
        "status": if db_ok { "ok" } else { "degraded" },
        "service": "twende-server",
        "database": if db_ok { "connected" } else { "error" }
    }))
}
