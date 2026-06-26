# VPS API deployment

The VPS never compiles Rust. GitHub Actions validates the server and produces a Linux/amd64 Docker image artifact for each release workflow run.

The VPS runtime is `/home/apps/sq/travel-engine/deploy/`. It contains only `docker-compose.vps.yml`, the executable `deploy-api.sh`, and a mode-600 `.env`. The container uses host networking solely to reach the VPS's local PostgreSQL and PgBouncer; `SERVER_HOST=127.0.0.1` ensures the API itself is not public. Nginx is the only public entry point.

Deploy a tested image artifact. The VPS downloads and loads Docker's already-built image; it does not build Rust or a Dockerfile:

```sh
cd /home/apps/sq/travel-engine/deploy
GH_TOKEN=<Actions-read-token> ./deploy-from-github-artifact.sh <run-id>
```

Rollback uses a previous successful workflow run ID with the same command. The script resolves the workflow commit SHA and runs that exact image tag. With host networking, production database and local-service URLs use `127.0.0.1` rather than a Docker bridge hostname.

DNS for `api.travelengine.zhio.dev` must be a DNS-only A record to the VPS IPv4 address. Do not add an AAAA record until the VPS Nginx site is intentionally configured for IPv6. That keeps Certbot's HTTP-01 validation on the known-good IPv4 path.
