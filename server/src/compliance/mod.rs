//! Tanzania/Zanzibar tourism-vendor KYB compliance.
//!
//! Required documents are computed from the operator's chosen service
//! categories and whether they operate in Zanzibar (TALA vs ZCT). Listing
//! quota is a straight function of how many of those required documents have
//! been uploaded — not of admin approval — so operators can start posting
//! before a human has reviewed anything.

use serde::Serialize;

pub const CATEGORY_SAFARI: &str = "safari";
pub const CATEGORY_CAR_HIRE: &str = "car_hire";
pub const CATEGORY_TREKKING: &str = "trekking";
pub const CATEGORY_WATER_SPORTS: &str = "water_sports";
pub const CATEGORY_HOTEL_LODGE: &str = "hotel_lodge";

pub const ALL_CATEGORIES: &[&str] = &[
    CATEGORY_SAFARI,
    CATEGORY_CAR_HIRE,
    CATEGORY_TREKKING,
    CATEGORY_WATER_SPORTS,
    CATEGORY_HOTEL_LODGE,
];

#[derive(Serialize, Clone, Copy)]
pub struct DocRequirement {
    pub key: &'static str,
    pub label: &'static str,
}

/// Every operator needs proof of legal existence + a tourism license, no
/// matter what they sell. The specific license (TALA vs ZCT) is a labeling
/// concern handled by `tourism_license_label`, not a separate requirement.
const UNIVERSAL: &[DocRequirement] = &[
    DocRequirement {
        key: "certificate_of_incorporation",
        label: "Certificate of Incorporation / Business Name Registration",
    },
    DocRequirement {
        key: "tin_certificate",
        label: "TIN Certificate",
    },
    DocRequirement {
        key: "tourism_license",
        label: "Tourism License",
    },
];

const VEHICLE_DOCS: &[DocRequirement] = &[
    DocRequirement {
        key: "vehicle_registration",
        label: "Vehicle Registration Card",
    },
    DocRequirement {
        key: "vehicle_insurance",
        label: "Comprehensive Vehicle Insurance",
    },
];

const GUIDE_DOC: DocRequirement = DocRequirement {
    key: "guide_license",
    label: "Professional Guide License",
};

/// Human label for the tourism-license requirement, based on location and
/// activity — purely informational, doesn't change what's required.
pub fn tourism_license_label(categories: &[String], is_zanzibar: bool) -> &'static str {
    if is_zanzibar {
        return "ZCT Tourism Operating License";
    }
    if categories.iter().any(|c| c == CATEGORY_HOTEL_LODGE) {
        "TALA License (Class C — Hotel/Lodge/Tented Camp)"
    } else if categories.iter().any(|c| c == CATEGORY_TREKKING) {
        "TALA License (Class A — Mountain Climbing/Trekking)"
    } else if categories.iter().any(|c| c == CATEGORY_WATER_SPORTS) {
        "TALA License (Class A — Tourism Water Sports)"
    } else if categories.iter().any(|c| c == CATEGORY_CAR_HIRE) {
        "TALA License (Class A — Car Rental/Hire)"
    } else {
        "TALA License (Class A — Tour Operator/Safari Outfitter)"
    }
}

pub fn required_documents(categories: &[String], is_zanzibar: bool) -> Vec<DocRequirement> {
    let mut docs: Vec<DocRequirement> = UNIVERSAL.to_vec();

    if categories.iter().any(|c| c == CATEGORY_CAR_HIRE) {
        docs.extend_from_slice(VEHICLE_DOCS);
    }
    if categories
        .iter()
        .any(|c| c == CATEGORY_TREKKING || c == CATEGORY_WATER_SPORTS)
    {
        docs.push(GUIDE_DOC);
    }

    let _ = is_zanzibar; // reserved: location only changes labeling today
    docs
}

/// Which of the required document keys are present, keyed by `DocRequirement.key`.
pub struct UploadedDocs {
    pub certificate_of_incorporation: bool,
    pub tin_certificate: bool,
    pub tourism_license: bool,
    pub vehicle_registration: bool,
    pub vehicle_insurance: bool,
    pub guide_license: bool,
}

impl UploadedDocs {
    pub fn has(&self, key: &str) -> bool {
        match key {
            "certificate_of_incorporation" => self.certificate_of_incorporation,
            "tin_certificate" => self.tin_certificate,
            "tourism_license" => self.tourism_license,
            "vehicle_registration" => self.vehicle_registration,
            "vehicle_insurance" => self.vehicle_insurance,
            "guide_license" => self.guide_license,
            _ => false,
        }
    }
}

/// Percentage (0.0-100.0) of the required documents that have been uploaded.
pub fn completion_percent(required: &[DocRequirement], uploaded: &UploadedDocs) -> f64 {
    if required.is_empty() {
        return 100.0;
    }
    let done = required.iter().filter(|d| uploaded.has(d.key)).count();
    (done as f64 / required.len() as f64) * 100.0
}

/// Maximum number of active listings this completion level unlocks.
/// `None` means unlimited.
pub fn listing_quota(completion_percent: f64) -> Option<i64> {
    if completion_percent >= 100.0 {
        None
    } else if completion_percent >= 50.0 {
        Some(5)
    } else {
        Some(1)
    }
}

/// Best-effort Zanzibar detection from free-text location fields.
pub fn is_zanzibar_location(
    country: Option<&str>,
    region: Option<&str>,
    city: Option<&str>,
) -> bool {
    let needles = ["zanzibar", "unguja", "pemba", "stone town"];
    [country, region, city].into_iter().flatten().any(|field| {
        let lower = field.to_lowercase();
        needles.iter().any(|n| lower.contains(n))
    })
}
