# Prompt 02: Define Coding-Agent Skills for the Project

**Phase:** 0 — Foundations & Agent Skills  
**Depends on prompt(s):** 01

## Context
Before any code is written, capture the domain vocabulary and conventions in short reference docs so every future coding-agent session (and every human) uses consistent terms and patterns.

## Task
- Write docs/skills/domain-glossary.md defining: Site (single bookable location, one-way, optional transport add-on), Experience (an activity, can chain 2+ Sites, e.g. a Stone Town day or watersports), Trip (a full itinerary combining Sites + Experiences + Safari + Transport with dates and group size), Safari (wildlife-specific schema: parks, game-drive windows, vehicle class, park fees), Transport (external pre-built point-to-point backend, called via API only).
- Write docs/skills/api-conventions.md: REST resource naming, /api/v1/ versioning, pagination shape, standard error envelope, auth header format.
- Write docs/skills/db-conventions.md: snake_case tables, UUID primary keys, soft deletes via deleted_at, status as Postgres enums, append-only audit logging rule, migration file naming.

## Constraints
- Each skill file must fit in roughly two pages so it can be pasted whole into a coding-agent context window.
- Use the exact module definitions above everywhere downstream — do not redefine them differently later.

## Acceptance Criteria
- [ ] Three skill docs exist under docs/skills/.
- [ ] Root README links to them as required reading before backend work.
