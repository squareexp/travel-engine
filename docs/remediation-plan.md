# Prompt remediation plan

This plan records the verified state of the server work. The repository has been narrowed to the Rust backend, so the remaining scope is backend, deployment, and operational hardening.

## Phase 0: foundations (prompts 01-07)

The shared documentation, local Docker services, secret-handling policy, OpenAPI contract, CI workflow skeletons, and ERD are now in place.

## Phase 1: harden the existing backend (prompts 08-29)

The database schema, auth, operators, destinations, listing types, availability, bookings, payments, reviews, and external Transport adapter already exist. Remaining work is to make the configuration strict and typed, validate seed data, complete itinerary generation, prove no-oversell and rollback behavior with integration tests, and reconcile endpoint behavior with the contract.

## Phase 2: missing marketplace infrastructure (prompts 30-34)

Add Google Maps geocoding/routing behind an adapter; durable notification delivery for email, FCM, and WhatsApp; Redis-backed caching/rate limiting; and an analytics event pipeline. Each must have configuration, failure handling, and test doubles.

## Out of repo

The original prompt set also included admin, iOS, and Android work. Those frontend surfaces are now treated as separate efforts and are not part of this backend repository.
