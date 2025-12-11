# Zugangsdaten und Endpunkte (Lokal)

Hinweis: Diese Datei enthält sensible Informationen. Nicht committen. Die tatsächlichen Geheimnisse liegen in `.env`.

## n8n
- URL: `http://localhost:5678`
- Benutzer: `admin`
- Passwort: aus `.env` (`N8N_PASSWORD`, aktuell: `securepass123`)
- Webhook-Pfad (Workflow Ingestion): `/webhook/ingest`

## NocoDB
- URL: `http://localhost:8080`
- Datenbank-Verbindung (intern konfiguriert):
  - Connection-String: `postgres://postgres:securepass123@db:5432/kanshi`
  - Host: `db`
  - Port: `5432`
  - Datenbank: `kanshi`
  - Benutzer: `postgres`
  - Passwort: aus `.env` (`DB_PASSWORD`, aktuell: `securepass123`)

## PostgreSQL (TimescaleDB)
- Host: `localhost`
- Port: `5432`
- Datenbank: `kanshi`
- Benutzer: `postgres`
- Passwort: aus `.env` (`DB_PASSWORD`, aktuell: `securepass123`)
- Tabelle für Analysen: `media_analysis`

## MinIO (S3-kompatibel)
- API: `http://localhost:9000`
- Console: `http://localhost:9001`
- Access Key: aus `.env` (`S3_ACCESS`, aktuell: `minioadmin`)
- Secret Key: aus `.env` (`S3_SECRET`, aktuell: `minioadmin123`)
- Buckets (optional): `/import`, `/frames`

## Grok (xAI)
- API-Key: aus `.env` (`GROK_API_KEY`)
- Endpoint: `https://api.x.ai/v1/chat/completions`

