# Prompt 20: Destinations & Sites API

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 10, 11, 19

## Context
The simplest listing type goes first end-to-end before tackling composite types.

## Task
- GET /api/v1/destinations (list/search).
- POST/GET/PATCH /api/v1/sites (operator-owned CRUD) and GET /api/v1/sites (public search by destination, price range, transport_eligible).

## Constraints
- Public list endpoints only ever return status='published' listings.

## Acceptance Criteria
- [ ] A verified operator can create, publish, and search for a Site; an unauthenticated traveler can browse published Sites only.
