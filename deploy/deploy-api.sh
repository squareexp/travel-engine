#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
export IMAGE_TAG="${1:-${IMAGE_TAG:-latest}}"

docker compose -f docker-compose.vps.yml pull api
docker compose -f docker-compose.vps.yml up -d --no-build --remove-orphans api

for _ in $(seq 1 30); do
  if curl --fail --silent --show-error http://127.0.0.1:18090/healthz >/dev/null; then
    docker compose -f docker-compose.vps.yml ps
    exit 0
  fi
  sleep 2
done

docker compose -f docker-compose.vps.yml logs --tail=100 api >&2
exit 1
