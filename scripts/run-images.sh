#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

docker compose -f docker-compose.images.yml pull
docker compose -f docker-compose.images.yml up -d
