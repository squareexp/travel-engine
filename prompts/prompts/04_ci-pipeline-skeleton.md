# Prompt 04: CI Pipeline Skeleton

**Phase:** 0 — Foundations & Agent Skills  
**Depends on prompt(s):** 01, 03

## Context
Establish automated checks early so every later prompt's output is verified the same way, matching the deck's 'all critical flows pass in CI' definition of done.

## Task
- Add .github/workflows/backend.yml: cargo fmt --check, cargo clippy, cargo test, on every push/PR touching backend/.
- Add .github/workflows/dashboard.yml: lint + build for admin-dashboard/.
- Add a placeholder job that will later run mobile builds (iOS/Android) once those projects exist.

## Constraints
- Pipelines should fail fast and run in under 5 minutes at this stage (empty/near-empty projects).

## Acceptance Criteria
- [ ] Both workflows run successfully on a trivial commit and show green checks.
