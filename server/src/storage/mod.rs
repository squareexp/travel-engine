use anyhow::{bail, Context, Result};
use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use reqwest::Client;
use rsa::pkcs8::DecodePrivateKey;
use rsa::{Pkcs1v15Sign, RsaPrivateKey};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};
use time::{format_description, OffsetDateTime};
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct GcsClient {
    inner: Arc<GcsClientInner>,
}

struct GcsClientInner {
    bucket: String,
    email: String,
    encoding_key: EncodingKey,
    signing_key: RsaPrivateKey,
    http: Client,
    cached_token: RwLock<Option<CachedToken>>,
}

struct CachedToken {
    access_token: String,
    expires_at: u64,
}

#[derive(Serialize)]
struct JwtClaims {
    iss: String,
    scope: String,
    aud: String,
    exp: u64,
    iat: u64,
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

#[derive(Deserialize)]
struct ServiceAccountKey {
    client_email: String,
    private_key: String,
}

impl GcsClient {
    pub fn from_credentials(bucket: String, credentials_json: &str) -> Result<Self> {
        let key: ServiceAccountKey =
            serde_json::from_str(credentials_json).context("invalid service account JSON")?;

        let encoding_key = EncodingKey::from_rsa_pem(key.private_key.as_bytes())
            .context("failed to parse service account private key")?;

        let signing_key = RsaPrivateKey::from_pkcs8_pem(&key.private_key)
            .context("failed to parse service account private key for URL signing")?;

        Ok(Self {
            inner: Arc::new(GcsClientInner {
                bucket,
                email: key.client_email,
                encoding_key,
                signing_key,
                http: Client::new(),
                cached_token: RwLock::new(None),
            }),
        })
    }

    /// Reads service-account credentials from `GOOGLE_APPLICATION_CREDENTIALS_JSON`
    /// (raw JSON — the way most deployment platforms want secrets, since it avoids
    /// bundling a file and resolving it relative to a working directory that may
    /// differ at runtime), falling back to `GOOGLE_APPLICATION_CREDENTIALS` as a
    /// file path for local development.
    pub fn from_env(bucket: String) -> Result<Self> {
        if let Ok(json) = std::env::var("GOOGLE_APPLICATION_CREDENTIALS_JSON") {
            return Self::from_credentials(bucket, &json);
        }

        let path = std::env::var("GOOGLE_APPLICATION_CREDENTIALS").context(
            "either GOOGLE_APPLICATION_CREDENTIALS_JSON (raw JSON) or \
             GOOGLE_APPLICATION_CREDENTIALS (file path) must be set",
        )?;
        let json = std::fs::read_to_string(&path)
            .with_context(|| format!("failed to read credentials file: {path}"))?;
        Self::from_credentials(bucket, &json)
    }

    async fn access_token(&self) -> Result<String> {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        {
            let cache = self.inner.cached_token.read().await;
            if let Some(ref t) = *cache {
                if t.expires_at > now + 60 {
                    return Ok(t.access_token.clone());
                }
            }
        }

        let mut cache = self.inner.cached_token.write().await;

        let iat = now;
        let exp = now + 3600;

        let claims = JwtClaims {
            iss: self.inner.email.clone(),
            scope: "https://www.googleapis.com/auth/devstorage.read_write".to_string(),
            aud: "https://oauth2.googleapis.com/token".to_string(),
            exp,
            iat,
        };

        let header = Header::new(Algorithm::RS256);
        let assertion = encode(&header, &claims, &self.inner.encoding_key)
            .context("failed to sign service account JWT")?;

        let resp = self
            .inner
            .http
            .post("https://oauth2.googleapis.com/token")
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", &assertion),
            ])
            .send()
            .await
            .context("token exchange request failed")?;

        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            bail!("GCS token exchange failed: {body}");
        }

        let token: TokenResponse = resp
            .json()
            .await
            .context("failed to parse token response")?;

        let cached = CachedToken {
            access_token: token.access_token.clone(),
            expires_at: now + token.expires_in,
        };
        *cache = Some(cached);

        Ok(token.access_token)
    }

    /// Upload bytes to GCS under the `travel-engine/` prefix.
    /// Returns the object path (relative to the bucket root) — not a public URL,
    /// since the bucket is private. Use `signed_url` to generate a readable link.
    pub async fn upload(
        &self,
        object_name: &str,
        content_type: &str,
        data: Vec<u8>,
    ) -> Result<String> {
        let token = self.access_token().await?;
        let bucket = &self.inner.bucket;
        let prefixed = format!("travel-engine/{object_name}");

        let encoded = urlencoding::encode(&prefixed);
        let url = format!(
            "https://storage.googleapis.com/upload/storage/v1/b/{bucket}/o?uploadType=media&name={encoded}"
        );

        let resp = self
            .inner
            .http
            .post(&url)
            .bearer_auth(&token)
            .header("Content-Type", content_type)
            .body(data)
            .send()
            .await
            .context("GCS upload request failed")?;

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            bail!("GCS upload failed ({status}): {body}");
        }

        Ok(prefixed)
    }

    /// Generate a V4 signed URL granting time-limited GET access to a private object.
    /// `object_path` is the full path within the bucket (e.g. "travel-engine/operators/.../license.pdf").
    pub fn signed_url(&self, object_path: &str, ttl_secs: i64) -> Result<String> {
        let bucket = &self.inner.bucket;
        let now = OffsetDateTime::now_utc();

        let ts_format = format_description::parse("[year][month][day]T[hour][minute][second]Z")
            .context("invalid timestamp format")?;
        let date_format =
            format_description::parse("[year][month][day]").context("invalid date format")?;

        let request_timestamp = now
            .format(&ts_format)
            .context("failed to format timestamp")?;
        let datestamp = now.format(&date_format).context("failed to format date")?;

        let credential_scope = format!("{datestamp}/auto/storage/goog4_request");
        let credential = format!("{}/{}", self.inner.email, credential_scope);

        let canonical_uri = format!("/{bucket}/{}", encode_object_path(object_path));

        let mut query_params: Vec<(&str, String)> = vec![
            ("X-Goog-Algorithm", "GOOG4-RSA-SHA256".to_string()),
            ("X-Goog-Credential", credential),
            ("X-Goog-Date", request_timestamp.clone()),
            ("X-Goog-Expires", ttl_secs.to_string()),
            ("X-Goog-SignedHeaders", "host".to_string()),
        ];
        query_params.sort_by(|a, b| a.0.cmp(b.0));

        let canonical_query_string = query_params
            .iter()
            .map(|(k, v)| format!("{}={}", urlencoding::encode(k), urlencoding::encode(v)))
            .collect::<Vec<_>>()
            .join("&");

        let canonical_headers = "host:storage.googleapis.com\n";
        let signed_headers = "host";

        let canonical_request = format!(
            "GET\n{canonical_uri}\n{canonical_query_string}\n{canonical_headers}\n{signed_headers}\nUNSIGNED-PAYLOAD"
        );

        let hashed_canonical_request = hex::encode(Sha256::digest(canonical_request.as_bytes()));

        let string_to_sign = format!(
            "GOOG4-RSA-SHA256\n{request_timestamp}\n{credential_scope}\n{hashed_canonical_request}"
        );

        let digest = Sha256::digest(string_to_sign.as_bytes());
        let padding = Pkcs1v15Sign::new::<Sha256>();
        let signature = self
            .inner
            .signing_key
            .sign(padding, &digest)
            .context("failed to sign GCS URL")?;
        let signature_hex = hex::encode(signature);

        Ok(format!(
            "https://storage.googleapis.com{canonical_uri}?{canonical_query_string}&X-Goog-Signature={signature_hex}"
        ))
    }
}

fn encode_object_path(path: &str) -> String {
    path.split('/')
        .map(|segment| urlencoding::encode(segment).into_owned())
        .collect::<Vec<_>>()
        .join("/")
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Requires GCS_BUCKET / GOOGLE_APPLICATION_CREDENTIALS in the environment (.env)
    /// and network access. Run with:
    ///   cargo test --package twende-server upload_and_sign_smoke_test -- --ignored --nocapture
    #[tokio::test]
    #[ignore]
    async fn upload_and_sign_smoke_test() {
        dotenvy::dotenv().ok();
        let bucket = std::env::var("GCS_BUCKET").expect("GCS_BUCKET not set");
        let client = GcsClient::from_env(bucket).expect("failed to init GCS client");

        let data =
            std::fs::read("/Users/ajmaljs/Assets/SquareCDS-pricing.pdf").expect("fixture missing");

        let object_path = client
            .upload("test/SquareCDS-pricing.pdf", "application/pdf", data)
            .await
            .expect("upload failed");
        println!("uploaded to: {object_path}");

        let url = client.signed_url(&object_path, 900).expect("sign failed");
        println!("signed url: {url}");

        let resp = reqwest::get(&url).await.expect("fetch failed");
        println!("fetch status: {}", resp.status());
        assert_eq!(resp.status(), reqwest::StatusCode::OK);
    }
}
