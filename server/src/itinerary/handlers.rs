use anyhow::anyhow;
use axum::{
    extract::{Multipart, Path, State},
    response::{Html, IntoResponse, Response},
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

/// Only these listing types carry a narrative itinerary. A `site` is a single
/// place, so a day-by-day plan doesn't apply.
const ITINERARY_TYPES: &[&str] = &["trip", "experience", "safari"];

const MAX_IMAGES_PER_DAY: usize = 3;
const MAX_DAYS: usize = 60;

#[derive(Deserialize)]
pub struct ItineraryDayInput {
    pub day_number: i32,
    pub title: Option<String>,
    pub description: Option<String>,
    #[serde(default)]
    pub image_urls: Vec<String>,
}

#[derive(Deserialize)]
pub struct ReplaceItineraryRequest {
    pub days: Vec<ItineraryDayInput>,
}

/// Confirms the listing exists and (unless admin) belongs to the caller,
/// returning its `listing_type`. Used to gate every operator itinerary op.
async fn require_owned_listing(
    state: &AppState,
    listing_id: Uuid,
    auth: &AuthUser,
) -> AppResult<String> {
    let row = sqlx::query(
        "SELECT operator_id, listing_type::text AS listing_type
         FROM listings WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(listing_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Listing not found".to_string()))?;

    let owner: Uuid = row.try_get("operator_id").map_err(AppError::from)?;
    if auth.role != "admin" && owner != auth.id {
        return Err(AppError::Forbidden("Not your listing".to_string()));
    }
    Ok(row.try_get::<String, _>("listing_type").unwrap_or_default())
}

async fn fetch_days(state: &AppState, listing_id: Uuid) -> AppResult<Vec<Value>> {
    let rows = sqlx::query(
        "SELECT id, day_number, title, description, image_urls
         FROM itinerary_days WHERE listing_id = $1 ORDER BY day_number",
    )
    .bind(listing_id)
    .fetch_all(&state.db)
    .await?;

    Ok(rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "day_number": r.try_get::<i32, _>("day_number").unwrap_or(0),
                "title": r.try_get::<Option<String>, _>("title").unwrap_or_default(),
                "description": r.try_get::<Option<String>, _>("description").unwrap_or_default(),
                "image_urls": r
                    .try_get::<Vec<String>, _>("image_urls")
                    .unwrap_or_default(),
            })
        })
        .collect())
}

fn share_url(state: &AppState, token: &str) -> String {
    format!(
        "{}/i/{}",
        state.config.public.share_base_url.trim_end_matches('/'),
        token
    )
}

/// GET /api/v1/operators/listings/:id/itinerary
pub async fn get_operator_itinerary(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(listing_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;
    let listing_type = require_owned_listing(&state, listing_id, &auth).await?;

    let token: Option<String> =
        sqlx::query_scalar("SELECT public_itinerary_token FROM listings WHERE id = $1")
            .bind(listing_id)
            .fetch_one(&state.db)
            .await?;

    let days = fetch_days(&state, listing_id).await?;
    Ok(Json(json!({
        "listing_id": listing_id,
        "listing_type": listing_type,
        "supports_itinerary": ITINERARY_TYPES.contains(&listing_type.as_str()),
        "days": days,
        "is_shared": token.is_some(),
        "share_url": token.as_deref().map(|t| share_url(&state, t)),
    })))
}

/// PUT /api/v1/operators/listings/:id/itinerary — full replace of all days.
///
/// Replace (delete-all + reinsert in one transaction) rather than per-row
/// diffing: the day-builder edits the whole list at once, and reordering/
/// deleting days is common, so a wholesale replace is simpler and avoids
/// stale rows. `ON DELETE CASCADE` from the parent listing still applies.
pub async fn replace_itinerary(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(listing_id): Path<Uuid>,
    Json(body): Json<ReplaceItineraryRequest>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;
    let listing_type = require_owned_listing(&state, listing_id, &auth).await?;
    if !ITINERARY_TYPES.contains(&listing_type.as_str()) {
        return Err(AppError::BadRequest(format!(
            "Itineraries are only supported for {} listings",
            ITINERARY_TYPES.join(", ")
        )));
    }
    if body.days.len() > MAX_DAYS {
        return Err(AppError::BadRequest(format!(
            "An itinerary can have at most {MAX_DAYS} days"
        )));
    }
    for day in &body.days {
        if day.image_urls.len() > MAX_IMAGES_PER_DAY {
            return Err(AppError::BadRequest(format!(
                "Each day can have at most {MAX_IMAGES_PER_DAY} images"
            )));
        }
    }

    let mut tx = state.db.begin().await?;
    sqlx::query("DELETE FROM itinerary_days WHERE listing_id = $1")
        .bind(listing_id)
        .execute(&mut *tx)
        .await?;

    for day in &body.days {
        sqlx::query(
            "INSERT INTO itinerary_days (listing_id, day_number, title, description, image_urls)
             VALUES ($1, $2, $3, $4, $5)",
        )
        .bind(listing_id)
        .bind(day.day_number)
        .bind(day.title.as_deref())
        .bind(day.description.as_deref())
        .bind(&day.image_urls)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;

    let days = fetch_days(&state, listing_id).await?;
    Ok(Json(json!({ "days": days })))
}

/// POST /api/v1/operators/listings/:id/itinerary/image — upload one day image.
/// Returns a permanent public URL the client then stores in a day's
/// `image_urls` on the next `replace_itinerary` call.
pub async fn upload_itinerary_image(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(listing_id): Path<Uuid>,
    mut multipart: Multipart,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;
    require_owned_listing(&state, listing_id, &auth).await?;

    let gcs = state
        .gcs
        .as_ref()
        .ok_or_else(|| AppError::BadRequest("Image uploads are not configured".to_string()))?;

    let mut file_bytes: Option<Vec<u8>> = None;
    let mut content_type: Option<String> = None;
    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::BadRequest(format!("multipart error: {e}")))?
    {
        if field.name() == Some("file") {
            content_type = Some(
                field
                    .content_type()
                    .unwrap_or("application/octet-stream")
                    .to_string(),
            );
            file_bytes = Some(
                field
                    .bytes()
                    .await
                    .map_err(|e| AppError::BadRequest(format!("failed to read file: {e}")))?
                    .to_vec(),
            );
        }
    }

    let bytes = file_bytes.ok_or_else(|| AppError::BadRequest("missing file field".to_string()))?;
    let ct = content_type.unwrap_or_else(|| "image/jpeg".to_string());
    if !ct.starts_with("image/") {
        return Err(AppError::BadRequest("file must be an image".to_string()));
    }
    let ext = if ct.contains("png") {
        "png"
    } else if ct.contains("webp") {
        "webp"
    } else {
        "jpg"
    };
    let object_name = format!("itineraries/{listing_id}/{}.{ext}", Uuid::new_v4().simple());

    let url = gcs
        .upload_public(&object_name, &ct, bytes)
        .await
        .map_err(|e| AppError::Internal(anyhow!("{e}")))?;

    Ok(Json(json!({ "url": url })))
}

/// POST /api/v1/operators/listings/:id/itinerary/share — mint (or return the
/// existing) public share token.
pub async fn share_itinerary(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(listing_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;
    require_owned_listing(&state, listing_id, &auth).await?;

    // Mint only if not already shared, so the link is stable across taps.
    let token: String = sqlx::query_scalar(
        "UPDATE listings
            SET public_itinerary_token = COALESCE(public_itinerary_token, $2),
                updated_at = now()
          WHERE id = $1
      RETURNING public_itinerary_token",
    )
    .bind(listing_id)
    .bind(Uuid::new_v4().simple().to_string())
    .fetch_one(&state.db)
    .await?;

    Ok(Json(json!({
        "is_shared": true,
        "token": token,
        "share_url": share_url(&state, &token),
    })))
}

/// DELETE /api/v1/operators/listings/:id/itinerary/share — revoke sharing.
pub async fn unshare_itinerary(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(listing_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;
    require_owned_listing(&state, listing_id, &auth).await?;

    sqlx::query(
        "UPDATE listings SET public_itinerary_token = NULL, updated_at = now() WHERE id = $1",
    )
    .bind(listing_id)
    .execute(&state.db)
    .await?;

    Ok(Json(json!({ "is_shared": false })))
}

/// Shared lookup for both the public JSON and HTML endpoints.
async fn public_itinerary(state: &AppState, token: &str) -> AppResult<Value> {
    let row = sqlx::query(
        r#"SELECT l.id, l.title, l.description, l.listing_type::text AS listing_type,
                  l.image_urls, l.base_price, l.currency,
                  u.full_name AS operator_name,
                  d.name AS destination_name, d.country AS destination_country
           FROM listings l
           JOIN users u ON u.id = l.operator_id
           JOIN destinations d ON d.id = l.destination_id
           WHERE l.public_itinerary_token = $1 AND l.deleted_at IS NULL"#,
    )
    .bind(token)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Itinerary not found".to_string()))?;

    let listing_id: Uuid = row.try_get("id").map_err(AppError::from)?;
    let days = fetch_days(state, listing_id).await?;

    Ok(json!({
        "title": row.try_get::<String, _>("title").unwrap_or_default(),
        "description": row.try_get::<Option<String>, _>("description").unwrap_or_default(),
        "listing_type": row.try_get::<String, _>("listing_type").unwrap_or_default(),
        "hero_image": row
            .try_get::<Option<Vec<String>>, _>("image_urls")
            .unwrap_or_default()
            .unwrap_or_default()
            .into_iter()
            .next(),
        "operator_name": row.try_get::<String, _>("operator_name").unwrap_or_default(),
        "destination_name": row.try_get::<String, _>("destination_name").unwrap_or_default(),
        "destination_country": row.try_get::<String, _>("destination_country").unwrap_or_default(),
        "days": days,
    }))
}

/// GET /api/v1/public/itineraries/:token — public JSON (no auth). This is the
/// durable contract the future client web app will render from.
pub async fn get_public_itinerary(
    State(state): State<AppState>,
    Path(token): Path<String>,
) -> AppResult<Json<Value>> {
    Ok(Json(public_itinerary(&state, &token).await?))
}

/// GET /i/:token — interim server-rendered share page (no auth). A minimal
/// self-contained HTML page so a shared link works today; superseded by the
/// dedicated client web app later (repoint PUBLIC_SHARE_BASE_URL there).
pub async fn public_itinerary_page(
    State(state): State<AppState>,
    Path(token): Path<String>,
) -> Response {
    match public_itinerary(&state, &token).await {
        Ok(data) => Html(render_itinerary_html(&data)).into_response(),
        Err(AppError::NotFound(_)) => (
            axum::http::StatusCode::NOT_FOUND,
            Html(render_not_found_html()),
        )
            .into_response(),
        Err(e) => e.into_response(),
    }
}

fn esc(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

fn render_itinerary_html(data: &Value) -> String {
    let title = esc(data["title"].as_str().unwrap_or("Itinerary"));
    let description = data["description"].as_str().unwrap_or("");
    let operator = esc(data["operator_name"].as_str().unwrap_or(""));
    let destination = esc(data["destination_name"].as_str().unwrap_or(""));
    let listing_type = esc(data["listing_type"].as_str().unwrap_or(""));
    let hero = data["hero_image"].as_str().unwrap_or("");

    let mut days_html = String::new();
    if let Some(days) = data["days"].as_array() {
        for day in days {
            let n = day["day_number"].as_i64().unwrap_or(0);
            let d_title = day["title"].as_str().filter(|s| !s.is_empty());
            let d_desc = day["description"].as_str().unwrap_or("");
            let heading = match d_title {
                Some(t) => format!("Day {n} · {}", esc(t)),
                None => format!("Day {n}"),
            };
            let mut imgs = String::new();
            if let Some(urls) = day["image_urls"].as_array() {
                for u in urls {
                    if let Some(u) = u.as_str() {
                        imgs.push_str(&format!(
                            "<img loading=\"lazy\" src=\"{}\" alt=\"\">",
                            esc(u)
                        ));
                    }
                }
            }
            let imgs_block = if imgs.is_empty() {
                String::new()
            } else {
                format!("<div class=\"imgs\">{imgs}</div>")
            };
            days_html.push_str(&format!(
                "<section class=\"day\"><h2>{heading}</h2><p>{}</p>{imgs_block}</section>",
                esc(d_desc)
            ));
        }
    }
    if days_html.is_empty() {
        days_html = "<p class=\"muted\">No days added yet.</p>".to_string();
    }

    let hero_block = if hero.is_empty() {
        String::new()
    } else {
        format!(
            "<div class=\"hero\" style=\"background-image:url('{}')\"></div>",
            esc(hero)
        )
    };
    let meta = [operator, destination, listing_type]
        .into_iter()
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join(" · ");

    format!(
        r#"<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — Itinerary</title>
<meta property="og:title" content="{title}">
<style>
:root{{color-scheme:light}}
*{{box-sizing:border-box}}
body{{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#0A1320;background:#F7F7F8}}
.wrap{{max-width:680px;margin:0 auto;padding:24px}}
.hero{{height:220px;border-radius:24px;background-size:cover;background-position:center;margin-bottom:20px}}
h1{{font-size:30px;letter-spacing:-.5px;margin:0 0 6px}}
.meta{{color:#6B7280;font-size:14px;margin:0 0 8px}}
.lead{{color:#374151;font-size:16px;line-height:1.5;margin:0 0 28px}}
.day{{background:#fff;border-radius:20px;padding:20px;margin-bottom:16px}}
.day h2{{font-size:18px;margin:0 0 8px}}
.day p{{color:#374151;line-height:1.55;margin:0;white-space:pre-wrap}}
.imgs{{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:8px;margin-top:14px}}
.imgs img{{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:12px;display:block}}
.muted{{color:#9CA3AF}}
footer{{color:#9CA3AF;font-size:13px;text-align:center;margin:32px 0}}
</style></head><body><div class="wrap">
{hero_block}
<h1>{title}</h1>
<p class="meta">{meta}</p>
<p class="lead">{lead}</p>
{days_html}
<footer>Shared via Twende</footer>
</div></body></html>"#,
        lead = esc(description),
    )
}

fn render_not_found_html() -> String {
    r#"<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Itinerary not found</title>
<style>body{margin:0;height:100vh;display:grid;place-items:center;font-family:-apple-system,sans-serif;color:#374151;background:#F7F7F8}</style>
</head><body><div><h1>This itinerary isn't available.</h1><p>The link may have been unshared or is incorrect.</p></div></body></html>"#.to_string()
}
