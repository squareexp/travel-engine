# Prompt 30: Google Maps Integration

**Phase:** 3 — Payments, Search, Maps, Notifications  
**Depends on prompt(s):** 10, 11, 24

## Context
Implements the routing layer the founder specifically requested for the MVP.

## Task
- Add a GoogleMapsClient wrapping: Geocoding API (resolve destination/site addresses to lat/lng on creation), Directions API (route + ETA for transport legs and multi-site Experiences), Distance Matrix API (estimate transport fares as a sanity check against the external transport backend's quote).
- Cache geocoding results in Redis since destination/site coordinates rarely change.
- Surface a route_preview field on Experience and Trip GET responses showing total travel time between stops.

## Constraints
- Store the Google Maps API key only via the config/secrets strategy from prompt 05 — never hardcoded.

## Acceptance Criteria
- [ ] Creating a 3-site Experience returns an accurate total inter-site travel time sourced from the Directions API.
