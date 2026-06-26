-- 009: Reviews

CREATE TYPE review_moderation_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE reviews (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id          UUID NOT NULL UNIQUE REFERENCES bookings(id),
    user_id             UUID NOT NULL REFERENCES users(id),
    listing_id          UUID NOT NULL REFERENCES listings(id),
    rating              SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment             TEXT,
    moderation_status   review_moderation_status NOT NULL DEFAULT 'pending',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX reviews_listing_idx ON reviews (listing_id);
CREATE INDEX reviews_user_idx ON reviews (user_id);
CREATE INDEX reviews_moderation_idx ON reviews (moderation_status);
