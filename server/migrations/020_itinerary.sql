-- 020: Operator-authored day-by-day itineraries + public sharing
--
-- Distinct from trip_items (which bundles other listings into a trip) and
-- itinerary_items (migration 011, a per-booking traveler plan). This is the
-- narrative itinerary an operator writes for a Trip / Experience / Safari
-- listing: an ordered set of days, each with a title, description, and up to
-- three images. Purely additive.

CREATE TABLE itinerary_days (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id    UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    day_number    INTEGER NOT NULL,
    title         TEXT,
    description   TEXT,
    -- Permanent public GCS URLs (see GcsClient.upload_public). Max 3 enforced
    -- in application code; kept as a plain array here for simple read/replace.
    image_urls    TEXT[] NOT NULL DEFAULT '{}',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (listing_id, day_number)
);

CREATE INDEX itinerary_days_listing_idx ON itinerary_days (listing_id, day_number);

-- Non-null => the itinerary is publicly shareable at that token; null =>
-- private. Minted/revoked by the operator; unique so a token maps to exactly
-- one listing.
ALTER TABLE listings
    ADD COLUMN public_itinerary_token TEXT UNIQUE;
