use anyhow::{anyhow, Context, Result};
use reqwest::Client as HttpClient;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

#[derive(Debug, Clone, Deserialize)]
pub struct Metadata {
    pub issuer: String,
    pub authorization_endpoint: String,
    pub token_endpoint: String,
    pub paseto_public_key_endpoint: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TokenPair {
    pub access_token: String,
    #[serde(default)]
    pub refresh_token: Option<String>,
    #[serde(default)]
    pub token_type: Option<String>,
    #[serde(default)]
    pub expires_in: Option<i64>,
}

// Shape returned by the IDP's GET /v1/me endpoint.
#[derive(Debug, Clone, Deserialize)]
struct MeResponse {
    #[serde(rename = "sub")]
    pub subject: String,
    #[serde(rename = "gid", default)]
    pub global_id: Option<String>,
    #[serde(rename = "email", default)]
    pub email: Option<String>,
    #[serde(rename = "name", default)]
    pub name: Option<String>,
}

pub struct Principal {
    pub subject: String,
    pub email: Option<String>,
    pub name: Option<String>,
}

#[derive(Clone)]
pub struct BaseIdpClient {
    inner: Arc<Inner>,
}

struct Inner {
    issuer: String,
    client_id: String,
    client_secret: String,
    redirect_uri: String,
    http: HttpClient,
    metadata_cache: parking_lot::RwLock<Option<Metadata>>,
}

impl BaseIdpClient {
    pub fn new(
        issuer: String,
        client_id: String,
        client_secret: String,
        _audience: String,
        redirect_uri: String,
    ) -> Self {
        let http = HttpClient::builder()
            .timeout(Duration::from_secs(15))
            .build()
            .expect("HTTP client");
        Self {
            inner: Arc::new(Inner {
                issuer: issuer.trim_end_matches('/').to_string(),
                client_id,
                client_secret,
                redirect_uri,
                http,
                metadata_cache: parking_lot::RwLock::new(None),
            }),
        }
    }

    pub async fn metadata(&self) -> Result<Metadata> {
        if let Some(m) = self.inner.metadata_cache.read().clone() {
            return Ok(m);
        }
        let url = format!("{}/.well-known/square-identity", self.inner.issuer);
        let metadata: Metadata = self
            .inner
            .http
            .get(&url)
            .send()
            .await
            .with_context(|| format!("base-idp discovery {url}"))?
            .error_for_status()?
            .json()
            .await?;
        *self.inner.metadata_cache.write() = Some(metadata.clone());
        Ok(metadata)
    }

    pub async fn exchange_code(
        &self,
        code: &str,
        code_verifier: Option<&str>,
        redirect_uri: Option<&str>,
    ) -> Result<TokenPair> {
        let metadata = self.metadata().await?;
        let redirect = redirect_uri.unwrap_or(&self.inner.redirect_uri);

        let mut form: HashMap<&str, &str> = HashMap::new();
        form.insert("grant_type", "authorization_code");
        form.insert("code", code);
        form.insert("client_id", &self.inner.client_id);
        form.insert("redirect_uri", redirect);
        if !self.inner.client_secret.is_empty() {
            form.insert("client_secret", &self.inner.client_secret);
        }
        if let Some(v) = code_verifier {
            form.insert("code_verifier", v);
        }

        let resp = self
            .inner
            .http
            .post(&metadata.token_endpoint)
            .header("Accept", "application/json")
            .form(&form)
            .send()
            .await
            .context("base-idp token exchange")?;

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(anyhow!("base-idp token endpoint {}: {}", status, body));
        }

        let pair: TokenPair = resp.json().await.context("decode token pair")?;
        Ok(pair)
    }

    /// Validate an access token by calling the IDP's /v1/me endpoint.
    /// The IDP verifies the PASETO signature, audience, and expiry server-side —
    /// no local cryptography needed.
    pub async fn verify_access_token(&self, token: &str) -> Result<Principal> {
        if token.trim().is_empty() {
            return Err(anyhow!("access token is empty"));
        }
        let url = format!("{}/v1/me", self.inner.issuer);
        let resp = self
            .inner
            .http
            .get(&url)
            .header("Authorization", format!("Bearer {token}"))
            .send()
            .await
            .context("base-idp /v1/me request")?;

        if resp.status() == reqwest::StatusCode::UNAUTHORIZED {
            return Err(anyhow!("IdP rejected the access token (401)"));
        }
        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(anyhow!("base-idp /v1/me returned {}: {}", status, body));
        }

        let me: MeResponse = resp.json().await.context("decode /v1/me response")?;
        if me.subject.is_empty() {
            return Err(anyhow!("base-idp /v1/me: missing subject claim"));
        }

        Ok(Principal {
            subject: me.subject,
            email: me.email,
            name: me.name,
        })
    }
}
