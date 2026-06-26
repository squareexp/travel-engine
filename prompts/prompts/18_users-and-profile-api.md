# Prompt 18: Users & Profile API

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 17

## Context
Basic self-service profile management for travelers and operators.

## Task
- GET/PATCH /api/v1/users/me.
- Validation: phone format, email format, partial update support.

## Constraints
- Users can only ever modify their own record at this layer; admin override is a separate endpoint added in prompt 36.

## Acceptance Criteria
- [ ] Authenticated user can fetch and update their own profile; cannot fetch another user's profile.
