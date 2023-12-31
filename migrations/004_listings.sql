-- 004: Listings Base Table (class-table inheritance root)

CREATE TYPE listing_type AS ENUM ('site', 'experience', 'trip', 'safari');
CREATE TYPE listing_status AS ENUM ('draft', 'active', 'paused', 'archived');

CREATE TABLE listings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operator_id     UUID NOT NULL REFERENCES users(id),
    destination_id  UUID NOT NULL REFERENCES destinations(id),
    listing_type    listing_type NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT,
    base_price      NUMERIC(12, 2) NOT NULL CHECK (base_price >= 0),
    currency        TEXT NOT NULL DEFAULT 'USD',
    status          listing_status NOT NULL DEFAULT 'draft',
    image_urls      TEXT[],
    tags            TEXT[],
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX listings_operator_idx ON listings (operator_id) WHERE deleted_at IS NULL;
CREATE INDEX listings_destination_idx ON listings (destination_id) WHERE deleted_at IS NULL;
CREATE INDEX listings_type_idx ON listings (listing_type) WHERE deleted_at IS NULL;
CREATE INDEX listings_status_idx ON listings (status) WHERE deleted_at IS NULL;
CREATE INDEX listings_price_idx ON listings (base_price) WHERE deleted_at IS NULL;

-- Full-text search index
CREATE INDEX listings_fts_idx ON listings
    USING GIN (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,'')))
    WHERE deleted_at IS NULL;
