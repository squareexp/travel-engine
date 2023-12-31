-- 006: Availability (no-oversell enforced at DB level)

CREATE TABLE availability (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id      UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    travel_date     DATE NOT NULL,
    capacity        INTEGER NOT NULL CHECK (capacity > 0),
    capacity_booked INTEGER NOT NULL DEFAULT 0 CHECK (capacity_booked >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- No-oversell constraint at DB level
    CONSTRAINT no_oversell CHECK (capacity_booked <= capacity),
    UNIQUE (listing_id, travel_date)
);

CREATE INDEX availability_listing_date_idx ON availability (listing_id, travel_date);
CREATE INDEX availability_date_idx ON availability (travel_date);
