# Twende Zanzibar — Product Overview

## What it is

Twende Zanzibar is a tourism marketplace app connecting travelers to verified experiences across Zanzibar and the Tanzania mainland — discovery, booking, payment, and post-booking support in one platform, instead of the fragmented mix of social media, WhatsApp, hotel desks, and scattered websites travelers currently piece together.

The client's investor deck frames the opportunity around real, growing demand: Tanzania logged 2.14M international arrivals and $3.90B in tourism earnings in 2024, with Zanzibar alone drawing 736,755 arrivals (+15.4% year over year), 98.3% of them leisure travelers. The product bet is that this demand is strong but the *booking layer* underneath it is missing — operators lack professional storefronts and payment workflows, and Zanzibar/mainland experiences are sold as disconnected pieces instead of one journey.

## The five product modules

These are the actual building blocks of the app, as defined for this build (they map onto, but are more specific than, the deck's generic "tours" concept):

| Module | What it is | Key property |
|---|---|---|
| **Sites** | A single, one-way bookable location — pay to go and experience it. | Optionally bundles transport; traveler supplies location, group size, etc. at booking. |
| **Experiences** | An enhanced activity layer on top of Sites — water bikes, skydiving, "A Day at Stone Town." | Can chain two or more Sites into one themed activity. |
| **Trips** | A full itinerary combining Sites, Experiences, Safari, and Transport with dates and group size. | The composite, multi-day product — effectively a packaged journey. |
| **Safari** | Wild-environment adventures with their own schema. | Carries fields the others don't need: park, game-drive window, vehicle class, park fees (itemized separately from the service price). |
| **Transport** | An already-built, production transport backend (point A → point B, choose a car). | Integrated via API as a service dependency — never rebuilt inside this app. |

This split matters for the data model: rather than one flat "tours" table, the system needs a shared `listings` identity (so search, availability, and bookings work uniformly) plus type-specific extension tables for each module's unique fields and rules. The 50-prompt build plan implements exactly this (see `prompts/07_*` for the full ERD).

## Customer journey

1. **Discover** — SEO, social content, hotel QR codes, airport transfer demand bring travelers in.
2. **Compare** — ratings, inclusions, price, availability, and operator verification status help them choose.
3. **Book & pay** — commission revenue is generated here, across tours, stays, and transfers.
4. **Experience** — itinerary, support, notifications, and upsell offers during the trip.
5. **Review** — ratings feed back into trust and future discovery.

## Who uses it

- **Travelers** — discover, book, pay, and manage their itinerary from the mobile app.
- **Operators** — local guides and tour businesses get a verified storefront, availability calendar, bookings inbox, and review responses through an operator portal.
- **Admins** — the founder's team verifies operators, moderates listings and reviews, manages refunds, and watches KPIs from a dashboard.
- **The existing Transport backend** — a separate, already-shipped system this app calls into for point-to-point rides; not a user-facing module in itself.

## Business model

Revenue centers on verified local travel demand, per the deck's plan:
- **Booking commission**: 12–18% on tours, transfers, and package bookings.
- **Featured listings**: paid visibility for verified hotels and operators.
- **Premium packages**: bundled Zanzibar + Serengeti/Kilimanjaro itineraries (i.e., Trips combining Safari).
- **B2B dashboard**: operator tools for bookings, availability, and analytics.
- **Payment services**: optional settlement, invoice, and refund support fees.

Initial commercial focus is Zanzibar high-frequency experiences, airport transfers, and mainland safari cross-sell. The deck's own illustrative Year 1 model — $720K GMV, $86K commission revenue at a 12% blended rate, 6,000 bookings, $120 AOV — should be treated as a planning assumption to validate in pilot, not a target baked into the product.

## MVP scope vs. later scope

The deck's own roadmap (and the 50-prompt build plan) target:

- **0–3 months — MVP build**: Rust backend, PostgreSQL schema, mobile app, admin dashboard, seeded content. This is what `prompts/01`–`50` deliver.
- **3–6 months — Zanzibar pilot**: onboard real operators, transfers, Stone Town tours, beach activities, hotel partners. Covered by `prompts/50`'s pilot rollout plan.
- **6–12 months — Mainland expansion**: Serengeti, Kilimanjaro, Ngorongoro, Dar transfer routes, package bundling — the schema already supports this from day one (destinations and Safari are built in, not bolted on later).
- **12+ months — Scale**: automated partner tools, analytics monetization, loyalty, B2B travel integrations — intentionally out of scope for the MVP prompts.

## What makes this defensible

The deck's core thesis is that the missing layer in Tanzanian tourism isn't demand — it's *trusted booking infrastructure*: a place where supply (operators), payments, and data all live together. The product's job is to be the layer that makes a Zanzibar beach day and a Serengeti safari feel like one trustworthy, bookable journey instead of two separate gambles.
