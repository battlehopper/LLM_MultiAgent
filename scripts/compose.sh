#!/usr/bin/env bash
# Wrapper: "docker compose" (v2) ou "docker-compose" (v1 legado).
set -euo pipefail

if docker compose version >/dev/null 2>&1; then
  exec docker compose "$@"
fi

if command -v docker-compose >/dev/null 2>&1; then
  exec docker-compose "$@"
fi

echo "Docker Compose não encontrado." >&2
echo "Execute na EC2: sudo ./scripts/install-compose.sh" >&2
exit 1
