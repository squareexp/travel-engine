# Prompt 13: Trip Extension + trip_items

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 12

## Context
A Trip is the highest-level bundle: a multi-day itinerary combining Sites, Experiences, Safari, and Transport legs.

## Task
- Migration: `trip_details` (listing_id PK/FK -> listings, duration_days, group_size_min, group_size_max).
- Migration: `trip_items` (id PK, trip_listing_id FK, day_number, item_type enum['site','experience','safari','transport_leg'], reference_id, start_time, sequence_order) — a polymorphic ordered schedule.

## Constraints
- reference_id meaning depends on item_type: listings.id for site/experience/safari, transport_legs.id for transport_leg (table added in prompt 24).

## Acceptance Criteria
- [ ] Can model a 3-day Trip with Day 1 = airport Transport leg + a Site, Day 2 = a Safari, Day 3 = an Experience.
