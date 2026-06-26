# Twende Zanzibar — Recommended Tech Stack

The client's investor deck already commits to a backend architecture (Rust, PostgreSQL, Redis, Axum + SQLx — see deck slide 11). This document keeps that foundation, since it's already part of the client's plan and investor narrative, and fills in everything around it with modern, production-proven choices suited to a fast, lean MVP team.

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

## Mobile

| Platform | Choice | Why |
|---|---|---|
| iOS | **Native SwiftUI**, MVVM, Swift Concurrency (async/await) | Per the founder's explicit choice — best native performance and platform feel. |
| Android | **Flutter** | Per the founder's explicit choice. |
| Shared contract | **OpenAPI 3.1 spec** as the single source of truth, with generated/mirrored clients on both platforms | This is what lets two different languages/frameworks stay in lockstep without sharing code — see Prompt 47. |
| Push notifications | **Firebase Cloud Messaging** (covers Android natively, routes to APNs for iOS) | One notification backend for both platforms. |
| Maps SDKs | Google Maps SDK for iOS / `google_maps_flutter` for Android | Matches the backend's Google Maps choice so routes look identical across platforms. |

## Admin Dashboard & Operator Portal

**Next.js + TypeScript**, Tailwind/shadcn-ui for fast, clean UI. A typed API client generated from the same OpenAPI spec used by mobile, so the dashboard never hand-diverges from the backend contract either.

## Infrastructure & DevOps

| Need | Choice |
|---|---|
| Local dev | Docker Compose (Postgres, Redis, MinIO) |
| CI | GitHub Actions — lint, test, build on every PR |
| Deployment (MVP stage) | Dockerized services on a simple managed host (Fly.io, Hetzner, or a DigitalOcean droplet with Docker Compose) — no need for Kubernetes until traffic actually demands it |
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

- **Firebase Cloud Messaging** for push (both platforms).
- Email via a transactional provider (e.g., Postmark, SES).
- **WhatsApp Business API** (via Twilio or Meta's Cloud API) for itinerary and transport updates — WhatsApp is the dominant messaging channel for this market, and the deck's own customer journey (slide 7) anticipates this kind of real-time, during-trip communication.

## Why this combination

Every piece either matches what's already committed in the client's investor deck (Rust/Axum/SQLx/Postgres/Redis), was explicitly requested by the founder (Postgres, Google Maps, SwiftUI, Flutter), or is the lowest-overhead modern option that keeps a small team able to ship an MVP in 0–3 months without taking on infrastructure they don't yet need (no Kubernetes, no separate search cluster, no microservices split before there's traffic to justify it).
