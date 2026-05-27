#!/usr/bin/env bash
# Bootstrap inicial em Amazon Linux 2023 / EC2 (Docker + Compose + clone opcional).
# Uso: ./scripts/ec2-setup.sh
set -euo pipefail

REPO_URL="${REPO_URL:-}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/LLM_MultiAgent}"

ensure_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose v2 OK: $(docker compose version)"
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose v1 OK: $(docker-compose --version)"
    return
  fi
  echo "Instalando Docker Compose plugin..."
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y docker-compose-plugin
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y docker-compose-v2
  else
    echo "Instale manualmente: docker-compose-plugin (dnf) ou docker-compose-v2 (apt)" >&2
    exit 1
  fi
  docker compose version
}

install_docker_amazon_linux() {
  sudo dnf update -y
  sudo dnf install -y docker docker-compose-plugin git
  sudo systemctl enable --now docker
  if [ "$(id -u)" -ne 0 ]; then
    sudo usermod -aG docker "$USER"
    echo "Reconecte o SSH para usar Docker sem sudo (se não for root)."
  fi
}

install_docker_ubuntu() {
  sudo apt-get update -y
  sudo apt-get install -y docker.io docker-compose-v2 git
  sudo systemctl enable --now docker
  if [ "$(id -u)" -ne 0 ]; then
    sudo usermod -aG docker "$USER"
    echo "Reconecte o SSH para usar Docker sem sudo (se não for root)."
  fi
}

if [ -f /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  case "${ID:-}" in
    amzn)
      if ! command -v docker >/dev/null 2>&1; then
        install_docker_amazon_linux
      else
        ensure_compose
      fi
      ;;
    ubuntu)
      if ! command -v docker >/dev/null 2>&1; then
        install_docker_ubuntu
      else
        ensure_compose
      fi
      ;;
    *) echo "SO não reconhecido ($ID). Instale Docker + Compose manualmente." ;;
  esac
fi

ensure_compose

if [ -n "$REPO_URL" ] && [ ! -d "$INSTALL_DIR/.git" ]; then
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

if [ -d "$INSTALL_DIR" ]; then
  cd "$INSTALL_DIR"
  chmod +x scripts/compose.sh scripts/run_gateway.sh scripts/run_processor.sh 2>/dev/null || true
  if [ ! -f .env ] && [ -f deploy/.env.ec2.example ]; then
    cp deploy/.env.ec2.example .env
    echo "Criado $INSTALL_DIR/.env — edite DD_API_KEY antes do compose up."
  fi
  echo ""
  echo "Próximo passo:"
  echo "  cd $INSTALL_DIR && nano .env"
  echo "  ./scripts/compose.sh -f docker-compose.prod.yml up -d --build"
fi
