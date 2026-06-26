# Prompt 24: Transport Integration Adapter

**Phase:** 2 — Rust Backend Core  
**Depends on prompt(s):** 16, 17

## Context
Transport already exists as a working production app/backend. This module is an HTTP client and translation layer, not a rebuild.

## Task
- Define a TransportClient trait in the domain crate with methods like quote_fare(origin, destination), book_ride(...), get_ride_status(ride_id).
- Implement it against the existing transport backend's real API (config-driven base URL + auth token).
- Migration: `transport_legs` (id PK, external_ride_id, origin_lat/lng, destination_lat/lng, fare_amount, status, linked_booking_id nullable).
- Add a mock/test implementation of TransportClient for integration tests so the suite doesn't depend on the live external service.

## Constraints
- Never duplicate routing or fare logic that already lives in the external transport backend — always call out to it.

## Acceptance Criteria
- [ ] Backend can fetch a fare quote and create a ride through the adapter against a mocked transport API in tests.
