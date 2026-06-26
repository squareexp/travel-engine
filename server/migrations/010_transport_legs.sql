-- 010: Transport Legs (Pistoni integration records)
-- These are created when Twende calls the Pistoni car-hire API.

CREATE TABLE transport_legs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id          UUID REFERENCES bookings(id),
    external_ride_id    TEXT NOT NULL, -- Pistoni rental/ride ID
    pickup_address      TEXT NOT NULL,
    dropoff_address     TEXT NOT NULL,
    pickup_lat          DOUBLE PRECISION,
    pickup_lng          DOUBLE PRECISION,
    dropoff_lat         DOUBLE PRECISION,
    dropoff_lng         DOUBLE PRECISION,
    fare_amount         NUMERIC(12, 2),
    currency            TEXT DEFAULT 'USD',
    status              TEXT NOT NULL DEFAULT 'pending',
    pistoni_response    JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX transport_legs_booking_idx ON transport_legs (booking_id);
CREATE INDEX transport_legs_external_id_idx ON transport_legs (external_ride_id);
