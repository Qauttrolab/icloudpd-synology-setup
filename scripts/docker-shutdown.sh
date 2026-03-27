#!/bin/bash
# =============================================================================
# docker-shutdown.sh — Sauberes Herunterfahren aller Docker Container
# =============================================================================
# Ablage: /volume1/docker/scripts/docker-shutdown.sh
#
# Aufgabenplaner (DSM):
#   Name:    Docker Shutdown
#   Benutzer: root
#   Zeit:    Täglich, 5 Minuten vor NAS-Abschaltung (z.B. 22:55)
#   Skript:  /bin/bash /volume1/docker/scripts/docker-shutdown.sh
#
# =============================================================================
# REIHENFOLGE — WICHTIG:
# =============================================================================
# Immer in dieser Reihenfolge stoppen:
#
#   1. Download/Sync Jobs     → können jederzeit unterbrochen werden
#   2. Web-Apps / Frontend    → zuerst neue Requests blockieren
#   3. Hintergrund-Services   → Worker, Scheduler, Exporter
#   4. Monitoring             → Grafana, Prometheus
#   5. Netzwerk-Services      → Tunnel, DNS, VPN
#   6. Caches (Redis)         → erst nach den Apps die sie nutzen
#   7. Datenbanken (Postgres) → IMMER ZULETZT — brauchen sauberes Shutdown
#
# NEUEN CONTAINER HINZUFÜGEN:
#   → Container in die passende Kategorie einsortieren
#   → Syntax: docker stop --time=$TIMEOUT CONTAINERNAME 2>/dev/null
#   → 2>/dev/null unterdrückt Fehler wenn Container bereits gestoppt ist
# =============================================================================

TIMEOUT=30      # Sekunden bis SIGKILL für normale Container
TIMEOUT_DB=60   # Sekunden bis SIGKILL für Datenbanken

echo "============================================="
echo " Docker Shutdown: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

# -----------------------------------------------------------------------------
# 1. DOWNLOAD / SYNC JOBS
# icloudpd merkt sich den Fortschritt — beim nächsten Start weiter
# -----------------------------------------------------------------------------
echo "[1/7] Stoppe Download-Jobs..."
docker stop --time=$TIMEOUT icloudpd-account1  2>/dev/null && echo "  ✓ icloudpd-account1"
docker stop --time=$TIMEOUT icloudpd-account2  2>/dev/null && echo "  ✓ icloudpd-account2"
# Weitere icloudpd Accounts hier eintragen:
# docker stop --time=$TIMEOUT icloudpd-account3 2>/dev/null && echo "  ✓ icloudpd-account3"

# -----------------------------------------------------------------------------
# 2. WEB-APPS / FRONTEND
# Zuerst stoppen damit keine neuen Requests mehr reinkommen
# -----------------------------------------------------------------------------
echo "[2/7] Stoppe Web-Apps..."
# Immich
docker stop --time=$TIMEOUT immich-server            2>/dev/null && echo "  ✓ immich-server"
docker stop --time=$TIMEOUT immich-machine-learning  2>/dev/null && echo "  ✓ immich-machine-learning"
# Paperless
docker stop --time=$TIMEOUT paperless                2>/dev/null && echo "  ✓ paperless"
# Weitere Web-Apps hier eintragen

# -----------------------------------------------------------------------------
# 3. HINTERGRUND-SERVICES / WORKER
# Nach den Apps stoppen
# -----------------------------------------------------------------------------
echo "[3/7] Stoppe Hintergrund-Services..."
docker stop --time=$TIMEOUT paperless-ofelia         2>/dev/null && echo "  ✓ paperless-ofelia"
docker stop --time=$TIMEOUT paperless-backup-runner  2>/dev/null && echo "  ✓ paperless-backup-runner"
docker stop --time=$TIMEOUT paperless-tika           2>/dev/null && echo "  ✓ paperless-tika"
docker stop --time=$TIMEOUT paperless-gotenberg      2>/dev/null && echo "  ✓ paperless-gotenberg"
# Weitere Worker/Scheduler hier eintragen

# -----------------------------------------------------------------------------
# 4. MONITORING
# Metriken gehen verloren — unkritisch
# -----------------------------------------------------------------------------
echo "[4/7] Stoppe Monitoring..."
docker stop --time=$TIMEOUT paperless-grafana        2>/dev/null && echo "  ✓ paperless-grafana"
docker stop --time=$TIMEOUT paperless-prometheus     2>/dev/null && echo "  ✓ paperless-prometheus"
docker stop --time=$TIMEOUT paperless-redis-exporter 2>/dev/null && echo "  ✓ paperless-redis-exporter"
# Weitere Monitoring-Container hier eintragen

# -----------------------------------------------------------------------------
# 5. NETZWERK-SERVICES
# Nach den Apps stoppen
# -----------------------------------------------------------------------------
echo "[5/7] Stoppe Netzwerk-Services..."
docker stop --time=$TIMEOUT cloudflared-tunnel  2>/dev/null && echo "  ✓ cloudflared-tunnel"
# Weitere Netzwerk-Services hier eintragen

# -----------------------------------------------------------------------------
# 6. CACHES (Redis)
# Erst nach allen Apps stoppen die Redis nutzen
# -----------------------------------------------------------------------------
echo "[6/7] Stoppe Caches..."
docker stop --time=$TIMEOUT immich-redis    2>/dev/null && echo "  ✓ immich-redis"
docker stop --time=$TIMEOUT paperless-redis 2>/dev/null && echo "  ✓ paperless-redis"
# Weitere Redis-Instanzen hier eintragen

# -----------------------------------------------------------------------------
# 7. DATENBANKEN — IMMER ZULETZT
# Postgres braucht Zeit für sauberes WAL-Flush und Checkpoint.
# NIEMALS vor den Apps stoppen — sonst Datenbankkorruption möglich.
# -----------------------------------------------------------------------------
echo "[7/7] Stoppe Datenbanken..."
docker stop --time=$TIMEOUT_DB immich-postgres 2>/dev/null && echo "  ✓ immich-postgres"
docker stop --time=$TIMEOUT_DB paperless-db    2>/dev/null && echo "  ✓ paperless-db"
# Weitere Datenbanken hier eintragen — immer mit $TIMEOUT_DB

echo ""
echo "============================================="
echo " Alle Container gestoppt: $(date '+%H:%M:%S')"
echo "============================================="
