#!/bin/sh
set -e

CONF="${WG_CONFIG:-/etc/wireguard/wg0.conf}"
INTERFACE="${WG_INTERFACE:-wg0}"

if [ ! -f "$CONF" ]; then
  echo "WireGuard-Konfiguration nicht gefunden: $CONF" >&2
  echo "Bitte eine gültige Config nach $CONF legen (siehe wireguard/wg0.conf.example)." >&2
  exit 1
fi

echo "Starte WireGuard-Interface $INTERFACE mit $CONF …"
wg-quick up "$INTERFACE"

# Tunnel offen halten; OpenClaw-Gateway nutzt diesen Netz-Stack (network_mode: service:wireguard)
exec tail -f /dev/null
