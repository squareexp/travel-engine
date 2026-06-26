use anyhow::{Context, Result};
use reqwest::Client;
use serde_json::Value;

/// HTTP client adapter for the Pistoni car-hire API.
/// Twende sends requests to Pistoni for all transport/car-hire operations.
pub struct PistoniClient {
    client: Client,
    base_url: String,
}

impl PistoniClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            client: Client::new(),
            base_url: base_url.trim_end_matches('/').to_string(),
        }
    }

    pub async fn list_cars(&self, status: Option<&str>, skip: i32, take: i32) -> Result<Value> {
        let mut url = format!("{}/cars?skip={}&take={}", self.base_url, skip, take);
        if let Some(s) = status {
            url.push_str(&format!("&status={}", s));
        }
        let resp = self
            .client
            .get(&url)
            .send()
            .await
            .context("Pistoni list_cars request failed")?
            .json::<Value>()
            .await
            .context("Pistoni list_cars response parse failed")?;
        Ok(resp)
    }

    pub async fn get_car(&self, car_id: &str) -> Result<Value> {
        let resp = self
            .client
            .get(format!("{}/cars/{}", self.base_url, car_id))
            .send()
            .await
            .context("Pistoni get_car request failed")?
            .json::<Value>()
            .await
            .context("Pistoni get_car response parse failed")?;
        Ok(resp)
    }

    pub async fn calculate_price(&self, body: &Value) -> Result<Value> {
        let resp = self
            .client
            .post(format!("{}/rentals/calculate-price", self.base_url))
            .json(body)
            .send()
            .await
            .context("Pistoni calculate_price request failed")?
            .json::<Value>()
            .await
            .context("Pistoni calculate_price response parse failed")?;
        Ok(resp)
    }

    pub async fn calculate_route_price(&self, body: &Value) -> Result<Value> {
        let resp = self
            .client
            .post(format!("{}/rentals/calculate-route-price", self.base_url))
            .json(body)
            .send()
            .await
            .context("Pistoni calculate_route_price request failed")?
            .json::<Value>()
            .await
            .context("Pistoni calculate_route_price response parse failed")?;
        Ok(resp)
    }

    pub async fn create_rental(&self, body: &Value) -> Result<Value> {
        let resp = self
            .client
            .post(format!("{}/rentals", self.base_url))
            .json(body)
            .send()
            .await
            .context("Pistoni create_rental request failed")?
            .json::<Value>()
            .await
            .context("Pistoni create_rental response parse failed")?;
        Ok(resp)
    }

    pub async fn get_rental(&self, rental_id: &str) -> Result<Value> {
        let resp = self
            .client
            .get(format!("{}/rentals/{}", self.base_url, rental_id))
            .send()
            .await
            .context("Pistoni get_rental request failed")?
            .json::<Value>()
            .await
            .context("Pistoni get_rental response parse failed")?;
        Ok(resp)
    }
}
