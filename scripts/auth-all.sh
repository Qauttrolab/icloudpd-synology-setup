#!/bin/bash
# =============================================================================
# auth-all.sh — Einmalige 2FA-Authentifizierung aller iCloud Accounts
# =============================================================================
# Ablage: /volume1/docker/icloudpd/auth-all.sh
#
# WANN ausführen:
#   - Beim allerersten Setup (einmalig pro Account)
#   - Wenn ein Cookie abgelaufen ist ("Authentication required" im Log)
#   - Nach Passwortänderung des Apple Accounts
#
# VORAUSSETZUNGEN:
#   - SSH-Zugang zur Synology
#   - .env Dateien aller Accounts befüllt
#   - Gerät des jeweiligen Accountinhabers erreichbar (iPhone/iPad/Mac)
#
# WICHTIG: Interaktiv ausführen — NICHT im Hintergrund starten!
# =============================================================================

set -uo pipefail

ACCOUNTS_DIR="/volume1/docker/icloudpd/accounts"
IMAGE="icloudpd/icloudpd:latest"

echo "============================================="
echo " icloudpd Auth-Setup"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="
echo ""
echo " Ablauf pro Account:"
echo "   1. Apple sendet Code ans Gerät des Accountinhabers"
echo "   2. 'Erlauben' tippen"
echo "   3. 6-stelligen Code hier eingeben → Enter"
echo "   4. Mit Enter zum nächsten Account"
echo ""
echo " Bereit? Mit Enter starten, Ctrl+C zum Abbrechen."
read -r

TOTAL=0
SUCCESS=0
FAILED=0

for account_dir in "$ACCOUNTS_DIR"/*/; do
  account_name=$(basename "$account_dir")
  env_file="$account_dir.env"

  TOTAL=$((TOTAL + 1))

  echo ""
  echo "---------------------------------------------"
  echo " Account: $account_name ($TOTAL)"
  echo "---------------------------------------------"

  if [ ! -f "$env_file" ]; then
    echo " WARNUNG: Keine .env in $account_dir gefunden, übersprungen."
    FAILED=$((FAILED + 1))
    continue
  fi

  # Zugangsdaten laden
  # shellcheck source=/dev/null
  source "$env_file"

  echo " Apple ID: $ICLOUD_USER"

  mkdir -p "$account_dir/cookies"

  echo " Starte Auth — Apple schickt Code ans Gerät..."
  echo ""

  if docker run -it --rm \
    -v "$account_dir/cookies:/config" \
    "$IMAGE" \
    icloudpd \
    --username "$ICLOUD_USER" \
    --password "$ICLOUD_PASS" \
    --auth-only \
    --cookie-directory /config; then

    echo ""
    echo " ✓ Auth für $account_name erfolgreich."
    SUCCESS=$((SUCCESS + 1))
  else
    echo ""
    echo " ✗ Auth für $account_name fehlgeschlagen."
    echo "   → .env prüfen, 2FA-Code korrekt eingegeben?"
    FAILED=$((FAILED + 1))
  fi

  if [ "$account_dir" != "$(ls -d "$ACCOUNTS_DIR"/*/ | tail -1)" ]; then
    echo ""
    echo " Weiter zum nächsten Account mit Enter..."
    read -r
  fi

done

echo ""
echo "============================================="
echo " Auth abgeschlossen: $(date '+%Y-%m-%d %H:%M:%S')"
echo " Erfolg: $SUCCESS | Fehler: $FAILED | Gesamt: $TOTAL"
echo "============================================="

if [ "$SUCCESS" -gt 0 ]; then
  echo ""
  echo " Nächster Schritt: run-all.sh für ersten Sync starten."
  echo " bash /volume1/docker/icloudpd/run-all.sh"
fi
