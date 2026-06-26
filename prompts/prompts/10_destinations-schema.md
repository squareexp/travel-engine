# Prompt 10: Destinations Schema

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 08

## Context
Geographic anchors for everything else: Zanzibar, Dar, Serengeti, Kilimanjaro, per deck slide 9.

## Task
- Migration: `destinations` (id PK, name, region, type enum['island','city','national_park','mountain'], lat, lng, created_at).
- Seed Zanzibar (Stone Town, Nungwi, Paje), Dar es Salaam, Serengeti, Kilimanjaro, Ngorongoro as initial rows for local dev and demos.

## Constraints
- lat/lng stored as numeric or PostGIS point if the team wants spatial queries later — default to numeric for MVP simplicity.

## Acceptance Criteria
- [ ] Seeded destinations are queryable and match the mainland-expansion list in the deck's roadmap (slide 15).
