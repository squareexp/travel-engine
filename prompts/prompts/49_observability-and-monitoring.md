# Prompt 49: Observability & Monitoring

**Phase:** 6 — Testing, Observability, Launch  
**Depends on prompt(s):** 16, 35, 40, 44

## Context
Deck slide 12 calls for 'observability for API and DB latency' and reliable backups — this prompt wires it up.

## Task
- Add structured logging + request tracing IDs through the Rust backend.
- Integrate Sentry (or equivalent) for backend, admin dashboard, iOS, and Android crash/error reporting.
- Add Prometheus metrics export from the backend (request latency, DB query latency, error rates) and a basic Grafana dashboard, or a simpler hosted alternative (e.g. Axiom, Better Stack) if self-hosting Grafana is overkill at MVP scale.
- Document the backup policy: daily Postgres backups with a tested restore procedure (deck slide 12's reliability bullet).

## Constraints
- Error tracking must scrub PII (no raw payment details, password hashes, or full phone numbers in logs/Sentry payloads).

## Acceptance Criteria
- [ ] A deliberately thrown test error in each of the four apps (backend, dashboard, iOS, Android) appears in the error tracker within seconds; a restore-from-backup drill succeeds against a scratch database.
