# Kanshi_n8n 🧩📽️

Ein modularer Workflow‑Stack für Media‑Ingestion, Analyse und Verwaltung – basierend auf n8n, NocoDB, PostgreSQL/TimescaleDB und MinIO. Semantische Analysen erfolgen vorerst über Grok (xAI). Der Stack ist für Windows 11 + Docker Desktop optimiert und lauffähig im lokalen Setup.

## ✨ Features
- 📥 Drag‑and‑Drop Media‑Ingestion (via eigenes Web‑UI + n8n Webhook)
- 🧠 Semantik über Grok (Tags, Summary als JSON)
- 🗃️ Speicherung in Postgres (`media_analysis` JSONB + Text)
- 🗂️ NocoDB‑UI für CRUD, Views und einfache Auswertungen
- 🧾 MinIO als S3‑Speicher (optional: `/import`, `/frames`)
- ⚙️ Erweiterbar: Pose/Outfit/Restraints/ReID via ONNX‑Runtime (später)

## 🧱 Komponenten
- **n8n** (`http://localhost:5678`): Workflows, Webhooks, HTTP‑Nodes
- **NocoDB** (`http://localhost:8080`): SQL‑UI, Tabellen/Views, APIs
- **PostgreSQL/TimescaleDB** (`localhost:5432`): Datenbank, `media_analysis`
- **MinIO** (`http://localhost:9000`, Console `http://localhost:9001`): S3‑kompatibel

## 📦 Verzeichnisstruktur
```
.
├─ web/                     # Einfaches Drag&Drop‑UI (index.html)
├─ workflows/               # n8n Workflows (JSON)
│  └─ ingestion_grok.json   # Webhook → Grok → JSON speichern/Antwort
├─ docs/
│  └─ Zugangsdaten.md       # Lokale Endpunkte und Zugangsdaten (sensibel)
├─ data/                    # Persistente Dateien (JSON‑Analysen etc.)
├─ docker-compose.yml       # Full‑Stack (n8n + NocoDB + DB + MinIO)
├─ docker-compose-minimal.yml# Minimal‑Stack (nur n8n + NocoDB)
├─ Dockerfile               # Custom n8n (FFmpeg)
├─ init.sql                 # DB‑Schema (TimescaleDB + pgvector)
├─ .env                     # Lokale Secrets (nicht committen)
└─ .env.example             # Beispiel‑Env mit Platzhaltern
```

## 🚀 Quickstart
1. 🧩 Voraussetzungen:
   - Windows 11 + Docker Desktop (WSL2 aktiviert)
   - Port‑Freigaben: `5432`, `5678`, `8080`, `9000`, `9001`
2. 🔑 `.env` erstellen:
   - Kopiere `.env.example` → `.env` und setze deine Werte:
     - `DB_PASSWORD`, `N8N_PASSWORD`, `GROK_API_KEY`, `S3_ACCESS`, `S3_SECRET`
3. ▶️ Stack starten:
   - `docker compose up -d`
4. 🖥️ Zugriff:
   - n8n: `http://localhost:5678` (Login: `admin` / `N8N_PASSWORD`)
   - NocoDB: `http://localhost:8080`
   - MinIO Console: `http://localhost:9001`
5. 🔌 Workflow importieren & aktivieren:
   - n8n → Import → `workflows/ingestion_grok.json` → aktivieren (Webhook: `/webhook/ingest`)
6. 🧪 Drag&Drop testen:
   - Öffne `web/index.html` im Browser
   - Ziehe eine Datei in die Drop‑Zone
   - Ergebnis (Tags, Summary) wird angezeigt

## ⚙️ Konfiguration
- **NocoDB Meta‑DB**: Standard ist SQLite (stabil). Bei Bedarf Postgres aktivieren:
  - Setze `NC_DB` in `docker-compose.yml` auf eine gültige URL
  - Empfohlen: `postgres://postgres:${DB_PASSWORD}@db:5432/kanshi`
- **Postgres‑Schema**:
  - `init.sql` wird beim ersten Start eingespielt
  - Tabelle `media_analysis` enthält: `filename`, `hash`, `tags` (JSONB), `summary`, `ts`
- **MinIO Buckets**:
  - Console `http://localhost:9001` → Erstelle optional `/import`, `/frames`
- **Grok API**:
  - `.env` → `GROK_API_KEY` (xAI)
  - Endpoint: `https://api.x.ai/v1/chat/completions`

## 🧰 Nützliche Kommandos
- 🔍 Status:
  - `docker ps`
  - `docker compose logs -f`
- 🧼 Neu starten:
  - `docker compose down && docker compose up -d`
- 🧪 Logs prüfen:
  - NocoDB: `docker logs kanshi_n8n-ui-1 --tail 120`
  - DB: `docker logs kanshi_n8n-db-1 --tail 100`
- 🗄️ DB‑Query:
  - `docker exec kanshi_n8n-db-1 psql -U postgres -d kanshi -c "SELECT * FROM media_analysis LIMIT 5;"`

## 🧩 Workflows
- `workflows/ingestion_grok.json`
  - Webhook → Hash (Code) → Grok (HTTP) → JSON speichern → Response
  - Speicherpfad: `data/analyses/<hash>.json`
  - Erweiterung: Insert in `media_analysis` via n8n SQLite/Postgres‑Node

## 🛠️ Troubleshooting
- 🔁 NocoDB startet neu (“Invalid URL” / “Database not supported”):
  - Prüfe `NC_DB` in `docker-compose.yml` → nutze `sqlite` oder eine gültige Postgres‑URL
- 🧱 DB Hypertable Warnung:
  - Timescale‑Hinweis (PK vs Partition Column) → Service läuft trotzdem.
  - Fix optional: PK auf `PRIMARY KEY (id, created_at)` ändern und `created_at` zu `TIMESTAMPTZ`.
- 🔒 Unauthorized bei n8n‑REST API:
  - REST‑API erwartet UI‑Session; importiere Workflows via UI

## 🔐 Sicherheit
- `.env` niemals committen
- Nutze starke Passwörter (`DB_PASSWORD`, `N8N_PASSWORD`)
- Optional: Traefik / TLS für Produktion

## 🗺️ Roadmap
- 🧠 KI‑Modelle (OpenPose, RF‑DETR, RT‑DETR, OSNet) via ONNX
- 🧮 pgvector und ReID‑Suchen
- 📊 Dashboards (Metabase) für Stats
- 🧼 Wartung: Auto‑Cleanup (Frames >90 Tage), Backups

## 📚 Referenzen
- `docs/Zugangsdaten.md` – Übersicht der lokalen Endpunkte/Zugänge
- `Pflichtenheft.md` – Anforderungen, Architektur, Workflows
- Offizielle Docs: n8n, NocoDB, TimescaleDB, MinIO, xAI Grok

---

> 💡 Hinweis: Dieses Repo ist lokal lauffähig. Für GPU/ROCm Unterstützung unter WSL2 sind zusätzliche Schritte nötig; aktuell ist CPU der Default.
