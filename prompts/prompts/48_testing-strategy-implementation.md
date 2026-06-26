# Prompt 48: Testing Strategy Implementation

**Phase:** 6 — Testing, Observability, Launch  
**Depends on prompt(s):** all backend + dashboard prompts

## Context
Implements the deck's own testing plan (slide 13) as real, running suites.

## Task
- Backend: unit tests for pricing/availability/orchestration logic in the domain crate; API tests for auth, booking creation, payment callbacks, reviews; DB tests for migrations/constraints/rollback using a disposable test database reset per run.
- Integration tests: Rust API + real Postgres + real Redis + mocked object storage and mocked TransportClient/PaymentGateway.
- End-to-end test: search -> book -> pay -> receipt -> itinerary -> review, run against the docker-compose dev stack.
- Explicitly test: payment webhook idempotency (prompt 27), booking concurrency/no-oversell (prompt 25), and orchestration rollback (prompt 26).

## Constraints
- CI (prompt 04) must run unit + API + DB tests on every PR; E2E can run on a slower nightly/merge-to-main schedule.

## Acceptance Criteria
- [ ] All five 'definition of done' bullets from deck slide 13 are met and demonstrably enforced by CI, not just documented.
