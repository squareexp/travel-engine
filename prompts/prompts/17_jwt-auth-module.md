# Prompt 17: JWT Auth Module

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 08, 16

## Context
Every later endpoint needs to know who's calling and with what role.

## Task
- Implement POST /api/v1/auth/register and /login (traveler + operator signup, admin created via seed only).
- Issue short-lived access JWTs + longer-lived refresh tokens; add POST /auth/refresh.
- Add an Axum extractor that validates the JWT and injects the authenticated user + role into handlers.
- Add a role-guard middleware usable as `require_role(Role::Admin)` etc.

## Constraints
- Passwords hashed with argon2; never log raw passwords or tokens.

## Acceptance Criteria
- [ ] A traveler can register, login, hit a protected test route with the access token, and get 401 without it.
