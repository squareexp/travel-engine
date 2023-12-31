-- 001: Users & Authentication

CREATE TYPE user_role AS ENUM ('traveler', 'operator', 'admin');

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL,
    phone           TEXT,
    password_hash   TEXT,
    full_name       TEXT NOT NULL,
    avatar_url      TEXT,
    role            user_role NOT NULL DEFAULT 'traveler',
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);

CREATE UNIQUE INDEX users_email_unique ON users (email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX users_phone_unique ON users (phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX users_role_idx ON users (role);

-- Seed admin user (password: Admin123!)
-- Hash was generated with argon2: $argon2id$v=19$m=65536,t=2,p=1$...
-- We will insert via the seed SQL at first migration
-- In production, run: cargo run -- seed-admin
