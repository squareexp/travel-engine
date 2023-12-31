-- 003: Destinations

CREATE TABLE destinations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    country     TEXT NOT NULL DEFAULT 'Tanzania',
    region      TEXT,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    description TEXT,
    image_urls  TEXT[],
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX destinations_country_idx ON destinations (country);
CREATE INDEX destinations_active_idx ON destinations (is_active);

-- Seed common Zanzibar destinations
INSERT INTO destinations (name, country, region, latitude, longitude, description) VALUES
    ('Stone Town', 'Tanzania', 'Zanzibar', -6.1630, 39.1897, 'UNESCO World Heritage Site and cultural heart of Zanzibar'),
    ('Nungwi Beach', 'Tanzania', 'Zanzibar', -5.7260, 39.2976, 'Pristine white-sand beach at the northern tip of Zanzibar'),
    ('Kendwa Beach', 'Tanzania', 'Zanzibar', -5.7550, 39.2888, 'Calm-water beach perfect for swimming and snorkeling'),
    ('Paje', 'Tanzania', 'Zanzibar', -6.2682, 39.5329, 'Kite-surfing capital and laid-back beach village'),
    ('Serengeti', 'Tanzania', 'Arusha', -2.3333, 34.8333, 'World-famous national park and Great Migration route'),
    ('Ngorongoro', 'Tanzania', 'Arusha', -3.2000, 35.4950, 'Stunning volcanic crater with year-round wildlife'),
    ('Kilimanjaro', 'Tanzania', 'Kilimanjaro', -3.0674, 37.3556, 'Africa''s highest peak and top trekking destination'),
    ('Zanzibar International Airport', 'Tanzania', 'Zanzibar', -6.2225, 39.2248, 'Main airport serving Zanzibar Island');
