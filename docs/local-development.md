# Local development

Copy `infra/.env.example` to `infra/.env` and run `make up` to start PostgreSQL 16, Redis 7, and MinIO. `make down`, `make logs`, and `make psql` manage the same stack.

For the Rust API, copy only the required local values into `server/.env`; never copy a staging or production environment file into the repository. The server uses `DIRECT_URL` for migrations and database pooling, which should point directly to PostgreSQL rather than through a transaction pooler.

The Flutter app lives in `client/`. The SwiftUI project lives in `client/TwendeZanzabar/`. Both consume versioned `/api/v1/` endpoints and must follow the shared contract in `shared/api-contracts/openapi.yaml`.
