# Prompt 27: Payments Service

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 15, 26

## Context
Turns a draft booking into revenue, matching the deck's commission-based business model (slide 8).

## Task
- Define a PaymentGateway trait with charge(), refund() implemented for: card/PayPal provider and a mobile-money provider (evaluate current East-Africa aggregators such as Selcom, Flutterwave, or DPO Group at integration time — pick one to implement first).
- POST /api/v1/payments/checkout creates a payment intent for a draft booking.
- POST /api/v1/payments/webhook handles gateway callbacks; uses payments.gateway_reference's unique constraint to guarantee idempotency even if the gateway retries.
- On payment success, flip booking status to 'confirmed'; on failure, release reserved capacity (call prompt 25's release_capacity).

## Constraints
- Webhook handler must be safe to call twice with the same payload without double-confirming or double-charging.

## Acceptance Criteria
- [ ] Replaying the same webhook payload twice results in exactly one confirmed booking, not two.
