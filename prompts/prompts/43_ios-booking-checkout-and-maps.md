# Prompt 43: iOS: Booking, Checkout & Maps

**Phase:** 5 — Mobile Apps  
**Depends on prompt(s):** 25, 26, 27, 30, 42

## Context
Where revenue actually happens.

## Task
- Build the booking flow: pick date/guests (checking GET /availability live), optional transport add-on toggle for Sites, review screen with price breakdown (base_price + park_fee + transport fare where applicable).
- Integrate the Google Maps SDK for iOS to show the route/stops on the booking review and post-booking itinerary screens.
- Wire checkout to POST /payments/checkout and handle the gateway's confirmation flow.

## Constraints
- Never show a 'Book Now' button as enabled if live availability is 0 — fetch fresh availability right before allowing checkout.

## Acceptance Criteria
- [ ] A full booking — Site with transport add-on — completes end-to-end against the real backend, including a visible route on the map.
