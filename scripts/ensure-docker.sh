#!/usr/bin/env bash
# Garante Docker instalado e daemon em execução (Amazon Linux 2/2023).
# Uso: sudo ./scripts/ensure-docker.sh
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Instalando Docker..."
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y docker
  elif command -v yum >/dev/null 2>&1; then
    yum install -y docker
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y docker.io
  else
    echo "Gerenciador de pacotes não suportado." >&2
    exit 1
  fi
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl enable docker
  if ! systemctl is-active --quiet docker; then
    echo "Iniciando docker.service..."
    systemctl start docker
    sleep 2
  fi
else
  service docker start || true
fi

if ! docker info >/dev/null 2>&1; then
  echo "Falha: daemon Docker inacessível em /var/run/docker.sock" >&2
  echo "Tente: systemctl status docker && journalctl -u docker -n 30" >&2
  exit 1
fi

echo "Docker OK: $(docker version --format '{{.Server.Version}}')"
