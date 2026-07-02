use anyhow::anyhow;
use axum::{
    extract::{Multipart, Path, Query, State},
    Json,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::FromRow;
use uuid::Uuid;

use crate::{
    app::AppState,
    auth::AuthUser,
    compliance,
    error::{AppError, AppResult},
    storage::GcsClient,
};

/// Object paths (not public URLs) are stored in the DB. Sign them into
/// time-limited readable links, since the bucket is private.
const DOCUMENT_URL_TTL_SECS: i64 = 900;

fn signed_or_none(
    gcs: Option<&std::sync::Arc<GcsClient>>,
    object_path: Option<String>,
) -> Option<String> {
    let path = object_path?;
    let client = gcs?;
    client.signed_url(&path, DOCUMENT_URL_TTL_SECS).ok()
}

#[derive(Deserialize)]
pub struct OperatorProfileUpdate {
    pub business_name: Option<String>,
    pub business_description: Option<String>,
    pub phone: Option<String>,
    pub website: Option<String>,
    pub address: Option<String>,
    pub business_registration_number: Option<String>,
    // Location
    pub country: Option<String>,
    pub city: Option<String>,
    pub region: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    // Branding
    pub logo_url: Option<String>,
    // Fleet
    pub fleet_size: Option<i32>,
    pub fleet_types: Option<Vec<String>>,
    // Social
    pub facebook_url: Option<String>,
    pub instagram_url: Option<String>,
    pub whatsapp_number: Option<String>,
    // Operations
    pub languages: Option<Vec<String>>,
    pub years_in_operation: Option<i32>,
    pub business_email: Option<String>,
    // Payout
    pub mpesa_number: Option<String>,
    pub bank_account_number: Option<String>,
    pub bank_name: Option<String>,
    // Emergency contact
    pub emergency_contact_name: Option<String>,
    pub emergency_contact_phone: Option<String>,
    // Compliance (KYB)
    /// Which tourism activities this operator offers: safari, car_hire,
    /// trekking, water_sports, hotel_lodge. Drives required documents.
    pub service_categories: Option<Vec<String>>,
    /// Business registration authority: 'brela' (mainland) or 'bpra' (Zanzibar).
    pub registration_authority: Option<String>,
    pub tin_number: Option<String>,
    pub tourism_license_number: Option<String>,
}

/// Computes the operator's document-completion percentage, required-document
/// checklist, and listing quota. Shared by `get_my_profile` and the
/// dedicated `/operators/me/compliance` endpoint.
pub(crate) async fn compute_compliance(state: &AppState, operator_id: Uuid) -> AppResult<Value> {
    use sqlx::Row;

    let row = sqlx::query(
        r#"SELECT service_categories, country, region, city,
                  certificate_of_incorporation_url, tin_certificate_url,
                  tourism_license_url, vehicle_registration_url,
                  vehicle_insurance_url, guide_license_url
           FROM operator_profiles WHERE user_id = $1"#,
    )
    .bind(operator_id)
    .fetch_optional(&state.db)
    .await?;

    let categories: Vec<String> = row
        .as_ref()
        .and_then(|r| {
            r.try_get::<Option<Vec<String>>, _>("service_categories")
                .ok()
                .flatten()
        })
        .unwrap_or_default();
    let country = row
        .as_ref()
        .and_then(|r| r.try_get::<Option<String>, _>("country").ok().flatten());
    let region = row
        .as_ref()
        .and_then(|r| r.try_get::<Option<String>, _>("region").ok().flatten());
    let city = row
        .as_ref()
        .and_then(|r| r.try_get::<Option<String>, _>("city").ok().flatten());
    let is_zanzibar =
        compliance::is_zanzibar_location(country.as_deref(), region.as_deref(), city.as_deref());

    let uploaded = compliance::UploadedDocs {
        certificate_of_incorporation: row
            .as_ref()
            .and_then(|r| {
                r.try_get::<Option<String>, _>("certificate_of_incorporation_url")
                    .ok()
                    .flatten()
            })
            .is_some(),
        tin_certificate: row
            .as_ref()
            .and_then(|r| {
                r.try_get::<Option<String>, _>("tin_certificate_url")
                    .ok()
                    .flatten()
            })
            .is_some(),
        tourism_license: row
            .as_ref()
            .and_then(|r| {
                r.try_get::<Option<String>, _>("tourism_license_url")
                    .ok()
                    .flatten()
            })
            .is_some(),
        vehicle_registration: row
            .as_ref()
            .and_then(|r| {
                r.try_get::<Option<String>, _>("vehicle_registration_url")
                    .ok()
                    .flatten()
            })
            .is_some(),
        vehicle_insurance: row
            .as_ref()
            .and_then(|r| {
                r.try_get::<Option<String>, _>("vehicle_insurance_url")
                    .ok()
                    .flatten()
            })
            .is_some(),
        guide_license: row
            .as_ref()
            .and_then(|r| {
                r.try_get::<Option<String>, _>("guide_license_url")
                    .ok()
                    .flatten()
            })
            .is_some(),
    };

    let required = compliance::required_documents(&categories, is_zanzibar);
    let percent = compliance::completion_percent(&required, &uploaded);
    let quota = compliance::listing_quota(percent);

    let listings_used: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM listings WHERE operator_id = $1 AND deleted_at IS NULL",
    )
    .bind(operator_id)
    .fetch_one(&state.db)
    .await?;

    let required_json: Vec<Value> = required
        .iter()
        .map(|d| {
            let label = if d.key == "tourism_license" {
                compliance::tourism_license_label(&categories, is_zanzibar)
            } else {
                d.label
            };
            json!({ "key": d.key, "label": label, "uploaded": uploaded.has(d.key) })
        })
        .collect();

    Ok(json!({
        "service_categories": categories,
        "is_zanzibar": is_zanzibar,
        "required_documents": required_json,
        "completion_percent": (percent * 10.0).round() / 10.0,
        "listing_quota": quota,
        "listings_used": listings_used,
        "listings_remaining": quota.map(|q| (q - listings_used).max(0)),
    }))
}

pub async fn get_my_compliance(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;
    Ok(Json(compute_compliance(&state, auth.id).await?))
}

#[derive(Deserialize)]
pub struct PaginationParams {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(FromRow, Serialize)]
struct OperatorRow {
    user_id: Uuid,
    email: String,
    full_name: String,
    phone: Option<String>,
    business_name: Option<String>,
    business_description: Option<String>,
    website: Option<String>,
    address: Option<String>,
    business_registration_number: Option<String>,
    verification_status: String,
    verified_at: Option<String>,
}

pub async fn get_my_profile(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let row = sqlx::query(
        r#"SELECT u.id as user_id, u.email, u.full_name, u.national_id_number,
                  op.phone, op.business_name, op.business_description, op.website, op.address,
                  op.business_registration_number, op.registration_authority,
                  op.tin_number, op.tourism_license_number,
                  op.service_categories,
                  op.country, op.city, op.region,
                  op.latitude::text as latitude, op.longitude::text as longitude,
                  op.logo_url, op.fleet_size, op.fleet_types,
                  op.facebook_url, op.instagram_url, op.whatsapp_number,
                  op.languages, op.years_in_operation, op.business_email,
                  op.mpesa_number, op.bank_name,
                  op.emergency_contact_name, op.emergency_contact_phone,
                  op.certificate_of_incorporation_url, op.tin_certificate_url,
                  op.tourism_license_url, op.vehicle_registration_url,
                  op.vehicle_insurance_url, op.guide_license_url,
                  COALESCE(op.verification_status::text, 'pending') as verification_status,
                  op.verified_at::text as verified_at
           FROM users u
           LEFT JOIN operator_profiles op ON op.user_id = u.id
           WHERE u.id = $1 AND u.deleted_at IS NULL"#,
    )
    .bind(auth.id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Operator not found".to_string()))?;

    use sqlx::Row;
    let gcs = state.gcs.as_ref();
    let compliance = compute_compliance(&state, auth.id).await?;
    Ok(Json(json!({
        "user_id": row.try_get::<Uuid, _>("user_id").ok(),
        "email": row.try_get::<String, _>("email").unwrap_or_default(),
        "full_name": row.try_get::<String, _>("full_name").unwrap_or_default(),
        "national_id_number": row.try_get::<Option<String>, _>("national_id_number").ok().flatten(),
        "phone": row.try_get::<Option<String>, _>("phone").ok().flatten(),
        "business_name": row.try_get::<Option<String>, _>("business_name").ok().flatten(),
        "business_description": row.try_get::<Option<String>, _>("business_description").ok().flatten(),
        "website": row.try_get::<Option<String>, _>("website").ok().flatten(),
        "address": row.try_get::<Option<String>, _>("address").ok().flatten(),
        "business_registration_number": row.try_get::<Option<String>, _>("business_registration_number").ok().flatten(),
        "registration_authority": row.try_get::<Option<String>, _>("registration_authority").ok().flatten(),
        "tin_number": row.try_get::<Option<String>, _>("tin_number").ok().flatten(),
        "tourism_license_number": row.try_get::<Option<String>, _>("tourism_license_number").ok().flatten(),
        "service_categories": row.try_get::<Option<Vec<String>>, _>("service_categories").ok().flatten(),
        // Location
        "country": row.try_get::<Option<String>, _>("country").ok().flatten(),
        "city": row.try_get::<Option<String>, _>("city").ok().flatten(),
        "region": row.try_get::<Option<String>, _>("region").ok().flatten(),
        "latitude": row.try_get::<Option<String>, _>("latitude").ok().flatten(),
        "longitude": row.try_get::<Option<String>, _>("longitude").ok().flatten(),
        // Branding
        "logo_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("logo_url").ok().flatten()),
        // Fleet
        "fleet_size": row.try_get::<Option<i32>, _>("fleet_size").ok().flatten(),
        "fleet_types": row.try_get::<Option<Vec<String>>, _>("fleet_types").ok().flatten(),
        // Social
        "facebook_url": row.try_get::<Option<String>, _>("facebook_url").ok().flatten(),
        "instagram_url": row.try_get::<Option<String>, _>("instagram_url").ok().flatten(),
        "whatsapp_number": row.try_get::<Option<String>, _>("whatsapp_number").ok().flatten(),
        // Operations
        "languages": row.try_get::<Option<Vec<String>>, _>("languages").ok().flatten(),
        "years_in_operation": row.try_get::<Option<i32>, _>("years_in_operation").ok().flatten(),
        "business_email": row.try_get::<Option<String>, _>("business_email").ok().flatten(),
        // Payout
        "mpesa_number": row.try_get::<Option<String>, _>("mpesa_number").ok().flatten(),
        "bank_name": row.try_get::<Option<String>, _>("bank_name").ok().flatten(),
        // Emergency
        "emergency_contact_name": row.try_get::<Option<String>, _>("emergency_contact_name").ok().flatten(),
        "emergency_contact_phone": row.try_get::<Option<String>, _>("emergency_contact_phone").ok().flatten(),
        // Documents (signed, time-limited URLs — object paths are stored, not raw URLs)
        "certificate_of_incorporation_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("certificate_of_incorporation_url").ok().flatten()),
        "tin_certificate_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("tin_certificate_url").ok().flatten()),
        "tourism_license_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("tourism_license_url").ok().flatten()),
        "vehicle_registration_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("vehicle_registration_url").ok().flatten()),
        "vehicle_insurance_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("vehicle_insurance_url").ok().flatten()),
        "guide_license_url": signed_or_none(gcs, row.try_get::<Option<String>, _>("guide_license_url").ok().flatten()),
        // Verification
        "verification_status": row.try_get::<String, _>("verification_status").unwrap_or_else(|_| "pending".to_string()),
        "verified_at": row.try_get::<Option<String>, _>("verified_at").ok().flatten(),
        "compliance": compliance
    })))
}

pub async fn update_my_profile(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<OperatorProfileUpdate>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    sqlx::query(
        r#"INSERT INTO operator_profiles (
             user_id, business_name, business_description, phone, website, address,
             business_registration_number,
             country, city, region, latitude, longitude,
             logo_url, fleet_size, fleet_types,
             facebook_url, instagram_url, whatsapp_number,
             languages, years_in_operation, business_email,
             mpesa_number, bank_account_number, bank_name,
             emergency_contact_name, emergency_contact_phone,
             service_categories, registration_authority, tin_number, tourism_license_number
           ) VALUES (
             $1, $2, $3, $4, $5, $6, $7,
             $8, $9, $10, $11, $12,
             $13, $14, $15,
             $16, $17, $18,
             $19, $20, $21,
             $22, $23, $24,
             $25, $26,
             $27, $28, $29, $30
           )
           ON CONFLICT (user_id) DO UPDATE SET
             business_name               = COALESCE($2,  operator_profiles.business_name),
             business_description        = COALESCE($3,  operator_profiles.business_description),
             phone                       = COALESCE($4,  operator_profiles.phone),
             website                     = COALESCE($5,  operator_profiles.website),
             address                     = COALESCE($6,  operator_profiles.address),
             business_registration_number = COALESCE($7, operator_profiles.business_registration_number),
             country                     = COALESCE($8,  operator_profiles.country),
             city                        = COALESCE($9,  operator_profiles.city),
             region                      = COALESCE($10, operator_profiles.region),
             latitude                    = COALESCE($11, operator_profiles.latitude),
             longitude                   = COALESCE($12, operator_profiles.longitude),
             logo_url                    = COALESCE($13, operator_profiles.logo_url),
             fleet_size                  = COALESCE($14, operator_profiles.fleet_size),
             fleet_types                 = COALESCE($15, operator_profiles.fleet_types),
             facebook_url                = COALESCE($16, operator_profiles.facebook_url),
             instagram_url               = COALESCE($17, operator_profiles.instagram_url),
             whatsapp_number             = COALESCE($18, operator_profiles.whatsapp_number),
             languages                   = COALESCE($19, operator_profiles.languages),
             years_in_operation          = COALESCE($20, operator_profiles.years_in_operation),
             business_email              = COALESCE($21, operator_profiles.business_email),
             mpesa_number                = COALESCE($22, operator_profiles.mpesa_number),
             bank_account_number         = COALESCE($23, operator_profiles.bank_account_number),
             bank_name                   = COALESCE($24, operator_profiles.bank_name),
             emergency_contact_name      = COALESCE($25, operator_profiles.emergency_contact_name),
             emergency_contact_phone     = COALESCE($26, operator_profiles.emergency_contact_phone),
             service_categories          = COALESCE($27, operator_profiles.service_categories),
             registration_authority      = COALESCE($28, operator_profiles.registration_authority),
             tin_number                  = COALESCE($29, operator_profiles.tin_number),
             tourism_license_number      = COALESCE($30, operator_profiles.tourism_license_number),
             updated_at = now()"#,
    )
    .bind(auth.id)
    .bind(req.business_name.as_deref())
    .bind(req.business_description.as_deref())
    .bind(req.phone.as_deref())
    .bind(req.website.as_deref())
    .bind(req.address.as_deref())
    .bind(req.business_registration_number.as_deref())
    .bind(req.country.as_deref())
    .bind(req.city.as_deref())
    .bind(req.region.as_deref())
    .bind(req.latitude)
    .bind(req.longitude)
    .bind(req.logo_url.as_deref())
    .bind(req.fleet_size)
    .bind(req.fleet_types.as_deref())
    .bind(req.facebook_url.as_deref())
    .bind(req.instagram_url.as_deref())
    .bind(req.whatsapp_number.as_deref())
    .bind(req.languages.as_deref())
    .bind(req.years_in_operation)
    .bind(req.business_email.as_deref())
    .bind(req.mpesa_number.as_deref())
    .bind(req.bank_account_number.as_deref())
    .bind(req.bank_name.as_deref())
    .bind(req.emergency_contact_name.as_deref())
    .bind(req.emergency_contact_phone.as_deref())
    .bind(req.service_categories.as_deref())
    .bind(req.registration_authority.as_deref())
    .bind(req.tin_number.as_deref())
    .bind(req.tourism_license_number.as_deref())
    .execute(&state.db)
    .await?;

    get_my_profile(State(state), auth).await
}

#[derive(Deserialize)]
pub struct IdentityUpdate {
    pub national_id_number: Option<String>,
    pub phone: Option<String>,
}

/// PATCH /api/v1/operators/me/identity
/// Personal identity capture (NIN + phone) — distinct from the business's
/// public contact phone stored on operator_profiles.
pub async fn update_my_identity(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<IdentityUpdate>,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    sqlx::query(
        r#"UPDATE users SET
             national_id_number = COALESCE($2, national_id_number),
             phone = COALESCE($3, phone),
             updated_at = now()
           WHERE id = $1"#,
    )
    .bind(auth.id)
    .bind(req.national_id_number.as_deref())
    .bind(req.phone.as_deref())
    .execute(&state.db)
    .await?;

    get_my_profile(State(state), auth).await
}

/// POST /api/v1/operators/me/documents
/// Accepts multipart/form-data with fields:
///   - `document_type`: certificate_of_incorporation | tin_certificate |
///     tourism_license | vehicle_registration | vehicle_insurance |
///     guide_license | logo
///   - `file`: the PDF (or image)
pub async fn upload_document(
    State(state): State<AppState>,
    auth: AuthUser,
    mut multipart: Multipart,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let gcs = state
        .gcs
        .as_ref()
        .ok_or_else(|| AppError::BadRequest("Document uploads are not configured".to_string()))?;

    let mut document_type: Option<String> = None;
    let mut file_bytes: Option<Vec<u8>> = None;
    let mut content_type: Option<String> = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::BadRequest(format!("multipart error: {e}")))?
    {
        let name = field.name().unwrap_or("").to_string();
        match name.as_str() {
            "document_type" => {
                document_type = Some(field.text().await.map_err(|e| {
                    AppError::BadRequest(format!("failed to read document_type: {e}"))
                })?);
            }
            "file" => {
                let ct = field
                    .content_type()
                    .unwrap_or("application/octet-stream")
                    .to_string();
                content_type = Some(ct);
                file_bytes = Some(
                    field
                        .bytes()
                        .await
                        .map_err(|e| AppError::BadRequest(format!("failed to read file: {e}")))?
                        .to_vec(),
                );
            }
            _ => {}
        }
    }

    let doc_type = document_type
        .ok_or_else(|| AppError::BadRequest("missing document_type field".to_string()))?;
    let bytes = file_bytes.ok_or_else(|| AppError::BadRequest("missing file field".to_string()))?;
    let ct = content_type.unwrap_or_else(|| "application/octet-stream".to_string());

    const VALID_TYPES: &[&str] = &[
        "certificate_of_incorporation",
        "tin_certificate",
        "tourism_license",
        "vehicle_registration",
        "vehicle_insurance",
        "guide_license",
        "logo",
    ];
    if !VALID_TYPES.contains(&doc_type.as_str()) {
        return Err(AppError::BadRequest(format!(
            "document_type must be one of: {}",
            VALID_TYPES.join(", ")
        )));
    }

    let ext = if ct.contains("pdf") {
        "pdf"
    } else if ct.contains("png") {
        "png"
    } else {
        "jpg"
    };
    let object_name = format!("operators/{}/{}.{}", auth.id, doc_type, ext);

    let object_path = gcs
        .upload(&object_name, &ct, bytes)
        .await
        .map_err(|e| AppError::Internal(anyhow!("{e}")))?;

    let db_column = match doc_type.as_str() {
        "certificate_of_incorporation" => "certificate_of_incorporation_url",
        "tin_certificate" => "tin_certificate_url",
        "tourism_license" => "tourism_license_url",
        "vehicle_registration" => "vehicle_registration_url",
        "vehicle_insurance" => "vehicle_insurance_url",
        "guide_license" => "guide_license_url",
        "logo" => "logo_url",
        _ => unreachable!(),
    };

    sqlx::query(&format!(
        "INSERT INTO operator_profiles (user_id, {db_column}) VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE SET {db_column} = $2, updated_at = now()"
    ))
    .bind(auth.id)
    .bind(&object_path)
    .execute(&state.db)
    .await?;

    let signed_url = gcs
        .signed_url(&object_path, DOCUMENT_URL_TTL_SECS)
        .map_err(|e| AppError::Internal(e))?;

    Ok(Json(json!({
        "document_type": doc_type,
        "url": signed_url
    })))
}

pub async fn admin_list_operators(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(params): Query<PaginationParams>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let limit = params.limit.unwrap_or(20).min(100);
    let offset = params.offset.unwrap_or(0);

    let rows = sqlx::query(
        r#"SELECT u.id, u.email, u.full_name, u.phone, u.created_at::text as created_at,
                  op.business_name, op.business_description,
                  op.city, op.country,
                  COALESCE(op.verification_status::text, 'pending') as verification_status,
                  op.verified_at::text as verified_at
           FROM users u
           LEFT JOIN operator_profiles op ON op.user_id = u.id
           WHERE u.role = 'operator' AND u.deleted_at IS NULL
           ORDER BY u.created_at DESC
           LIMIT $1 OFFSET $2"#,
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db)
    .await?;

    let total: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM users WHERE role = 'operator' AND deleted_at IS NULL",
    )
    .fetch_one(&state.db)
    .await?;

    use sqlx::Row;
    let operators: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "id": r.try_get::<Uuid, _>("id").ok(),
                "email": r.try_get::<String, _>("email").unwrap_or_default(),
                "full_name": r.try_get::<String, _>("full_name").unwrap_or_default(),
                "phone": r.try_get::<Option<String>, _>("phone").ok().flatten(),
                "business_name": r.try_get::<Option<String>, _>("business_name").ok().flatten(),
                "city": r.try_get::<Option<String>, _>("city").ok().flatten(),
                "country": r.try_get::<Option<String>, _>("country").ok().flatten(),
                "verification_status": r.try_get::<String, _>("verification_status").unwrap_or_else(|_| "pending".into()),
                "verified_at": r.try_get::<Option<String>, _>("verified_at").ok().flatten(),
                "created_at": r.try_get::<String, _>("created_at").unwrap_or_default()
            })
        })
        .collect();

    Ok(Json(
        json!({ "data": operators, "total": total, "limit": limit, "offset": offset }),
    ))
}

pub async fn admin_get_operator(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(operator_id): Path<Uuid>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    let row = sqlx::query(
        r#"SELECT u.id, u.email, u.full_name, u.phone, u.national_id_number, u.created_at::text as created_at,
                  op.business_name, op.business_description, op.website, op.address,
                  op.business_registration_number, op.registration_authority,
                  op.tin_number, op.tourism_license_number, op.service_categories,
                  op.country, op.city, op.region,
                  op.latitude::text as latitude, op.longitude::text as longitude,
                  op.logo_url, op.fleet_size, op.fleet_types,
                  op.facebook_url, op.instagram_url, op.whatsapp_number,
                  op.languages, op.years_in_operation, op.business_email,
                  op.mpesa_number, op.bank_name,
                  op.emergency_contact_name, op.emergency_contact_phone,
                  op.certificate_of_incorporation_url, op.tin_certificate_url,
                  op.tourism_license_url, op.vehicle_registration_url,
                  op.vehicle_insurance_url, op.guide_license_url,
                  COALESCE(op.verification_status::text, 'pending') as verification_status,
                  op.verified_at::text as verified_at, op.verified_by, op.rejection_reason
           FROM users u
           LEFT JOIN operator_profiles op ON op.user_id = u.id
           WHERE u.id = $1 AND u.role = 'operator' AND u.deleted_at IS NULL"#,
    )
    .bind(operator_id)
    .fetch_optional(&state.db)
    .await?
    .ok_or_else(|| AppError::NotFound("Operator not found".to_string()))?;

    use sqlx::Row;
    let gcs = state.gcs.as_ref();
    let sign_admin = |path: Option<String>| -> Option<String> {
        let path = path?;
        let client = gcs?;
        client.signed_url(&path, 3600).ok()
    };
    let compliance = compute_compliance(&state, operator_id).await?;
    Ok(Json(json!({
        "id": row.try_get::<Uuid, _>("id").ok(),
        "email": row.try_get::<String, _>("email").unwrap_or_default(),
        "full_name": row.try_get::<String, _>("full_name").unwrap_or_default(),
        "phone": row.try_get::<Option<String>, _>("phone").ok().flatten(),
        "national_id_number": row.try_get::<Option<String>, _>("national_id_number").ok().flatten(),
        "business_name": row.try_get::<Option<String>, _>("business_name").ok().flatten(),
        "business_description": row.try_get::<Option<String>, _>("business_description").ok().flatten(),
        "website": row.try_get::<Option<String>, _>("website").ok().flatten(),
        "address": row.try_get::<Option<String>, _>("address").ok().flatten(),
        "business_registration_number": row.try_get::<Option<String>, _>("business_registration_number").ok().flatten(),
        "registration_authority": row.try_get::<Option<String>, _>("registration_authority").ok().flatten(),
        "tin_number": row.try_get::<Option<String>, _>("tin_number").ok().flatten(),
        "tourism_license_number": row.try_get::<Option<String>, _>("tourism_license_number").ok().flatten(),
        "service_categories": row.try_get::<Option<Vec<String>>, _>("service_categories").ok().flatten(),
        "country": row.try_get::<Option<String>, _>("country").ok().flatten(),
        "city": row.try_get::<Option<String>, _>("city").ok().flatten(),
        "region": row.try_get::<Option<String>, _>("region").ok().flatten(),
        "latitude": row.try_get::<Option<String>, _>("latitude").ok().flatten(),
        "longitude": row.try_get::<Option<String>, _>("longitude").ok().flatten(),
        "logo_url": sign_admin(row.try_get::<Option<String>, _>("logo_url").ok().flatten()),
        "fleet_size": row.try_get::<Option<i32>, _>("fleet_size").ok().flatten(),
        "fleet_types": row.try_get::<Option<Vec<String>>, _>("fleet_types").ok().flatten(),
        "facebook_url": row.try_get::<Option<String>, _>("facebook_url").ok().flatten(),
        "instagram_url": row.try_get::<Option<String>, _>("instagram_url").ok().flatten(),
        "whatsapp_number": row.try_get::<Option<String>, _>("whatsapp_number").ok().flatten(),
        "languages": row.try_get::<Option<Vec<String>>, _>("languages").ok().flatten(),
        "years_in_operation": row.try_get::<Option<i32>, _>("years_in_operation").ok().flatten(),
        "business_email": row.try_get::<Option<String>, _>("business_email").ok().flatten(),
        "mpesa_number": row.try_get::<Option<String>, _>("mpesa_number").ok().flatten(),
        "bank_name": row.try_get::<Option<String>, _>("bank_name").ok().flatten(),
        "emergency_contact_name": row.try_get::<Option<String>, _>("emergency_contact_name").ok().flatten(),
        "emergency_contact_phone": row.try_get::<Option<String>, _>("emergency_contact_phone").ok().flatten(),
        "certificate_of_incorporation_url": sign_admin(row.try_get::<Option<String>, _>("certificate_of_incorporation_url").ok().flatten()),
        "tin_certificate_url": sign_admin(row.try_get::<Option<String>, _>("tin_certificate_url").ok().flatten()),
        "tourism_license_url": sign_admin(row.try_get::<Option<String>, _>("tourism_license_url").ok().flatten()),
        "vehicle_registration_url": sign_admin(row.try_get::<Option<String>, _>("vehicle_registration_url").ok().flatten()),
        "vehicle_insurance_url": sign_admin(row.try_get::<Option<String>, _>("vehicle_insurance_url").ok().flatten()),
        "guide_license_url": sign_admin(row.try_get::<Option<String>, _>("guide_license_url").ok().flatten()),
        "verification_status": row.try_get::<String, _>("verification_status").unwrap_or_else(|_| "pending".into()),
        "verified_at": row.try_get::<Option<String>, _>("verified_at").ok().flatten(),
        "verified_by": row.try_get::<Option<Uuid>, _>("verified_by").ok().flatten(),
        "rejection_reason": row.try_get::<Option<String>, _>("rejection_reason").ok().flatten(),
        "created_at": row.try_get::<String, _>("created_at").unwrap_or_default(),
        "compliance": compliance
    })))
}

#[derive(Deserialize)]
pub struct VerifyRequest {
    pub status: String,
    pub rejection_reason: Option<String>,
}

pub async fn admin_verify_operator(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(operator_id): Path<Uuid>,
    Json(req): Json<VerifyRequest>,
) -> AppResult<Json<Value>> {
    auth.require_admin()?;

    if !["verified", "rejected", "under_review", "suspended"].contains(&req.status.as_str()) {
        return Err(AppError::BadRequest(
            "Status must be: verified, rejected, under_review, or suspended".to_string(),
        ));
    }

    let exists: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM users WHERE id = $1 AND role = 'operator'")
            .bind(operator_id)
            .fetch_one(&state.db)
            .await?;

    if exists == 0 {
        return Err(AppError::NotFound("Operator not found".to_string()));
    }

    sqlx::query(
        "INSERT INTO operator_profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING",
    )
    .bind(operator_id)
    .execute(&state.db)
    .await?;

    sqlx::query(
        r#"UPDATE operator_profiles
           SET verification_status = $1::operator_verification_status,
               verified_by = $2,
               verified_at = CASE WHEN $1 = 'verified' THEN now() ELSE NULL END,
               rejection_reason = $3,
               updated_at = now()
           WHERE user_id = $4"#,
    )
    .bind(&req.status)
    .bind(auth.id)
    .bind(req.rejection_reason.as_deref())
    .bind(operator_id)
    .execute(&state.db)
    .await?;

    sqlx::query(
        "INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id) VALUES ($1, $2, 'operator', $3)",
    )
    .bind(auth.id)
    .bind(format!("operator_{}", req.status))
    .bind(operator_id)
    .execute(&state.db)
    .await?;

    Ok(Json(json!({
        "message": format!("Operator {}", req.status),
        "operator_id": operator_id,
        "status": req.status
    })))
}

pub async fn operator_analytics(
    State(state): State<AppState>,
    auth: AuthUser,
) -> AppResult<Json<Value>> {
    auth.require_operator()?;

    let metrics = sqlx::query(
        r#"SELECT
             COUNT(DISTINCT l.id) as total_listings,
             COUNT(DISTINCT l.id) FILTER (WHERE l.status = 'active') as active_listings,
             COUNT(b.id) as total_bookings,
             COUNT(b.id) FILTER (WHERE b.status = 'pending') as pending_bookings,
             COUNT(b.id) FILTER (WHERE b.status = 'confirmed') as confirmed_bookings,
             COUNT(b.id) FILTER (WHERE b.status = 'cancelled') as cancelled_bookings,
             COALESCE(SUM(b.total_amount), 0)::text as gmv,
             COALESCE(AVG(b.total_amount), 0)::text as avg_order_value
           FROM listings l
           LEFT JOIN bookings b ON b.listing_id = l.id
           WHERE l.operator_id = $1 AND l.deleted_at IS NULL"#,
    )
    .bind(auth.id)
    .fetch_one(&state.db)
    .await?;

    let destinations = sqlx::query(
        r#"SELECT d.name,
                  COUNT(b.id) as bookings,
                  COALESCE(SUM(b.total_amount), 0)::text as gmv
           FROM listings l
           JOIN destinations d ON d.id = l.destination_id
           LEFT JOIN bookings b ON b.listing_id = l.id
           WHERE l.operator_id = $1 AND l.deleted_at IS NULL
           GROUP BY d.name
           ORDER BY bookings DESC, d.name ASC
           LIMIT 5"#,
    )
    .bind(auth.id)
    .fetch_all(&state.db)
    .await?;

    let avg_rating: Option<f64> = sqlx::query_scalar(
        r#"SELECT AVG(r.rating::float)
           FROM reviews r
           JOIN listings l ON l.id = r.listing_id
           WHERE l.operator_id = $1 AND r.moderation_status = 'approved'"#,
    )
    .bind(auth.id)
    .fetch_one(&state.db)
    .await?;

    let total_bookings = metrics.try_get::<i64, _>("total_bookings").unwrap_or(0);
    let cancelled_bookings = metrics.try_get::<i64, _>("cancelled_bookings").unwrap_or(0);
    let active_listings = metrics.try_get::<i64, _>("active_listings").unwrap_or(0);
    let total_listings = metrics.try_get::<i64, _>("total_listings").unwrap_or(0);

    let cancellation_rate = if total_bookings > 0 {
        cancelled_bookings as f64 / total_bookings as f64
    } else {
        0.0
    };
    let conversion_rate = if total_listings > 0 {
        active_listings as f64 / total_listings as f64
    } else {
        0.0
    };

    use sqlx::Row;
    let by_destination: Vec<Value> = destinations
        .iter()
        .map(|r| {
            json!({
                "name": r.try_get::<String, _>("name").unwrap_or_default(),
                "bookings": r.try_get::<i64, _>("bookings").unwrap_or(0),
                "gmv": r.try_get::<String, _>("gmv").unwrap_or_else(|_| "0".into())
            })
        })
        .collect();

    Ok(Json(json!({
        "total_listings": total_listings,
        "active_listings": active_listings,
        "total_bookings": total_bookings,
        "pending_bookings": metrics.try_get::<i64, _>("pending_bookings").unwrap_or(0),
        "confirmed_bookings": metrics.try_get::<i64, _>("confirmed_bookings").unwrap_or(0),
        "cancelled_bookings": cancelled_bookings,
        "gmv": metrics.try_get::<String, _>("gmv").unwrap_or_else(|_| "0".into()),
        "avg_order_value": metrics.try_get::<String, _>("avg_order_value").unwrap_or_else(|_| "0".into()),
        "conversion_rate": (conversion_rate * 1000.0).round() / 10.0,
        "cancellation_rate": (cancellation_rate * 1000.0).round() / 10.0,
        "average_rating": avg_rating.map(|v| (v * 10.0).round() / 10.0),
        "demand_by_destination": by_destination
    })))
}
