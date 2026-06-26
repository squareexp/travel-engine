# Prompt 22: Trips API

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 13, 21

## Context
The full itinerary builder — the most composite module, sitting on top of everything else.

## Task
- POST/GET/PATCH /api/v1/trips accepting an ordered trip_items array mixing site/experience/safari/transport_leg references across multiple days.
- Validation: day_number sequencing, no duplicate sequence_order within a day, referenced listings must be published.
- GET /api/v1/trips/:id returns the fully expanded itinerary (joins back to sites/experiences/safari details, not just raw ids).

## Constraints
- Transport legs referenced here don't exist as bookable rows until prompt 24 — stub the reference_id check until then.

## Acceptance Criteria
- [ ] A 3-day Trip mixing all item types serializes correctly with human-readable expanded details, not just foreign keys.
