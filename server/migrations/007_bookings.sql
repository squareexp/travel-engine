-- 007: Bookings

CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed', 'refunded');

CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    listing_id      UUID NOT NULL REFERENCES listings(id),
    availability_id UUID REFERENCES availability(id),
    guests          INTEGER NOT NULL CHECK (guests > 0),
    total_amount    NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    currency        TEXT NOT NULL DEFAULT 'USD',
    status          booking_status NOT NULL DEFAULT 'pending',
    special_requests TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX bookings_user_idx ON bookings (user_id);
CREATE INDEX bookings_listing_idx ON bookings (listing_id);
CREATE INDEX bookings_status_idx ON bookings (status);
CREATE INDEX bookings_availability_idx ON bookings (availability_id);
