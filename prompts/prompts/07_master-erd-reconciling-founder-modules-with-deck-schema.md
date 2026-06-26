# Prompt 07: Master ERD Reconciling Founder Modules with Deck Schema

**Phase:** 1 — Database Foundation  
**Depends on prompt(s):** 02, 06

## Context
The investor deck's database (slides 9–10) uses one generic 'tours' table. The founder's actual product splits that into Sites, Experiences, Trips, and Safari, with Transport external. This prompt produces the real ERD before any migration is written.

## Task
- Design a shared base table `listings` (id, operator_id, destination_id, type enum['site','experience','trip','safari'], title, description, base_price, status, timestamps) so search, availability, and bookings can reference one parent id regardless of type.
- Design type-specific extension tables: site_details, experience_details (+ experience_sites join table for the 'combine two sites' rule), trip_details (+ trip_items ordered list referencing any listing or a transport leg), safari_details (park, game_drive_window, vehicle_class, park_fee_amount).
- Show how `transport` is NOT a listings type but a referenced external booking (transport_legs table storing the external backend's booking reference, points, fare) attachable to a Site, Experience, or Trip.
- Document the ERD as docs/erd.md with a diagram description and the rationale for class-table-inheritance over one flat table.

## Constraints
- Every extension table's primary key is also a foreign key to listings.id (shared PK pattern).

## Acceptance Criteria
- [ ] docs/erd.md exists and an engineer unfamiliar with the project can explain how a Trip references two Sites and one Transport leg from reading it.
