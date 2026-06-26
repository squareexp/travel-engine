# Prompt 41: iOS: Auth & Onboarding

**Phase:** 5 — Mobile Apps  
**Depends on prompt(s):** 40

## Context
First real screens a traveler sees.

## Task
- Build register/login screens, optional Sign in with Apple, and a short onboarding carousel introducing Sites/Experiences/Trips/Safari.
- Handle and surface backend validation errors using the standard error envelope from docs/skills/api-conventions.md.

## Constraints
- Form validation client-side must mirror backend validation rules to avoid confusing round-trip errors.

## Acceptance Criteria
- [ ] A new user can register, get auto-logged-in, and land on the Discover tab.
