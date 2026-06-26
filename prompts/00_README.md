# Twende Travel Engine Prompt Archive

This folder is a sequenced set of build prompts that originally described a larger product plan. The repository has since been narrowed to the Rust backend, so treat these files as archived context rather than the active repository scope.

Read alongside:
- `PRODUCT_OVERVIEW.md` — product context for the travel marketplace
- `TECH_STACK.md` — backend stack guidance for the server repo

## How to use the prompts

1. Open a fresh coding-agent session in your project repo.
2. Paste the contents of `prompts/01_*.md`, let the agent build it, review the diff.
3. Verify every box under **Acceptance Criteria** before moving on — don't skip ahead on a half-finished step. Several later prompts (especially the orchestration, payments, and concurrency ones) silently assume earlier acceptance criteria actually hold.
4. Paste the next prompt. Each file states its dependencies at the top so you always know what must already exist.
5. Treat `docs/skills/*.md` (created in Prompt 02) as required context to re-paste into any agent session that's drifted or lost history.

## Phase map

| Phase | Prompts | What gets built |
|---|---|---|
| 0 — Foundations & Agent Skills | 01–06 | Repo layout, domain glossary, local Docker env, CI skeleton, secrets strategy, shared OpenAPI contract |
| 1 — Database Foundation | 07–15 | Full ERD reconciling the deck's schema with Sites/Experiences/Trips/Safari, then every migration |
| 2 — Rust Backend Core | 16–26 | Axum + SQLx scaffold, auth, every module's API, the Transport adapter, no-oversell inventory engine, booking orchestration |
| 3 — Payments, Search, Maps, Notifications | 27–34 | Payments + webhooks, reviews, itinerary generation, Google Maps routing, search, push/WhatsApp notifications, Redis caching, analytics/KPIs |
| 4 — Launch Readiness | 48–50 | Full test suite, monitoring/backups, MVP launch checklist + Zanzibar pilot rollout |

## Design decisions baked into these prompts

- **One shared `listings` table, four type extensions.** The investor deck's schema (slide 9–10) uses one generic `tours` table. Your actual product has four distinct sellable types — Site, Experience, Trip, Safari — each with different fields and rules (a Site is one location; an Experience chains 2+ Sites; a Trip bundles everything across multiple days; Safari needs park/vehicle/fee fields none of the others have). Prompt 07 designs a class-table-inheritance pattern (a shared `listings` base + per-type extension tables) so search, availability, and bookings can all reference one `listing_id` regardless of type, while each type still gets its own clean schema.
- **Transport is integrated, never rebuilt.** Every prompt that touches Transport (09, 24, 26) treats your existing transport backend as an external service called through an adapter — quote a fare, book a ride, check status — never as logic to reimplement.
- **No-oversell is enforced at the database level**, not just in application code (Prompt 15's check constraint + Prompt 25's row-locking), because that's the single most damaging bug class for a booking marketplace.
- The archive originally assumed separate client codebases. That frontend work now lives outside this repository and is not part of the backend server build.

## What this plan does not cover

Pricing/commission validation, legal/payment-licensing setup in Tanzania, and marketing execution are explicitly out of scope for these engineering prompts — they're called out in the deck as items "to validate in pilot" and belong in a separate business workstream.
