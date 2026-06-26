# Prompt 36: Admin: Operators & Listings Management

**Phase:** 4 — Admin Dashboard & Operator Portal  
**Depends on prompt(s):** 19, 20, 21, 22, 23, 35

## Context
Gives the founder's team the verification and content-moderation tools the deck calls 'operator problem' infrastructure (slide 4).

## Task
- Screen: operator applications queue with document review and verify/reject actions.
- Screen: unified listings table across Sites/Experiences/Trips/Safari with publish/suspend actions and filters by type/destination/status.

## Constraints
- Every state-changing action here must hit the audited backend endpoints from prompt 19 — no direct DB writes from the dashboard.

## Acceptance Criteria
- [ ] An admin can verify a pending operator and publish their first Site listing end-to-end through the UI.
