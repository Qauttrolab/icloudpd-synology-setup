# icloudpd — Synology NAS Setup

> Automatisches Backup von iCloud Fotos & Videos auf eine Synology NAS via [icloudpd](https://github.com/icloudpd/icloudpd) mit Multi-Account Support, Docker Compose und automatisiertem Tagesbetrieb über den DSM Aufgabenplaner.

**📖 [Vollständige Anleitung (HTML)](https://qauttrolab.github.io/icloudpd-synology-setup/)**

---

## Features

- ✅ Mehrere iCloud Accounts parallel verwalten
- ✅ Originaldateien (HEIC, MOV, MP4, JPG, PNG)
- ✅ Live Photos vollständig (Bild + Video)
- ✅ GPS-Daten und EXIF bleiben erhalten
- ✅ Ordnerstruktur nach Jahr/Monat (`YYYY/MM`)
- ✅ One-Way Sync — NAS löschen hat keinen Einfluss auf iCloud
- ✅ Automatischer Tagesbetrieb via DSM Aufgabenplaner

---

## Schnellstart

```bash
# 1. Ordner anlegen
mkdir -p /volume1/docker/icloudpd/accounts/account1/cookies
mkdir -p /volume2/Backups/icloud/account1

# 2. Skripte und Config kopieren (aus diesem Repo)

# 3. .env befüllen
nano /volume1/docker/icloudpd/.env

# 4. Container erstellen
cd /volume1/docker/icloudpd
sudo docker-compose -f compose.yaml up -d icloudpd-account1

# 5. 2FA Auth durchführen
sudo docker run -it --rm \
 -v /volume1/docker/icloudpd/accounts/account1/cookies:/config \
 icloudpd/icloudpd:latest \
 icloudpd --username your@apple.id --password xxxx-xxxx-xxxx-xxxx \
 --auth-only --cookie-directory /config
```

**→ Vollständige Anleitung mit allen Schritten: [docs/index.html](docs/index.html)**

---

## Repository Struktur

```
icloudpd-synology-setup/
├── docs/
│   └── index.html          ← Vollständige HTML-Anleitung (GitHub Pages)
├── config/
│   ├── compose.yaml        ← Docker Compose Vorlage (Multi-Account)
│   ├── env.example         ← .env Vorlage
│   └── env-account.example ← Account .env Vorlage
├── scripts/
│   ├── run-all.sh          ← Täglicher Sync aller Accounts
│   └── auth-all.sh         ← Einmalige 2FA-Authentifizierung
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── FUNDING.yml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

---

## Voraussetzungen

| Komponente | Mindestanforderung |
|---|---|
| Synology DSM | 7.3+ |
| Container Manager | Aktuellste Version |
| icloudpd | `latest` |
| SSH-Zugang | Aktiviert |

---

## Getestet auf

- Synology DS723+ mit DSM 7.3
- Synology DS923+ mit DSM 7.3

---

## Verwandte Projekte

- [icloudpd/icloudpd](https://github.com/icloudpd/icloudpd) — Das verwendete Backup-Tool
- [immich-app/immich](https://github.com/immich-app/immich) — Empfohlener Foto-Viewer für die heruntergeladenen Dateien

---

## Lizenz

MIT — siehe [LICENSE](LICENSE)
