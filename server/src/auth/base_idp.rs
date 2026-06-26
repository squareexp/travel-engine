use anyhow::{anyhow, Context, Result};
use base64::Engine;
use ed25519_dalek::{Verifier, VerifyingKey};
use parking_lot::RwLock;
use reqwest::Client as HttpClient;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};

const DEFAULT_AUDIENCE: &str = "square-experience";
const DEFAULT_IMPLICIT_ASSERTION: &str = "square-experience:idp:access:v1";
const PASETO_HEADER: &[u8] = b"v4.public.";

#[derive(Debug, Clone, Deserialize)]
pub struct Metadata {
    pub issuer: String,
    pub authorization_endpoint: String,
    pub token_endpoint: String,
    pub paseto_public_key_endpoint: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct PublicKey {
    pub kid: String,
    pub alg: String,
    #[allow(dead_code)]
    pub kty: Option<String>,
    pub crv: String,
    pub public_key_base64: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct PublicKeySet {
    pub keys: Vec<PublicKey>,
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

#[derive(Debug, Deserialize)]
struct FooterJson {
    kid: String,
    alg: String,
    typ: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AccessClaims {
    pub iss: String,
    pub sub: String,
    pub aud: String,
    pub exp: String,
    pub nbf: String,
    #[serde(default)]
    pub gid: Option<String>,
    #[serde(default)]
    pub email: Option<String>,
    #[serde(default)]
    pub name: Option<String>,
    pub token_use: String,
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
    audience: String,
    redirect_uri: String,
    http: HttpClient,
    metadata_cache: RwLock<Option<Metadata>>,
    keys_cache: RwLock<Option<(PublicKeySet, Instant)>>,
}

impl BaseIdpClient {
    pub fn new(
        issuer: String,
        client_id: String,
        client_secret: String,
        audience: String,
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
                audience: if audience.is_empty() {
                    DEFAULT_AUDIENCE.to_string()
                } else {
                    audience
                },
                redirect_uri,
                http,
                metadata_cache: RwLock::new(None),
                keys_cache: RwLock::new(None),
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

    pub async fn public_keys(&self) -> Result<PublicKeySet> {
        if let Some((keys, fetched_at)) = self.inner.keys_cache.read().clone() {
            if fetched_at.elapsed() < Duration::from_secs(300) {
                return Ok(keys);
            }
        }
        let metadata = self.metadata().await?;
        let keys: PublicKeySet = self
            .inner
            .http
            .get(&metadata.paseto_public_key_endpoint)
            .send()
            .await
            .context("base-idp public keys fetch")?
            .error_for_status()?
            .json()
            .await?;
        *self.inner.keys_cache.write() = Some((keys.clone(), Instant::now()));
        Ok(keys)
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

    pub async fn verify_access_token(&self, token: &str) -> Result<Principal> {
        let parts: Vec<&str> = token.split('.').collect();
        if parts.len() != 4 || parts[0] != "v4" || parts[1] != "public" {
            return Err(anyhow!("token is not PASETO v4.public"));
        }

        let payload = base64_url_decode(parts[2]).context("decode payload")?;
        let footer_bytes = base64_url_decode(parts[3]).context("decode footer")?;

        if payload.len() <= 64 {
            return Err(anyhow!("payload too short"));
        }

        let footer: FooterJson =
            serde_json::from_slice(&footer_bytes).context("decode footer json")?;
        if footer.alg != "v4.public" || footer.typ != "paseto" || footer.kid.is_empty() {
            return Err(anyhow!("invalid PASETO v4.public footer"));
        }

        let keys = self.public_keys().await?;
        let key_b64 = keys
            .keys
            .iter()
            .find(|k| k.kid == footer.kid && k.alg == "v4.public" && k.crv == "Ed25519")
            .ok_or_else(|| anyhow!("kid {} not found in IdP key set", footer.kid))?;

        let key_bytes = base64_decode_flexible(&key_b64.public_key_base64)
            .context("decode Ed25519 public key")?;
        if key_bytes.len() != 32 {
            return Err(anyhow!("Ed25519 public key size invalid"));
        }
        let mut key_arr = [0u8; 32];
        key_arr.copy_from_slice(&key_bytes);
        let verifying_key =
            VerifyingKey::from_bytes(&key_arr).map_err(|e| anyhow!("parse Ed25519 key: {e}"))?;

        let sig_start = payload.len() - 64;
        let message = &payload[..sig_start];
        let sig_bytes = &payload[sig_start..];
        let mut sig_arr = [0u8; 64];
        sig_arr.copy_from_slice(sig_bytes);
        let signature = ed25519_dalek::Signature::from_bytes(&sig_arr);

        let implicit = DEFAULT_IMPLICIT_ASSERTION.as_bytes();
        let pae = pre_auth_encode(&[PASETO_HEADER, message, &footer_bytes, implicit]);

        verifying_key
            .verify(&pae, &signature)
            .map_err(|e| anyhow!("PASETO signature verification failed: {e}"))?;

        let claims: AccessClaims = serde_json::from_slice(message).context("decode claims json")?;

        if claims.token_use != "access" {
            return Err(anyhow!("token_use must be 'access'"));
        }
        if claims.iss != self.inner.issuer {
            return Err(anyhow!(
                "issuer mismatch: token={} expected={}",
                claims.iss,
                self.inner.issuer
            ));
        }
        if claims.aud != self.inner.audience {
            return Err(anyhow!(
                "audience mismatch: token={} expected={}",
                claims.aud,
                self.inner.audience
            ));
        }

        let now = time::OffsetDateTime::now_utc();
        let exp = time::OffsetDateTime::parse(
            &claims.exp,
            &time::format_description::well_known::Rfc3339,
        )
        .context("parse exp")?;
        if exp <= now - time::Duration::seconds(30) {
            return Err(anyhow!("token expired"));
        }
        let nbf = time::OffsetDateTime::parse(
            &claims.nbf,
            &time::format_description::well_known::Rfc3339,
        )
        .context("parse nbf")?;
        if nbf > now + time::Duration::seconds(30) {
            return Err(anyhow!("token not yet valid"));
        }

        Ok(Principal {
            subject: claims.sub,
            email: claims.email,
            name: claims.name,
        })
    }
}

fn pre_auth_encode(pieces: &[&[u8]]) -> Vec<u8> {
    let mut out = Vec::with_capacity(8 + pieces.iter().map(|p| 8 + p.len()).sum::<usize>());
    out.extend_from_slice(&(pieces.len() as u64).to_le_bytes());
    for piece in pieces {
        out.extend_from_slice(&(piece.len() as u64).to_le_bytes());
        out.extend_from_slice(piece);
    }
    out
}

fn base64_url_decode(value: &str) -> Result<Vec<u8>> {
    base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(value)
        .or_else(|_| base64::engine::general_purpose::URL_SAFE.decode(value))
        .map_err(|e| anyhow!("base64 decode failed: {e}"))
}

fn base64_decode_flexible(value: &str) -> Result<Vec<u8>> {
    use base64::engine::general_purpose::*;
    for engine in [&URL_SAFE_NO_PAD, &URL_SAFE, &STANDARD_NO_PAD, &STANDARD] {
        if let Ok(decoded) = engine.decode(value) {
            return Ok(decoded);
        }
    }
    Err(anyhow!("base64 decode failed for public key"))
}
