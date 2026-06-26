mod admin;
mod app;
mod auth;
mod availability;
mod bookings;
mod config;
mod db;
mod destinations;
mod error;
mod listings;
mod middleware;
mod operators;
mod payments;
mod reviews;
mod transport;

use anyhow::Result;
use std::sync::Arc;
use tracing::info;

#[tokio::main]
async fn main() -> Result<()> {
    // Load .env
    dotenvy::dotenv().ok();

    // Load config
    let config = config::Config::from_env()?;

    // Init tracing
    tracing_subscriber::fmt()
        .with_env_filter(&config.logging.rust_log)
        .init();

    info!("Starting Twende Zanzibar API server");

    // Use DIRECT_URL for the pool (bypasses pgBouncer which rejects SQLx startup params)
    let db = db::create_pool(&config.database.direct_url).await?;
    info!("Database pool connected");

    // Run migrations
    sqlx::migrate!("./migrations").run(&db).await?;
    info!("Migrations applied");

    let base_idp = if let (Some(client_id), Some(client_secret)) = (
        config.base_idp.client_id.clone(),
        config.base_idp.client_secret.clone(),
    ) {
        info!("Base-IdP configured (issuer={})", config.base_idp.issuer);
        Some(auth::base_idp::BaseIdpClient::new(
            config.base_idp.issuer.clone(),
            client_id,
            client_secret,
            config.base_idp.audience.clone(),
            config.base_idp.mobile_redirect_uri.clone(),
        ))
    } else {
        info!("Base-IdP not configured (no BASE_IDP_CLIENT_ID); /auth/idp-exchange disabled");
        None
    };

    let state = app::AppState {
        db,
        config: Arc::new(config.clone()),
        base_idp,
    };

    let router = app::build_router(state);
    let addr = format!("{}:{}", config.server.host, config.server.port);
    info!("Listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, router).await?;

    Ok(())
}
