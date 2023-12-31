use anyhow::Result;
use sqlx::{postgres::PgPoolOptions, PgPool};

pub async fn create_pool(database_url: &str) -> Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .min_connections(0)
        .acquire_timeout(std::time::Duration::from_secs(90))
        .idle_timeout(Some(std::time::Duration::from_secs(600)))
        .max_lifetime(Some(std::time::Duration::from_secs(1800)))
        .connect(database_url)
        .await?;

    Ok(pool)
}
