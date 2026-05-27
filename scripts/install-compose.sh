#!/usr/bin/env bash
# Instala Docker Compose v2 via binário oficial (Amazon Linux 2/2023 e derivados).
# Uso: sudo ./scripts/install-compose.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/ensure-docker.sh"

COMPOSE_VERSION="${COMPOSE_VERSION:-v2.32.4}"

arch="$(uname -m)"
case "$arch" in
  x86_64) compose_arch="x86_64" ;;
  aarch64 | arm64) compose_arch="aarch64" ;;
  *)
    echo "Arquitetura não suportada: $arch" >&2
    exit 1
    ;;
esac

# Tenta pacote do SO (ignora falha — AL2 muitas vezes não tem o plugin)
if command -v dnf >/dev/null 2>&1; then
  dnf install -y docker-compose-plugin 2>/dev/null || true
fi
if command -v yum >/dev/null 2>&1; then
  yum install -y docker-compose-plugin 2>/dev/null || true
fi

if docker compose version >/dev/null 2>&1; then
  echo "Compose já disponível: $(docker compose version)"
  exit 0
fi

PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"
BINARY_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${compose_arch}"

echo "Baixando Compose ${COMPOSE_VERSION} (${compose_arch})..."
mkdir -p "$PLUGIN_DIR"
curl -fsSL "$BINARY_URL" -o "$PLUGIN_DIR/docker-compose"
chmod +x "$PLUGIN_DIR/docker-compose"
ln -sf "$PLUGIN_DIR/docker-compose" /usr/local/bin/docker-compose

echo "Instalado:"
docker compose version
echo ""
echo "Suba a stack com:"
echo "  ./scripts/compose.sh -f docker-compose.prod.yml up -d --build"
