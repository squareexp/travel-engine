# Prompt 28: Reviews & Ratings Module

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 15, 27

## Context
Closes the trust loop from the deck's customer journey (slide 7, step 5: Review).

## Task
- POST /api/v1/bookings/:id/review — only allowed for bookings with status='completed', one review per booking.
- Admin moderation endpoints: GET pending reviews, PATCH approve/reject.
- Aggregate rating exposed on listing GET responses (avg rating, count of approved reviews).

## Constraints
- Unmoderated reviews never appear in public listing responses.

## Acceptance Criteria
- [ ] A review submitted before moderation does not affect the public-facing rating average until approved.
