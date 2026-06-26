# Twende Zanzibar

Twende is a tourism marketplace for discovering, booking, and managing verified experiences across Zanzibar and Tanzania.

## Product modules

- **Sites** are single, one-way bookable locations, with optional transport.
- **Experiences** are themed activities that can combine two or more Sites.
- **Trips** are multi-day itineraries combining Sites, Experiences, Safari, and Transport.
- **Safari** is a wildlife product with park, game-drive, vehicle, and park-fee details.
- **Transport** is an existing, production backend integrated through its API. It is never rebuilt here.

## Repository layout

The existing projects remain independently buildable:

- `server/` - Rust/Axum API and SQLx migrations.
- `client/` - Flutter traveler app.
- `client/TwendeZanzabar/` - SwiftUI traveler app.
- `shared/api-contracts/` - OpenAPI contract shared by every client.
- `infra/` - local service stack and developer tooling.
- `docs/` - architecture, conventions, operational guidance, and delivery plan.

Read [the domain glossary](docs/skills/domain-glossary.md), [API conventions](docs/skills/api-conventions.md), and [database conventions](docs/skills/db-conventions.md) before changing product behavior.

## Local services

```sh
cp infra/.env.example infra/.env
make up
```

This starts PostgreSQL, Redis, and MinIO. See [local development](docs/local-development.md) for application configuration and commands.
