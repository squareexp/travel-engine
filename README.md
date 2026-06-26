# Twende Travel Engine

Twende Travel Engine is the Rust backend for the travel marketplace. This repository is now treated as the server source of truth, with deployment, database, and API contract work living here.

## Repository layout

- `server/` - Rust/Axum API and SQLx migrations.
- `deploy/` - VPS deployment helpers and Nginx configs.
- `infra/` - local service stack and developer tooling.
- `shared/api-contracts/` - OpenAPI contract for the backend API.
- `docs/` - backend conventions, operational guidance, and deployment notes.
- `prompts/` - archived build prompts and planning notes.

Frontend app work is intentionally out of scope for this repository.

Read [the domain glossary](docs/skills/domain-glossary.md), [API conventions](docs/skills/api-conventions.md), and [database conventions](docs/skills/db-conventions.md) before changing product behavior.

## Local services

```sh
cp infra/.env.example infra/.env
make up
```

This starts PostgreSQL, Redis, and MinIO for the backend. See [local development](docs/local-development.md) for application configuration and commands.
