#![recursion_limit = "256"]

mod admin;
mod app;
mod auth;
mod availability;
mod bookings;
mod compliance;
mod config;
mod db;
mod destinations;
mod error;
mod listings;
mod middleware;
mod operators;
mod payments;
mod reviews;
mod storage;
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

    // Dedicated LISTEN connection for realtime (SSE) endpoints: fans out
    // `axiomdb_changes` notifications (see migration 019) to any number of
    // in-process subscribers via a broadcast channel. Reconnects on drop.
    let (db_changes_tx, _) = tokio::sync::broadcast::channel::<String>(64);
    let db_changes = Arc::new(db_changes_tx);
    {
        let direct_url = config.database.direct_url.clone();
        let tx = db_changes.clone();
        tokio::spawn(async move {
            loop {
                match sqlx::postgres::PgListener::connect(&direct_url).await {
                    Ok(mut listener) => {
                        if let Err(e) = listener.listen("axiomdb_changes").await {
                            tracing::warn!("axiomdb_changes: LISTEN failed: {e}");
                        } else {
                            loop {
                                match listener.recv().await {
                                    Ok(notification) => {
                                        if let Ok(payload) = serde_json::from_str::<serde_json::Value>(
                                            notification.payload(),
                                        ) {
                                            if let Some(table) = payload["table"].as_str() {
                                                let _ = tx.send(table.to_string());
                                            }
                                        }
                                    }
                                    Err(e) => {
                                        tracing::warn!(
                                            "axiomdb_changes: connection lost ({e}), reconnecting"
                                        );
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => {
                        tracing::warn!("axiomdb_changes: connect failed ({e}), retrying");
                    }
                }
                tokio::time::sleep(std::time::Duration::from_secs(5)).await;
            }
        });
    }

    // Run migrations unless explicitly disabled for local diagnostics.
    if std::env::var("SKIP_MIGRATIONS").as_deref() == Ok("true") {
        info!("Migrations skipped because SKIP_MIGRATIONS=true");
    } else {
        sqlx::migrate!("./migrations").run(&db).await?;
        info!("Migrations applied");
    }

    let base_idp = if let Some(client_id) = config.base_idp.client_id.clone() {
        info!("Base-IdP configured (issuer={})", config.base_idp.issuer);
        Some(auth::base_idp::BaseIdpClient::new(
            config.base_idp.issuer.clone(),
            client_id,
            config.base_idp.client_secret.clone().unwrap_or_default(),
            config.base_idp.audience.clone(),
            config.base_idp.mobile_redirect_uri.clone(),
        ))
    } else {
        info!("Base-IdP not configured (no BASE_IDP_CLIENT_ID); /auth/idp-exchange disabled");
        None
    };

    let gcs = if let Some(bucket) = config.gcs.bucket.clone() {
        match storage::GcsClient::from_env(bucket.clone()) {
            Ok(client) => {
                info!("GCS configured (bucket={})", bucket);
                Some(Arc::new(client))
            }
            Err(e) => {
                tracing::warn!("GCS not available: {e}; document uploads disabled");
                None
            }
        }
    } else {
        info!("GCS not configured (no GCS_BUCKET); document uploads disabled");
        None
    };

    let state = app::AppState {
        db,
        config: Arc::new(config.clone()),
        base_idp,
        gcs,
        db_changes,
    };

    let router = app::build_router(state);
    let addr = format!("{}:{}", config.server.host, config.server.port);
    info!("Listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, router).await?;

    Ok(())
}
