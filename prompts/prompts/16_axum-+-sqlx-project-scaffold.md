# Prompt 16: Axum + SQLx Project Scaffold

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 05, 15

## Context
Stand up the real backend service that every API prompt from here on adds to.

## Task
- Initialize backend/ as a Cargo workspace: crates for api (Axum routes/handlers), domain (business logic/services), db (SQLx repositories), and config.
- Wire a Postgres connection pool (SQLx) and Redis client using the config crate from prompt 05.
- Add a /healthz endpoint that checks DB and Redis connectivity.
- Add the standard error envelope and tracing/logging middleware per docs/skills/api-conventions.md.

## Constraints
- Keep handlers thin — business logic lives in the domain crate so it stays testable without HTTP.

## Acceptance Criteria
- [ ] cargo run starts the server; GET /healthz returns 200 with DB and Redis status.
