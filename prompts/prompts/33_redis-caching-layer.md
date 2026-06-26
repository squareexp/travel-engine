# Prompt 33: Redis Caching Layer

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 16, 20, 30

## Context
Performance and rate-limiting groundwork called out explicitly in the deck (slide 11, slide 12).

## Task
- Cache popular destination/listing search results in Redis with a short TTL and explicit invalidation on listing update.
- Implement rate limiting middleware (per-IP and per-user) on auth and booking endpoints using Redis.
- Use Redis for refresh-token/session storage if not already covered by prompt 17.

## Constraints
- Cache must never be the source of truth for availability/capacity — those reads always hit Postgres directly.

## Acceptance Criteria
- [ ] Repeated identical search requests show measurably lower latency on cache hit; a brute-force login attempt is rate-limited.
