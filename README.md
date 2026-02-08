# OpenClaw Docker Stack

Docker-Compose-Setup für [OpenClaw](https://github.com/openclaw/openclaw) (persönlicher KI-Assistent). Der Stack baut das offizielle OpenClaw-Image aus dem GitHub-Repo und startet Gateway sowie CLI-Container.

## Voraussetzungen

- **Docker** (Desktop oder Engine) mit **Docker Compose v2**
- Node ≥22 wird im Image verwendet (nicht lokal nötig)

## Quick Start

```bash
# 1. .env anlegen (optional: Werte anpassen)
cp .env.example .env

# 2. Setup: Image bauen, Onboarding, Gateway starten
chmod +x docker-setup.sh
./docker-setup.sh
```

Beim ersten Lauf führt das Skript durch das Onboarding (Modell, Auth, Token). Anschließend:

- **Control UI:** http://127.0.0.1:18789/
- Token aus der Konsolenausgabe in der UI unter **Einstellungen → Token** eintragen.

## Manueller Ablauf

```bash
# Image bauen
docker build -t openclaw:local -f Dockerfile .

# .env setzen (OPENCLAW_CONFIG_DIR, OPENCLAW_WORKSPACE_DIR, OPENCLAW_GATEWAY_TOKEN)
cp .env.example .env
# OPENCLAW_GATEWAY_TOKEN z. B. mit: openssl rand -hex 32

# Onboarding (einmalig)
docker compose run --rm openclaw-cli onboard --no-install-daemon

# Gateway starten
docker compose up -d openclaw-gateway
```

## Verzeichnisse

| Host (Standard)        | Container              | Zweck                    |
|------------------------|------------------------|---------------------------|
| `~/.openclaw`          | `/home/node/.openclaw` | Config, Agents, Sessions  |
| `~/.openclaw/workspace`| `/home/node/.openclaw/workspace` | Agent-Workspace   |

Über `.env` änderbar: `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`.

## Nützliche Befehle

```bash
# Logs
docker compose logs -f openclaw-gateway

# Status
docker compose run --rm openclaw-cli status

# Dashboard-Link (Token/URL)
docker compose run --rm openclaw-cli dashboard --no-open

# Kanäle (Beispiele)
docker compose run --rm openclaw-cli channels login                    # WhatsApp (QR)
docker compose run --rm openclaw-cli channels add --channel telegram --token "<TOKEN>"
docker compose run --rm openclaw-cli pairing approve telegram <CODE>
```

## WireGuard-Client (optional)

Der gesamte Traffic des Gateways kann über einen WireGuard-Tunnel laufen (z. B. für Tailscale/Netzwerk-VPN).

**Voraussetzung:** WireGuard-Kernelmodul auf dem Host (üblich unter Linux; unter macOS/Windows ggf. WireGuard-Desktop-App oder WG im Docker-Host-Netz prüfen).

1. **Config anlegen** (private Keys eintragen):
   ```bash
   cp wireguard/wg0.conf.example wireguard/wg0.conf
   # wireguard/wg0.conf bearbeiten: PrivateKey, PublicKey, Endpoint
   ```

2. **Stack mit VPN starten:**
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.vpn.yml up -d --build
   ```

   Beim ersten Mal das WireGuard-Image bauen: `--build`. Danach wie gewohnt:
   - Control UI: http://127.0.0.1:18789/
   - Der Gateway-Container nutzt den Netz-Stack des WireGuard-Containers; ausgehender Traffic geht durch den Tunnel.

3. **Ohne VPN** (Standard): nur `docker compose up -d` (ohne `docker-compose.vpn.yml`).

Optional in `.env`: **OPENCLAW_WIREGUARD_CONF** – Pfad zur `wg0.conf` (Standard: `./wireguard/wg0.conf`).

## Optionale Umgebungsvariablen (.env)

- **OPENCLAW_GATEWAY_PORT** / **OPENCLAW_BRIDGE_PORT** – Ports (Default 18789, 18790)
- **OPENCLAW_GATEWAY_BIND** – `loopback`, `lan` oder `0.0.0.0`
- **OPENCLAW_DOCKER_APT_PACKAGES** – Zusätzliche apt-Pakete beim Image-Build (z. B. `ffmpeg git`)
- **OPENCLAW_IMAGE** – Image-Name (Default: `openclaw:local`)
- **OPENCLAW_WIREGUARD_CONF** – Pfad zur WireGuard-Config (nur bei VPN-Modus)

Weitere Optionen siehe `.env.example`.

## Links

- [OpenClaw](https://github.com/openclaw/openclaw)
- [Docker-Installation (offiziell)](https://docs.openclaw.ai/install/docker)
- [Getting Started](https://docs.openclaw.ai/start/getting-started)
