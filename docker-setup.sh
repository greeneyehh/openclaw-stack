#!/usr/bin/env bash
# OpenClaw Docker Stack – Build, Onboarding und Start
# Siehe https://docs.openclaw.ai/install/docker

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
IMAGE_NAME="${OPENCLAW_IMAGE:-openclaw:local}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Fehlende Abhängigkeit: $1" >&2
    exit 1
  fi
}

require_cmd docker
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 wird benötigt (z. B. docker compose version)" >&2
  exit 1
fi

# .env aus .env.example anlegen, falls nicht vorhanden
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f .env.example ]]; then
    cp .env.example "$ENV_FILE"
    echo "==> $ENV_FILE aus .env.example erstellt. Bitte anpassen."
  else
    echo "==> Bitte $ENV_FILE anlegen (siehe .env.example)." >&2
    exit 1
  fi
fi

# Variablen aus .env laden (Export für compose)
set -a
# shellcheck source=/dev/null
source "$ENV_FILE" 2>/dev/null || true
set +a

OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"

mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"

export OPENCLAW_CONFIG_DIR
export OPENCLAW_WORKSPACE_DIR
export OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
export OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
export OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
export OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-openclaw:local}"

if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  if command -v openssl >/dev/null 2>&1; then
    OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
  else
    OPENCLAW_GATEWAY_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  fi
  export OPENCLAW_GATEWAY_TOKEN
  # In .env zurückschreiben
  if grep -q '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" 2>/dev/null; then
    sed -i.bak "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN/" "$ENV_FILE"
  else
    echo "OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN" >> "$ENV_FILE"
  fi
fi

echo "==> Baue Docker-Image: $OPENCLAW_IMAGE"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}" \
  -t "$OPENCLAW_IMAGE" \
  -f Dockerfile \
  .

echo ""
echo "==> Onboarding (interaktiv)"
echo "Wenn gefragt:"
echo "  - Gateway bind: lan"
echo "  - Gateway auth: token"
echo "  - Gateway token: $OPENCLAW_GATEWAY_TOKEN"
echo "  - Tailscale: Off"
echo "  - Daemon installieren: Nein"
echo ""
docker compose run --rm openclaw-cli onboard --no-install-daemon

echo ""
echo "==> Starte Gateway"
docker compose up -d openclaw-gateway

echo ""
echo "Gateway läuft."
echo "  Control UI:  http://127.0.0.1:${OPENCLAW_GATEWAY_PORT}/"
echo "  Config:     $OPENCLAW_CONFIG_DIR"
echo "  Workspace:  $OPENCLAW_WORKSPACE_DIR"
echo "  Token:      $OPENCLAW_GATEWAY_TOKEN"
echo ""
echo "Nützliche Befehle:"
echo "  docker compose logs -f openclaw-gateway"
echo "  docker compose run --rm openclaw-cli status"
echo "  docker compose run --rm openclaw-cli pairing approve telegram <CODE>"
