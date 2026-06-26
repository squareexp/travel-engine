# Prompt 34: Analytics Event Pipeline

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 26, 27, 28

## Context
Turns the database into the 'decision engine' the deck promises investors (slide 14): GMV, commission revenue, bookings, AOV.

## Task
- Add an events table (or lightweight separate analytics DB per the architecture diagram in slide 11) capturing: listing_viewed, search_performed, booking_created, payment_succeeded, review_submitted.
- Emit events from the relevant service-layer calls (search, bookings, payments) without coupling business logic to analytics — use an async event bus or simple background task.
- Add a read-only GET /api/v1/admin/kpis endpoint computing GMV, commission revenue, bookings count, AOV for a given period.

## Constraints
- Analytics writes must never be on the critical path of a booking/payment — failures here must not roll back a real transaction.

## Acceptance Criteria
- [ ] After running a handful of test bookings, the KPI endpoint returns correct GMV/AOV/commission figures matching the underlying bookings/payments rows.
