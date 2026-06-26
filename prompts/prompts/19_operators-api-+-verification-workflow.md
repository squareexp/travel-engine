# Prompt 19: Operators API + Verification Workflow

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 09, 17, 18

## Context
Turns the operators schema into a real onboarding flow, closing the deck's 'operator problem.'

## Task
- POST /api/v1/operators (operator applies, status defaults to 'pending').
- POST /api/v1/operators/:id/documents (upload to object storage, store key in operator_documents).
- Admin-only PATCH /api/v1/operators/:id/verify to flip status to verified/rejected.
- Enforce in the domain layer: a listing cannot be set to status='published' unless its operator is verified.

## Constraints
- Object storage upload uses the MinIO/S3 client configured in prompt 03/05.

## Acceptance Criteria
- [ ] An unverified operator's listing publish attempt is rejected with a clear error; after admin verification it succeeds.
