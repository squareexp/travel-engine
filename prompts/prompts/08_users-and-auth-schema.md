# Prompt 08: Users & Auth Schema

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 07

## Context
Implement the first real migration: identity and roles for travelers, operators, and admins, per deck slide 9.

## Task
- Write an SQLx migration creating `users` (id UUID PK, role enum['traveler','operator','admin'], email, phone, password_hash, created_at, deleted_at).
- Add unique constraints on email and phone (nullable-safe).
- Add seed data: one admin user for local dev.

## Constraints
- Follow docs/skills/db-conventions.md exactly (naming, soft delete, UUIDs).

## Acceptance Criteria
- [ ] Migration applies cleanly on a fresh database; rollback works; seed admin can be queried.
