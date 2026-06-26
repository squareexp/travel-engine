# Prompt 44: Android App Architecture (Flutter)

**Phase:** 5 — Mobile Apps  
**Depends on prompt(s):** 06, 17

## Context
Native-feeling Android app per the founder's explicit choice of Flutter, sharing the same backend contract as iOS.

## Task
- Initialize android-app/ as a Flutter project using Riverpod (or Bloc) for state management and a Dart client generated/mirrored from shared/api-contracts/openapi.yaml.
- Set up secure token storage (flutter_secure_storage) with the same auto-refresh-on-401 behavior as iOS.
- Establish the same navigation shell (Discover, Trips, Bookings, Profile) so feature parity is structurally obvious.

## Constraints
- Module names, error envelope handling, and screen structure should mirror the iOS app from prompt 40 so the two codebases stay conceptually in lockstep even though they're different languages.

## Acceptance Criteria
- [ ] App builds and runs on an Android emulator with a working login screen hitting the same backend endpoint as iOS.
