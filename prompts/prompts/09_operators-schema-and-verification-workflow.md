# Prompt 09: Operators Schema & Verification Workflow

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 08

## Context
Local guides and tour businesses need a verifiable storefront identity before they can publish listings (deck slide 4, 'operator problem').

## Task
- Migration: `operators` (id PK, owner_user_id FK -> users, legal_name, commission_rate numeric default 0.12–0.18 range per deck slide 8, verification_status enum['pending','verified','rejected'], created_at).
- Add a `operator_documents` table for verification artifacts (object storage keys, document_type, reviewed_by, reviewed_at).

## Constraints
- commission_rate must be constrained between 0 and 1 at the DB level.

## Acceptance Criteria
- [ ] A pending operator cannot be referenced by a published listing until verification_status = 'verified' (enforce in service layer prompt 19, but leave a documented TODO here).
