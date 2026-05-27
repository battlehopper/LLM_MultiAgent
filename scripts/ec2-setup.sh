#!/usr/bin/env bash
# Bootstrap inicial em Amazon Linux 2023 / EC2 (Docker + clone opcional).
# Uso: curl -fsSL ... | bash   OU   ./scripts/ec2-setup.sh
set -euo pipefail

REPO_URL="${REPO_URL:-}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/LLM_MultiAgent}"

install_docker_amazon_linux() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker já instalado."
    return
  fi
  sudo dnf update -y
  sudo dnf install -y docker git
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo "Reconecte o SSH para usar Docker sem sudo."
}

install_docker_ubuntu() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker já instalado."
    return
  fi
  sudo apt-get update -y
  sudo apt-get install -y docker.io docker-compose-v2 git
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo "Reconecte o SSH para usar Docker sem sudo."
}

if [ -f /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  case "${ID:-}" in
    amzn) install_docker_amazon_linux ;;
    ubuntu) install_docker_ubuntu ;;
    *) echo "SO não reconhecido ($ID). Instale Docker manualmente." ;;
  esac
fi

if [ -n "$REPO_URL" ] && [ ! -d "$INSTALL_DIR/.git" ]; then
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

if [ -d "$INSTALL_DIR" ]; then
  cd "$INSTALL_DIR"
  if [ ! -f .env ] && [ -f deploy/.env.ec2.example ]; then
    cp deploy/.env.ec2.example .env
    echo "Criado $INSTALL_DIR/.env — edite DD_API_KEY antes do compose up."
  fi
  echo "Próximo passo:"
  echo "  cd $INSTALL_DIR && nano .env"
  echo "  docker compose -f docker-compose.prod.yml up -d --build"
fi
