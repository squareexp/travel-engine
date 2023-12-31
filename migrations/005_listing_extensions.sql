-- 005: Listing Type Extension Tables (class-table inheritance leaves)

-- Sites: single bookable location
CREATE TABLE site_details (
    listing_id          UUID PRIMARY KEY REFERENCES listings(id) ON DELETE CASCADE,
    address             TEXT,
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    duration_hours      DOUBLE PRECISION,
    max_capacity        INTEGER,
    includes_transport  BOOLEAN NOT NULL DEFAULT FALSE,
    highlights          TEXT[]
);

-- Experiences: chains 2+ sites into a themed activity
CREATE TABLE experience_details (
    listing_id          UUID PRIMARY KEY REFERENCES listings(id) ON DELETE CASCADE,
    theme               TEXT,
    duration_hours      DOUBLE PRECISION,
    min_participants    INTEGER DEFAULT 1,
    max_participants    INTEGER
);

-- Join table: which sites compose an experience, in order
CREATE TABLE experience_sites (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id   UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    site_id         UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    sequence_order  INTEGER NOT NULL,
    UNIQUE (experience_id, site_id),
    UNIQUE (experience_id, sequence_order)
);

-- Trips: multi-day itinerary bundling listings + transport
CREATE TABLE trip_details (
    listing_id          UUID PRIMARY KEY REFERENCES listings(id) ON DELETE CASCADE,
    duration_days       INTEGER,
    max_participants    INTEGER,
    difficulty_level    TEXT -- easy, moderate, challenging, expert
);

-- Ordered items in a trip
CREATE TABLE trip_items (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id                 UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    sequence_order          INTEGER NOT NULL,
    day_number              INTEGER NOT NULL DEFAULT 1,
    item_type               TEXT NOT NULL CHECK (item_type IN ('listing', 'transport', 'free_time')),
    listing_id              UUID REFERENCES listings(id),
    transport_description   TEXT,
    notes                   TEXT,
    UNIQUE (trip_id, sequence_order)
);

-- Safari: park adventures
CREATE TABLE safari_details (
    listing_id          UUID PRIMARY KEY REFERENCES listings(id) ON DELETE CASCADE,
    park_name           TEXT,
    vehicle_class       TEXT, -- shared_jeep, private_jeep, luxury_4wd
    game_drive_window   TEXT, -- e.g. "06:00-10:00 & 15:30-18:30"
    park_fee_amount     NUMERIC(12, 2),
    park_fee_currency   TEXT DEFAULT 'USD'
);
