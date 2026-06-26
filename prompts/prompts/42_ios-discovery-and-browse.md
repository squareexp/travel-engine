# Prompt 42: iOS: Discovery & Browse

**Phase:** 5 — Mobile Apps  
**Depends on prompt(s):** 20, 21, 22, 23, 31, 41

## Context
The core browsing experience across all four sellable modules.

## Task
- Build the Discover screen calling GET /api/v1/search with destination/type filters.
- Build listing detail screens for Site, Experience (showing the chained sites), Trip (showing the day-by-day itinerary preview), and Safari (showing park fee breakdown).

## Constraints
- Reuse one underlying card/list component across module types rather than four bespoke implementations.

## Acceptance Criteria
- [ ] A traveler can search 'Zanzibar', filter to Experiences, and open a detail screen showing chained sites and total travel time from prompt 30's data.
