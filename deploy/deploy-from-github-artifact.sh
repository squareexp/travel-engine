#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?GitHub Actions run id is required}"
artifact_dir="$(mktemp -d)"
trap 'rm -rf "$artifact_dir"' EXIT

: "${GH_TOKEN:?Set GH_TOKEN to a token with Actions read access}"
api_base="https://api.github.com/repos/squareexp/travel-engine/actions/runs"
headers=(-H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json")

run_json="$(curl --fail --silent --show-error "${headers[@]}" "$api_base/$run_id")"
image_tag="${2:-$(printf '%s' "$run_json" | python3 -c 'import json, sys; print(json.load(sys.stdin)["head_sha"])')}"
artifacts_json="$(curl --fail --silent --show-error "${headers[@]}" "$api_base/$run_id/artifacts")"
artifact_url="$(printf '%s' "$artifacts_json" | python3 -c '
import json
import sys

for artifact in json.load(sys.stdin)["artifacts"]:
    if artifact["name"] == "travel-engine-api-linux-amd64":
        print(artifact["archive_download_url"])
        break
else:
    raise SystemExit("release image artifact was not found")
')"

curl --fail --silent --show-error --location "${headers[@]}" "$artifact_url" --output "$artifact_dir/image.zip"
unzip -q "$artifact_dir/image.zip" -d "$artifact_dir"

IMAGE_ARCHIVE="$artifact_dir/travel-engine-api.tar" \
  "$(dirname "$0")/deploy-api.sh" "$image_tag"
