use anyhow::{bail, Context, Result};

#[derive(Clone)]
pub struct Config {
    pub database: DatabaseConfig,
    pub redis: RedisConfig,
    pub jwt: JwtConfig,
    pub google_maps: GoogleMapsConfig,
    pub payments: PaymentsConfig,
    pub server: ServerConfig,
    pub transport: TransportConfig,
    pub logging: LoggingConfig,
    pub base_idp: BaseIdpConfig,
}

#[derive(Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub direct_url: String,
}

#[derive(Clone)]
pub struct RedisConfig {
    pub url: Option<String>,
}

#[derive(Clone)]
pub struct JwtConfig {
    pub secret: String,
    pub refresh_secret: String,
}

#[derive(Clone)]
pub struct GoogleMapsConfig {
    pub api_key: Option<String>,
}

#[derive(Clone)]
pub struct PaymentsConfig {
    pub webhook_secret: Option<String>,
}

#[derive(Clone)]
pub struct ServerConfig {
    pub port: u16,
}

#[derive(Clone)]
pub struct TransportConfig {
    pub pistoni_api_url: String,
}

#[derive(Clone)]
pub struct LoggingConfig {
    pub rust_log: String,
}

#[derive(Clone)]
pub struct BaseIdpConfig {
    pub issuer: String,
    pub client_id: Option<String>,
    pub client_secret: Option<String>,
    pub audience: String,
    pub mobile_redirect_uri: String,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        let database_url = required_var("DATABASE_URL")?;
        let jwt_secret = required_secret("JWT_SECRET")?;
        let jwt_refresh_secret = required_secret("JWT_REFRESH_SECRET")?;
        let base_idp_client_id = optional_var("BASE_IDP_CLIENT_ID");
        let base_idp_client_secret = optional_var("BASE_IDP_CLIENT_SECRET");

        if base_idp_client_id.is_some() != base_idp_client_secret.is_some() {
            bail!("BASE_IDP_CLIENT_ID and BASE_IDP_CLIENT_SECRET must be set together");
        }

        Ok(Self {
            database: DatabaseConfig {
                url: database_url.clone(),
                direct_url: optional_var("DIRECT_URL").unwrap_or(database_url),
            },
            redis: RedisConfig {
                url: optional_var("REDIS_URL"),
            },
            jwt: JwtConfig {
                secret: jwt_secret,
                refresh_secret: jwt_refresh_secret,
            },
            google_maps: GoogleMapsConfig {
                api_key: optional_var("GOOGLE_MAPS_API_KEY"),
            },
            payments: PaymentsConfig {
                webhook_secret: optional_var("PAYMENTS_WEBHOOK_SECRET"),
            },
            server: ServerConfig {
                port: optional_var("SERVER_PORT")
                    .unwrap_or_else(|| "8090".to_string())
                    .parse()
                    .context("SERVER_PORT must be a valid port number")?,
            },
            transport: TransportConfig {
                pistoni_api_url: required_var("PISTONI_API_URL")?,
            },
            logging: LoggingConfig {
                rust_log: optional_var("RUST_LOG").unwrap_or_else(|| "info".to_string()),
            },
            base_idp: BaseIdpConfig {
                issuer: optional_var("BASE_IDP_ISSUER")
                    .unwrap_or_else(|| "http://localhost:8080".to_string()),
                client_id: base_idp_client_id,
                client_secret: base_idp_client_secret,
                audience: optional_var("BASE_IDP_AUDIENCE")
                    .unwrap_or_else(|| "square-experience".to_string()),
                mobile_redirect_uri: optional_var("BASE_IDP_MOBILE_REDIRECT_URI")
                    .unwrap_or_else(|| "twende://auth/callback".to_string()),
            },
        })
    }
}

fn required_var(name: &str) -> Result<String> {
    optional_var(name).with_context(|| format!("{name} must be set"))
}

fn required_secret(name: &str) -> Result<String> {
    let value = required_var(name)?;
    if value.len() < 32 {
        bail!("{name} must be at least 32 characters long");
    }
    Ok(value)
}

fn optional_var(name: &str) -> Option<String> {
    std::env::var(name)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
}

#[cfg(test)]
mod tests {
    use super::required_secret;

    #[test]
    fn required_secret_rejects_values_shorter_than_32_characters() {
        std::env::set_var("TWENDE_TEST_SHORT_SECRET", "too-short");
        let error = required_secret("TWENDE_TEST_SHORT_SECRET").unwrap_err();
        assert!(error.to_string().contains("at least 32 characters"));
        std::env::remove_var("TWENDE_TEST_SHORT_SECRET");
    }
}
