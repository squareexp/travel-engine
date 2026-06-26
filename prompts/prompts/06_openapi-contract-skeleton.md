# Prompt 06: OpenAPI Contract Skeleton

**Phase:** 0 — Foundations & Agent Skills  
**Depends on prompt(s):** 01, 02

## Context
iOS (SwiftUI), Android (Flutter), and the admin dashboard must all speak to the same API surface. Defining the contract first lets mobile and web work start before every backend endpoint is finished.

## Task
- Create shared/api-contracts/openapi.yaml (OpenAPI 3.1) with the top-level resource groups: auth, users, operators, destinations, sites, experiences, trips, safari, availability, bookings, payments, reviews, itinerary.
- Stub each group with at least a list/get endpoint and the core response schema, even with placeholder fields — this will be filled in as each backend prompt lands.
- Add a docs note: this file is the single source of truth; mobile/dashboard client code is generated from it, never hand-diverged.

## Constraints
- Keep schemas aligned with the domain glossary's module names exactly.

## Acceptance Criteria
- [ ] openapi.yaml lints clean with an OpenAPI validator and lists all module groups above.
