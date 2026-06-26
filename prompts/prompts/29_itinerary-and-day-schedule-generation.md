# Prompt 29: Itinerary & Day-Schedule Generation

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 15, 26

## Context
Once a Trip is booked, travelers need a readable day-by-day plan, not raw trip_items rows.

## Task
- Service that expands a confirmed booking's trip_items (or a single listing booking) into itinerary_items with concrete start_time and location, pulling transport pickup times from transport_legs.
- GET /api/v1/bookings/:id/itinerary returns the day-by-day human-readable schedule.

## Constraints
- Itinerary generation must be idempotent — re-running it after a transport delay update should refresh times without duplicating items.

## Acceptance Criteria
- [ ] A booked 3-day Trip returns a clean day-by-day itinerary including transport pickup times.
