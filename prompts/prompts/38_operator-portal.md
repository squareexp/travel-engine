# Prompt 38: Operator Portal

**Phase:** 4 — Admin Dashboard & Operator Portal  
**Depends on prompt(s):** 20, 23, 25, 28, 35

## Context
Self-service tools for operators, per the deck's 'Operator Tools' box (slide 5, slide 11).

## Task
- Screen: operator's own listings with create/edit forms for Sites, Experiences (site picker), Safaris.
- Screen: availability calendar editor (set capacity per date) wired to the availability table.
- Screen: bookings inbox for the operator's listings and a simple reply-to-review flow.

## Constraints
- An operator can only ever see/edit their own listings and bookings — enforce at the API layer, not just hidden in the UI.

## Acceptance Criteria
- [ ] Operator A cannot view or edit Operator B's listings even by guessing IDs in the network tab.
