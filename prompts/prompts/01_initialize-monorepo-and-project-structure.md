# Prompt 01: Initialize Monorepo & Project Structure

**Phase:** 0 — Foundations & Agent Skills  
**Depends on prompt(s):** None — first prompt

## Context
Set up the root repository that will hold the Rust backend, admin dashboard, iOS app, Android app, and shared API contract. Every later prompt assumes this layout exists.

## Task
- Create a monorepo with top-level folders: backend/ (Rust/Axum), admin-dashboard/ (Next.js), ios-app/ (SwiftUI), android-app/ (Flutter), shared/api-contracts/ (OpenAPI spec), infra/ (Docker, CI/CD), docs/.
- Add a root README.md that names the five product modules — Sites, Experiences, Trips, Safari, Transport — and one sentence each on what they are.
- State explicitly in the README that Transport is an existing, already-in-production backend that will be integrated via API, never rebuilt.
- Initialize git with a combined .gitignore covering Rust, Node, Swift/Xcode, and Flutter/Dart artifacts.

## Constraints
- Backend, mobile apps, and dashboard must stay independently buildable — the only thing they share is the OpenAPI contract, not compiled code.
- Do not write any business logic yet — this prompt is scaffolding only.

## Acceptance Criteria
- [ ] Folder tree matches the layout above and is committed.
- [ ] Root README correctly distinguishes the 5 modules and flags Transport as external.
