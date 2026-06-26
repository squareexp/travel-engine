# Prompt 23: Safari Module API

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 14, 19

## Context
Wildlife logistics differ enough (vehicles, park fees, drive windows) to warrant dedicated endpoints.

## Task
- POST/GET/PATCH /api/v1/safaris including park_destination_id, game_drive_window, vehicle_class, park_fee.
- GET /api/v1/safaris with filters for park, vehicle_class, and date range (joins availability).

## Constraints
- park_fee must always be returned as a separate line item, never merged into base_price, per prompt 14's pricing-clarity rule.

## Acceptance Criteria
- [ ] A Serengeti safari search returns price broken into base_price + park_fee.
