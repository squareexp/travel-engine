# Prompt 47: Cross-Platform Contract Sync & Versioning

**Phase:** 5 — Mobile Apps  
**Depends on prompt(s):** 40, 44

## Context
With two independent native codebases hitting one API, drift is the biggest long-term risk. This prompt locks in the discipline to prevent it.

## Task
- Add a CI check that regenerates both the iOS and Android API client code from shared/api-contracts/openapi.yaml and fails the build if generated output differs from what's committed (catches contract drift immediately).
- Adopt /api/v1/ now and document in docs/api-conventions.md how a breaking change becomes /api/v2/ without forcing simultaneous app store releases.
- Add a short docs/mobile-parity-checklist.md that every new feature must update for both iOS and Android before being marked done.

## Constraints
- This is process/tooling, not a feature — no new user-facing screens here.

## Acceptance Criteria
- [ ] Deliberately editing openapi.yaml and not regenerating clients fails CI on both mobile workflow stubs from prompt 04.
