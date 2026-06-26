# Database conventions

Use lowercase `snake_case` table and column names. Primary keys are UUIDs. Mutable product data uses `deleted_at` for soft deletion when records must remain auditable. Lifecycle states use PostgreSQL enums rather than unconstrained text.

Migrations are ordered, immutable SQLx migration files under `server/migrations/`, named with a zero-padded sequence and purpose, for example `015_add_listing_search_index.sql`. Never edit a migration that has been applied to a shared environment.

Audit logs are append-only. A new audit event records the actor, action, entity, and metadata; it never overwrites a prior event. Extension tables for Site, Experience, Trip, and Safari share the parent listing UUID as their primary and foreign key.

Secrets are injected by the deployment platform's secret manager. `.env` files are local only and ignored by Git; only redacted `.env.example` files are committed.
