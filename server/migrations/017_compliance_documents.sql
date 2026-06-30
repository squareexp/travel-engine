-- 017: Tanzania/Zanzibar tourism-vendor compliance documents
--
-- Repurposes the two generic document slots added in 016 into the specific
-- government documents required to legally operate:
--   license_document_url    -> certificate_of_incorporation_url (BRELA/BPRA)
--   insurance_document_url  -> vehicle_insurance_url (car-hire only)
-- and adds the remaining KYB documents: TIN certificate, TALA/ZCT tourism
-- license, vehicle registration, guide license. Required-document sets are
-- computed in application code based on service_categories + Zanzibar
-- location, not enforced by the schema.

ALTER TABLE operator_profiles
    RENAME COLUMN license_document_url TO certificate_of_incorporation_url;

ALTER TABLE operator_profiles
    RENAME COLUMN insurance_document_url TO vehicle_insurance_url;

ALTER TABLE operator_profiles
    -- Which tourism activities this operator offers; drives which documents
    -- are required. Values: safari, car_hire, trekking, water_sports, hotel_lodge.
    ADD COLUMN service_categories        TEXT[],

    -- Business registration authority: 'brela' (mainland) or 'bpra' (Zanzibar).
    ADD COLUMN registration_authority    TEXT,

    -- TRA tax compliance.
    ADD COLUMN tin_number                TEXT,
    ADD COLUMN tin_certificate_url       TEXT,

    -- Tourism license: TALA (mainland, class A or C) or ZCT (Zanzibar).
    ADD COLUMN tourism_license_issuer    TEXT,
    ADD COLUMN tourism_license_class     TEXT,
    ADD COLUMN tourism_license_number    TEXT,
    ADD COLUMN tourism_license_url       TEXT,

    -- Car-hire safety documents.
    ADD COLUMN vehicle_registration_url  TEXT,

    -- Guides / trekking / water-sports operators.
    ADD COLUMN guide_license_url         TEXT;

-- Personal identity capture (National ID number), separate from business
-- compliance. Lives on users since it's about the individual, not the business.
ALTER TABLE users
    ADD COLUMN national_id_number TEXT;
