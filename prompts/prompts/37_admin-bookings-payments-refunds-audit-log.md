# Prompt 37: Admin: Bookings, Payments, Refunds, Audit Log

**Phase:** 4 — Admin Dashboard & Operator Portal  
**Depends on prompt(s):** 15, 26, 27, 35

## Context
Operational visibility and the security trail the deck promises investors (slide 12).

## Task
- Screen: bookings table with status, linked payment, and a manual refund action wired to the Payments service's refund().
- Screen: searchable audit_logs viewer (actor, action, entity, before/after diff).

## Constraints
- Refund actions must themselves write an audit_logs entry.

## Acceptance Criteria
- [ ] Issuing a refund from the dashboard updates payment status and produces a corresponding audit log entry.
