# Prompt 14: Safari Extension

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 11

## Context
Safari needs fields that don't apply to beach Sites or city Experiences — park logistics, vehicles, fees.

## Task
- Migration: `safari_details` (listing_id PK/FK -> listings, park_destination_id FK -> destinations, game_drive_window enum['morning','afternoon','full_day','overnight'], vehicle_class enum['shared_4x4','private_4x4','luxury'], park_fee_amount, park_fee_currency).

## Constraints
- park_fee_amount is stored separately from base_price so it can be itemized at checkout per deck's 'clear price, availability, guests, receipts' principle (slide 5).

## Acceptance Criteria
- [ ] A Serengeti safari listing stores park fees distinctly from the operator's service price.
