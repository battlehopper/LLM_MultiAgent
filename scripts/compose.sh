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
echo "Amazon Linux: sudo dnf install -y docker-compose-plugin" >&2
echo "Ubuntu:       sudo apt install -y docker-compose-v2" >&2
exit 1
