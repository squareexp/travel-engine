# Local development

Copy `infra/.env.example` to `infra/.env` and run `make up` to start PostgreSQL 16, Redis 7, and MinIO. `make down`, `make logs`, and `make psql` manage the same stack.

For the Rust API, copy only the required local values into `server/.env`; never copy a staging or production environment file into the repository. The server uses `DIRECT_URL` for migrations and database pooling, which should point directly to PostgreSQL rather than through a transaction pooler.

This repository now focuses on the Rust backend only. Any frontend or mobile app work belongs in separate repositories and is not part of the local backend workflow here.
