# Prompt remediation plan

This plan records the verified state of the existing implementation and the remaining work from prompts 01-50. It is intentionally staged so operational foundations and marketplace correctness land before additional user interfaces.

## Phase 0: foundations (prompts 01-07)

The shared documentation, local Docker services, secret-handling policy, OpenAPI contract, CI workflow skeletons, and ERD are now in place. The existing `server/`, Flutter client, and SwiftUI client remain in place; moving them to the original empty-repo names would create churn without improving build isolation.

## Phase 1: harden the existing backend (prompts 08-29)

The database schema, auth, operators, destinations, listing types, availability, bookings, payments, reviews, and external Transport adapter already exist. Remaining work is to make the configuration strict and typed, validate seed data, complete itinerary generation, prove no-oversell and rollback behavior with integration tests, and reconcile endpoint behavior with the contract.

## Phase 2: missing marketplace infrastructure (prompts 30-34)

Add Google Maps geocoding/routing behind an adapter; durable notification delivery for email, FCM, and WhatsApp; Redis-backed caching/rate limiting; and an analytics event pipeline. Each must have configuration, failure handling, and test doubles.

## Phase 3: operations surfaces (prompts 35-39)

Build a Next.js admin dashboard and operator portal from the OpenAPI contract, then wire real verification, listing moderation, refunds/audit logs, and KPI views. These do not currently exist as independent applications.

## Phase 4: mobile and release readiness (prompts 40-50)

Complete map and notification features in Flutter and SwiftUI, add generated-client contract-drift verification, build backend/database/E2E coverage, add privacy-safe observability and backup drills, then use the launch and Zanzibar pilot documents as evidence-based go/no-go gates.
