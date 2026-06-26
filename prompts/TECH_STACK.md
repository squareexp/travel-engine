# Twende Travel Engine — Backend Tech Stack

This repository is now the Rust backend source of truth. Keep the stack lean, backend-first, and deployable on a small VPS without bundling frontend apps into this repo.

## Backend

| Layer | Choice | Why |
|---|---|---|
| Language/framework | **Rust + Axum + SQLx** | Already specified in the client's deck. Strong type safety, very low memory/CPU footprint per request — cost-efficient on modest infrastructure, which matters for an early-stage East-Africa-based deployment. |
| Auth | **JWT (access + refresh)**, argon2 password hashing | Stateless, mobile-friendly; matches deck slide 11. |
| Database | **PostgreSQL 16** | Already specified. Supports the class-table-inheritance pattern needed for Sites/Experiences/Trips/Safari, plus pg_trgm for search without adding a separate search service at MVP scale. |
| Cache / sessions / rate limiting | **Redis 7** | Already specified. |
| Object storage | **S3-compatible** — MinIO locally, Cloudflare R2 or AWS S3 in production | R2 in particular avoids egress fees, which matters for image-heavy tour listings. |
| Background jobs | **Tokio-based async tasks**, or **Apalis** if a proper job queue is needed (e.g., scheduled itinerary refreshes, notification retries) | Stays in the Rust ecosystem rather than adding a separate worker language. |

## Maps & Routing

**Google Maps Platform** — explicitly requested:
- Geocoding API — resolve destination/site addresses to coordinates.
- Directions API — route + travel time between Sites in an Experience, and for Transport legs.
- Distance Matrix API — sanity-check transport fare estimates.
- Places Autocomplete — for pickup-location entry in the booking flow.

## Payments

A gateway abstraction (`PaymentGateway` trait) that supports two providers from day one:
- **Card / international** — Stripe or PayPal.
- **Mobile money** — East-Africa-specific aggregators worth evaluating at integration time (e.g., Selcom, Flutterwave, DPO Group); confirm current coverage and fees in Tanzania before committing, since this space moves fast.

Either way, webhook handling must be idempotent (unique `gateway_reference`) — this is built into the schema and the Payments service prompt.

## Infrastructure & DevOps

| Need | Choice |
|---|---|
| Local dev | Docker Compose (Postgres, Redis, MinIO) |
| CI | GitHub Actions — lint, test, build on every PR |
| Deployment (MVP stage) | Dockerized Rust service on a simple managed host or VPS — no need for Kubernetes until traffic actually demands it |
| Migrations | SQLx migrations versioned with application code, applied automatically in CI/CD, per deck slide 12 |
| Backups | Daily automated Postgres backups with a periodically *tested* restore procedure — not just backups that have never been restored |

## Observability

- **Sentry** (or equivalent) for backend, dashboard, iOS, and Android error/crash reporting.
- **Prometheus + Grafana**, or a simpler hosted alternative (Axiom, Better Stack) if self-hosting monitoring infrastructure is more than the team wants to own at MVP stage — for API and DB latency, matching the deck's reliability requirements (slide 12).
- Structured logging with request tracing IDs through the Rust backend.

## Search & Analytics

- **Postgres full-text + trigram search** at MVP scale — no need for a dedicated search service like Meilisearch or Typesense until listing volume genuinely demands it.
- A lightweight **events table / analytics pipeline** feeding the KPI dashboard the deck promises investors (GMV, commission revenue, bookings, AOV, conversion rate).

## Notifications

- Email via a transactional provider (e.g., Postmark, SES).
- WhatsApp Business API (via Twilio or Meta's Cloud API) for itinerary and transport updates.

## Why this combination

Every piece either matches the existing backend direction (Rust/Axum/SQLx/Postgres/Redis) or keeps the server lean enough to ship and run on modest infrastructure without dragging frontend code into the same repository.
