# Prompt 25: Availability & Inventory Engine

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 15, 20, 23

## Context
The deck's non-negotiable: 'booking inventory cannot oversell' (slide 13).

## Task
- Service-layer function reserve_capacity(listing_id, date, guests) that increments capacity_booked inside a DB transaction with row-level locking (SELECT ... FOR UPDATE) and rejects if it would exceed capacity.
- release_capacity(...) for cancellations.
- GET /api/v1/availability?listing_id=&date= for the booking UI to check before showing 'Book Now.'

## Constraints
- This must be safe under concurrent requests — write a test that fires N simultaneous reservation attempts against a capacity of N-1 and asserts exactly N-1 succeed.

## Acceptance Criteria
- [ ] Concurrency test passes: no oversell under simultaneous booking attempts.
