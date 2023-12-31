-- 008: Payments (idempotent by gateway_reference)

CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');

CREATE TABLE payments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id          UUID NOT NULL REFERENCES bookings(id),
    gateway             TEXT NOT NULL, -- stripe, mobile_money, cash
    gateway_reference   TEXT NOT NULL UNIQUE, -- idempotency key
    currency            TEXT NOT NULL DEFAULT 'USD',
    amount              NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    status              payment_status NOT NULL DEFAULT 'pending',
    gateway_metadata    JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX payments_booking_idx ON payments (booking_id);
CREATE INDEX payments_status_idx ON payments (status);
CREATE INDEX payments_gateway_ref_idx ON payments (gateway_reference);
