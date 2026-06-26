# Travel Engine Server

This directory contains the Rust backend for the travel marketplace.

## Getting started

```bash
cp .env.example .env
cargo run
```

If the database is not initialized, run the SQLx migrations in `server/migrations/`.

## Scope

- Rust API handlers
- Database migrations
- Backend tests and tooling
- Deployment artifacts consumed by the VPS
