# Prompt 03: Local Dev Environment with Docker Compose

**Phase:** 0 — Foundations & Agent Skills  
**Depends on prompt(s):** 01

## Context
Give every contributor (and every future prompt) a one-command local environment matching the planned production stack.

## Task
- Write infra/docker-compose.dev.yml with services: postgres:16, redis:7, and an S3-compatible object store emulator (MinIO) for tour images and receipts.
- Add infra/.env.example listing every variable the compose file and backend will need (DB url, Redis url, MinIO keys, JWT secret placeholder, Google Maps API key placeholder).
- Add a Makefile or justfile with `up`, `down`, `logs`, `psql` shortcuts.

## Constraints
- No production secrets in the repo — only placeholders in .env.example.

## Acceptance Criteria
- [ ] `docker compose -f infra/docker-compose.dev.yml up` brings up Postgres, Redis, and MinIO cleanly.
- [ ] .env.example covers every variable referenced anywhere in infra/.
