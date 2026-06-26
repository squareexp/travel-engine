# Prompt 31: Search & Filtering

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 20, 21, 22, 23

## Context
Lets travelers actually find things across all four sellable module types from one search box.

## Task
- Add a Postgres trigram (pg_trgm) index across listings.title/description for fuzzy text search.
- GET /api/v1/search?q=&type=&destination_id=&price_min=&price_max= returning a unified, ranked result list spanning sites/experiences/trips/safaris.
- Document a future swap path to Meilisearch/Typesense in docs/erd.md if search volume grows past what Postgres trigram comfortably handles.

## Constraints
- Search must only return status='published' listings from verified operators.

## Acceptance Criteria
- [ ] Searching 'stone town' returns matching Sites, Experiences, and Trips ranked by relevance.
