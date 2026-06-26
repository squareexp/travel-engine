# Prompt 12: Experience Extension + experience_sites Join

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 11

## Context
Experiences enhance one or more Sites into a themed activity (water bikes, skydiving, a full Stone Town day).

## Task
- Migration: `experience_details` (listing_id PK/FK -> listings, category enum['adventure','cultural','water','wildlife_adjacent'], min_group_size, max_group_size).
- Migration: `experience_sites` (experience_listing_id FK, site_listing_id FK, sequence_order) allowing an Experience to chain 2+ Sites in order.

## Constraints
- At least one row in experience_sites is required per experience at the application layer (document as a TODO for the service-layer prompt).

## Acceptance Criteria
- [ ] Can model 'A Day at Stone Town' as one Experience linking 3 Sites in sequence.
