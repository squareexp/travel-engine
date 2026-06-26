# Prompt 35: Admin Dashboard Scaffold

**Phase:** 4 — Admin Dashboard & Operator Portal  
**Depends on prompt(s):** 06, 17

## Context
Stand up the web app investors and the founder's team will actually look at, per deck slide 11's 'Admin Dashboard' box.

## Task
- Initialize admin-dashboard/ as a Next.js + TypeScript app, generate a typed API client from shared/api-contracts/openapi.yaml.
- Implement login against the backend's JWT auth, with role-based route guards (admin vs operator views).
- Set up the base layout/navigation shell (no real data screens yet).

## Constraints
- Do not hand-write API call signatures — generate them from the OpenAPI contract so drift is impossible.

## Acceptance Criteria
- [ ] An admin user can log in and see an empty but role-correct dashboard shell; an operator sees a different, restricted shell.
