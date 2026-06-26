-- 013: Link Twende users to Base-IdP identities

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS idp_subject TEXT,
    ADD COLUMN IF NOT EXISTS idp_issuer  TEXT,
    ALTER COLUMN password_hash DROP NOT NULL;

-- Unique on (issuer, subject) so the same IdP user maps to exactly one Twende user.
CREATE UNIQUE INDEX IF NOT EXISTS users_idp_identity_unique
    ON users (idp_issuer, idp_subject)
    WHERE idp_subject IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS users_idp_subject_idx
    ON users (idp_subject)
    WHERE idp_subject IS NOT NULL;
