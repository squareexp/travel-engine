# Prompt 15: Availability, Bookings, Payments, Reviews, Itinerary, Audit

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 11, 12, 13, 14

## Context
The transactional core from deck slide 9 — this is what makes everything sellable, payable, and auditable.

## Task
- Migration: `availability` (id PK, listing_id FK, travel_date, capacity, capacity_booked default 0) with a check constraint capacity_booked <= capacity.
- Migration: `bookings` (id PK, user_id FK, listing_id FK, availability_id FK, guests, total_amount, status enum['pending','confirmed','cancelled','completed'], created_at).
- Migration: `payments` (id PK, booking_id FK, gateway, gateway_reference unique, currency, amount, status enum['pending','succeeded','failed','refunded'], created_at).
- Migration: `reviews` (id PK, booking_id FK unique, rating 1-5, comment, moderation_status enum['pending','approved','rejected']).
- Migration: `itinerary_items` (id PK, booking_id FK, start_time, location, note).
- Migration: `audit_logs` (id PK, actor_user_id FK, action, entity_type, entity_id, before_state jsonb, after_state jsonb, created_at).

## Constraints
- payments.gateway_reference unique constraint is what makes webhook handling idempotent later (prompt 27).

## Acceptance Criteria
- [ ] All six migrations apply in order; a manual test booking can be inserted with a linked payment and review without FK errors; oversell is impossible due to the capacity check constraint.
