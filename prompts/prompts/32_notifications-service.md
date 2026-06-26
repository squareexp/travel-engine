# Prompt 32: Notifications Service

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 26, 27, 29

## Context
Keeps travelers and operators informed before, during, and after the trip per the deck's customer-journey step 4.

## Task
- Add a NotificationSender trait with implementations for push (Firebase Cloud Messaging, which covers both Android/Flutter and iOS via APNs through FCM), email, and a WhatsApp Business API hook for itinerary/transport updates.
- Trigger notifications on: booking confirmed, payment failed, transport pickup reminder, review request after trip completion.

## Constraints
- Notification failures must never fail the originating booking/payment transaction — fire-and-forget with logging and retry.

## Acceptance Criteria
- [ ] Confirming a booking in tests results in a queued push + email notification without blocking the booking response.
