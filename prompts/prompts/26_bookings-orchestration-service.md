# Prompt 26: Bookings Orchestration Service

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 22, 24, 25

## Context
The single checkout that ties Sites, Experiences, Safari, and Transport into one booking, regardless of which module the traveler started from.

## Task
- POST /api/v1/bookings accepting either a single listing_id (Site/Experience/Safari) or a trip_id, plus optional transport add-on flags.
- Orchestrate: reserve_capacity for every involved listing, create transport_legs via the adapter if requested, create the bookings row, return a draft booking awaiting payment.
- On any step failure, roll back all reservations (saga-style compensation) so nothing is left half-booked.

## Constraints
- This endpoint does not take payment itself — it hands off to the Payments service (prompt 27) for that.

## Acceptance Criteria
- [ ] Booking a Trip that includes a Transport leg either fully succeeds (all legs reserved) or fully fails with everything released — verified by a test that forces a mid-orchestration failure.
