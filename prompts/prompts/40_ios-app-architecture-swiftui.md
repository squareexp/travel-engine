# Prompt 40: iOS App Architecture (SwiftUI)

**Phase:** 5 — Mobile Apps  
**Depends on prompt(s):** 06, 17

## Context
Native iOS app per the founder's explicit choice of SwiftUI.

## Task
- Initialize ios-app/ as a SwiftUI project using MVVM, async/await for networking, and a code-generated (or hand-mirrored) client from shared/api-contracts/openapi.yaml.
- Set up secure token storage (Keychain) for JWT access/refresh tokens with auto-refresh on 401.
- Establish the app's navigation shell (tab bar: Discover, Trips, Bookings, Profile).

## Constraints
- Networking layer must be a thin, testable layer separate from Views — no URLSession calls inside SwiftUI Views directly.

## Acceptance Criteria
- [ ] App builds and runs in the simulator with a working login screen hitting the real backend's /auth/login.
