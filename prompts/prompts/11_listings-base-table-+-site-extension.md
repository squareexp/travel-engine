# Prompt 11: Listings Base Table + Site Extension

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 07, 09, 10

## Context
Implement the shared `listings` table designed in prompt 07, then the Site extension — the simplest, one-way bookable module.

## Task
- Migration: `listings` (id PK, operator_id FK, destination_id FK, type enum, title, description, base_price, currency, status enum['draft','published','suspended'], created_at, deleted_at).
- Migration: `site_details` (listing_id PK/FK -> listings, location_lat, location_lng, default_duration_minutes, transport_eligible boolean).
- Add an index on listings(type, destination_id, status) for search.

## Constraints
- transport_eligible flag is what later lets the booking flow ask 'do you need transport?' for a Site.

## Acceptance Criteria
- [ ] Can insert a Site listing end-to-end and query it joined with its base listings row.
