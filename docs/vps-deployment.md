# VPS API deployment

The VPS never compiles Rust. GitHub Actions validates the server and publishes a Linux/amd64 image to `ghcr.io/squareexp/travel-engine` tagged with both `latest` and the immutable commit SHA.

The VPS runtime is `/home/apps/sq/travel-engine/deploy/`. It contains only `docker-compose.vps.yml`, the executable `deploy-api.sh`, and a mode-600 `.env`. The API binds solely to `127.0.0.1:18090`; Nginx is the only public entry point.

Deploy a tested image:

```sh
cd /home/apps/sq/travel-engine/deploy
./deploy-api.sh <commit-sha>
```

Rollback uses the previous image SHA with the same command. The container resolves host services through `host.docker.internal`; production `PISTONI_API_URL` and `REDIS_URL` must use that hostname rather than `localhost`.

DNS for `api.traverengine.zhio.dev` must be a DNS-only A record to the VPS IPv4 address. Do not add an AAAA record until the VPS Nginx site is intentionally configured for IPv6. That keeps Certbot's HTTP-01 validation on the known-good IPv4 path.
