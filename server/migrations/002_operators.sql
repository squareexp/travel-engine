-- 002: Operator Profiles & Verification

CREATE TYPE operator_verification_status AS ENUM ('pending', 'under_review', 'verified', 'rejected', 'suspended');

CREATE TABLE operator_profiles (
    user_id                     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    business_name               TEXT,
    business_description        TEXT,
    phone                       TEXT,
    website                     TEXT,
    address                     TEXT,
    business_registration_number TEXT,
    license_document_url        TEXT,
    verification_status         operator_verification_status NOT NULL DEFAULT 'pending',
    verified_at                 TIMESTAMPTZ,
    verified_by                 UUID REFERENCES users(id),
    rejection_reason            TEXT,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX op_profiles_status_idx ON operator_profiles (verification_status);
