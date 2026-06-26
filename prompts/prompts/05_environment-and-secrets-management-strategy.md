# Prompt 05: Environment & Secrets Management Strategy

**Phase:** 0 — Foundations & Agent Skills  
**Depends on prompt(s):** 03

## Context
Decide once how configuration and secrets flow through local, staging, and production so later prompts never hardcode values.

## Task
- In the Rust backend, add a config crate (e.g. config + serde) that loads from environment variables with typed structs (DatabaseConfig, RedisConfig, JwtConfig, GoogleMapsConfig, PaymentsConfig).
- Document in docs/skills/db-conventions.md (or a new docs/secrets.md) how staging/production secrets will be injected (e.g. platform secret manager, never committed files).
- Confirm .env is git-ignored and only .env.example is tracked.

## Constraints
- Config loading must fail fast with a clear error if a required variable is missing.

## Acceptance Criteria
- [ ] Backend boots locally using only infra/.env values and panics with a readable message if one is removed.
