#!/usr/bin/env bash
# Sobe os agentes em background (detach) e libera o terminal.
set -euo pipefail
cd "$(dirname "$0")/.."

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

./scripts/ensure-docker.sh
./scripts/compose.sh -f "$COMPOSE_FILE" up -d --build

echo ""
echo "Containers em execução (detached). Terminal liberado."
echo ""
./scripts/compose.sh -f "$COMPOSE_FILE" ps
echo ""
echo "Comandos úteis:"
echo "  Logs gateway:  ./scripts/compose.sh -f $COMPOSE_FILE logs -f retail-gateway"
echo "  Logs todos:    ./scripts/compose.sh -f $COMPOSE_FILE logs -f"
echo "  Parar:         ./scripts/compose.sh -f $COMPOSE_FILE down"
echo "  Reiniciar:     ./scripts/compose.sh -f $COMPOSE_FILE restart"
