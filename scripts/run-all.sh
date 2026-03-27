#!/bin/bash
# =============================================================================
# run-all.sh — Täglicher iCloud Sync für alle Accounts
# =============================================================================
# Ablage: /volume1/docker/icloudpd/run-all.sh
#
# Aufgabenplaner (DSM):
#   Name:    icloudpd Sync
#   Benutzer: root
#   Zeit:    Täglich, gewünschte Uhrzeit (z.B. 07:00)
#   Skript:  /bin/bash /volume1/docker/icloudpd/run-all.sh >> /volume1/docker/icloudpd/logs/sync.log 2>&1
#
# VORAUSSETZUNGEN:
#   - Container wurden einmalig via docker-compose up -d erstellt
#   - 2FA Auth wurde für jeden Account durchgeführt (auth-all.sh)
#
# NEUEN ACCOUNT HINZUFÜGEN:
#   1. Account in compose.yaml einkommentieren
#   2. sudo docker-compose -f compose.yaml up -d icloudpd-NAME
#   3. Auth durchführen: bash auth-all.sh (oder manuell)
#   4. Account hier in der ACCOUNTS Liste eintragen
#
# ACCOUNT DEAKTIVIEREN:
#   → Account in der ACCOUNTS Liste auskommentieren
#   → Daten auf der NAS bleiben erhalten
# =============================================================================

set -uo pipefail

LOG_DIR="/volume1/docker/icloudpd/logs"

# Sekunden Pause zwischen Accounts.
# 0 = sofort nach Abschluss des vorherigen Accounts starten.
DELAY=0

mkdir -p "$LOG_DIR"

echo "============================================="
echo " icloudpd Sync gestartet: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="

# =============================================================================
# ACCOUNTS — aktive Accounts hier eintragen
# Auskommentieren = Account wird nicht gesynct
# =============================================================================
ACCOUNTS=(
  "account1"
  # "account2"   # auskommentiert bis eingerichtet
  # "account3"   # fertig, kein weiterer Sync nötig
)

TOTAL=${#ACCOUNTS[@]}
COUNT=0
SUCCESS=0
FAILED=0

for account in "${ACCOUNTS[@]}"; do
  COUNT=$((COUNT + 1))

  echo ""
  echo "---------------------------------------------"
  echo " Account: $account ($COUNT/$TOTAL)"
  echo " Gestartet: $(date '+%H:%M:%S')"
  echo "---------------------------------------------"

  # Prüfen ob Container existiert
  if ! docker inspect "icloudpd-$account" > /dev/null 2>&1; then
    echo " WARNUNG: Container icloudpd-$account existiert nicht."
    echo "          → sudo docker-compose -f compose.yaml up -d icloudpd-$account"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Container starten und auf Abschluss warten
  docker start "icloudpd-$account"
  EXIT_CODE=$(docker wait "icloudpd-$account")

  if [ "$EXIT_CODE" = "0" ]; then
    echo " ✓ $account fertig: $(date '+%H:%M:%S')"
    SUCCESS=$((SUCCESS + 1))
  else
    echo " ✗ $account Fehler (Exit Code: $EXIT_CODE): $(date '+%H:%M:%S')"
    FAILED=$((FAILED + 1))
  fi

  # Pause zwischen Accounts
  if [ "$COUNT" -lt "$TOTAL" ] && [ "$DELAY" -gt 0 ]; then
    echo " Warte ${DELAY}s bis zum nächsten Account..."
    sleep $DELAY
  fi

done

echo ""
echo "============================================="
echo " Sync abgeschlossen: $(date '+%Y-%m-%d %H:%M:%S')"
echo " Erfolg: $SUCCESS | Fehler: $FAILED | Gesamt: $TOTAL"
echo "============================================="
