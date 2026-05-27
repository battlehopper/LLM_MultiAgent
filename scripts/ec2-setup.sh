#!/usr/bin/env bash
# Bootstrap inicial em Amazon Linux 2/2023 / EC2 (Docker + Compose + clone opcional).
# Uso: ./scripts/ec2-setup.sh   (ou sudo ./scripts/ec2-setup.sh)
set -euo pipefail

REPO_URL="${REPO_URL:-}"
# Ex.: INSTALL_DIR=/opt/llmagent ./scripts/ec2-setup.sh
INSTALL_DIR="${INSTALL_DIR:-$HOME/LLM_MultiAgent}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_docker_amazon_linux() {
  if command -v dnf >/dev/null 2>&1; then
    as_root dnf update -y
    as_root dnf install -y docker git curl
  else
    as_root yum update -y
    as_root yum install -y docker git curl
  fi
  as_root systemctl enable --now docker
  if [ "$(id -u)" -ne 0 ]; then
    as_root usermod -aG docker "$USER"
    echo "Reconecte o SSH para usar Docker sem sudo (se não for root)."
  fi
}

install_docker_ubuntu() {
  as_root apt-get update -y
  as_root apt-get install -y docker.io docker-compose-v2 git curl
  as_root systemctl enable --now docker
  if [ "$(id -u)" -ne 0 ]; then
    as_root usermod -aG docker "$USER"
    echo "Reconecte o SSH para usar Docker sem sudo (se não for root)."
  fi
}

if [ -f /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  if ! command -v docker >/dev/null 2>&1; then
    case "${ID:-}" in
      amzn) install_docker_amazon_linux ;;
      ubuntu) install_docker_ubuntu ;;
      *) echo "SO não reconhecido ($ID). Instale Docker manualmente." ;;
    esac
  fi
fi

as_root bash "$SCRIPT_DIR/install-compose.sh"

if [ -n "$REPO_URL" ] && [ ! -d "$INSTALL_DIR/.git" ]; then
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

if [ -d "$INSTALL_DIR" ]; then
  cd "$INSTALL_DIR"
  chmod +x scripts/compose.sh scripts/install-compose.sh scripts/run_gateway.sh scripts/run_processor.sh 2>/dev/null || true
  if [ ! -f .env ] && [ -f deploy/.env.ec2.example ]; then
    cp deploy/.env.ec2.example .env
    echo "Criado $INSTALL_DIR/.env — edite DD_API_KEY antes do compose up."
  fi
  echo ""
  echo "Próximo passo:"
  echo "  cd $INSTALL_DIR && nano .env"
  echo "  ./scripts/compose.sh -f docker-compose.prod.yml up -d --build"
fi
