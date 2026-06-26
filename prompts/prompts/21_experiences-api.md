# Prompt 21: Experiences API

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 12, 20

## Context
Implements the 'combine two sites into one enhanced activity' rule.

## Task
- POST/GET/PATCH /api/v1/experiences with a body that includes an ordered list of site_listing_ids to populate experience_sites.
- Validation: at least 1 site referenced, all referenced sites must belong to the same operator or be explicitly cross-operator-allowed (flag for future B2B partnerships).

## Constraints
- Reuse the Sites repository from prompt 20 rather than duplicating query logic.

## Acceptance Criteria
- [ ] Creating 'Stone Town Day' as an Experience over 3 existing Sites returns them in sequence order on GET.
