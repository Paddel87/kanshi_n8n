# Pflichtenheft für Kanshi_n8n

## 1. Einleitung

### 1.1 Zweck des Dokuments
Dieses Pflichtenheft beschreibt die Anforderungen an das System Kanshi_n8n, eine Workflow-Automatisierungsplattform basierend auf n8n zur automatisierten Analyse von Video- und Bildmaterial. Das System dient der Erfassung, Analyse und Kategorisierung von Medieninhalten, insbesondere im Kontext von Modellanalysen (Personen in Videos/Frames), unter Berücksichtigung von Datenschutz, Skalierbarkeit und KI-Integration. Es ermöglicht die automatisierte Verarbeitung von Frames mit Fokus auf Pose-Erkennung, Outfit- und Restraint-Detektion, Re-Identification (ReID) von Personen und semantische Beschreibung.

Das Dokument dient als Grundlage für die Entwicklung, Implementierung und Validierung des Systems. Es basiert auf den identifizierten Bedürfnissen und dem bestehenden Implementierungsplan.

### 1.2 Geltungsbereich
- **Systemumfang**: Automatisierte Pipeline für Media-Import, Frame-Extraktion, KI-Analyse (Pose, Outfit, Restraints, ReID, Semantik), Speicherung in einer Datenbank, Visualisierung und Wartung.
- **Ausgrenzungen**: Keine Echtzeit-Verarbeitung (Batch-Processing), keine Audio-Analyse (optional erweiterbar), keine direkte Hardware-Integration (z.B. Kameras).
- **Zielgruppe**: Entwickler, Analysten und Administratoren im Bereich Medienanalyse und Automatisierung.

### 1.3 Definitionen und Abkürzungen
- **n8n**: Open-Source-Workflow-Automatisierungstool.
- **ReID**: Re-Identification, Wiedererkennung von Personen basierend auf Embeddings.
- **ONNX**: Open Neural Network Exchange, Format für ML-Modelle.
- **pgvector**: PostgreSQL-Erweiterung für Vektor-Suchen (Embeddings).
- **NocoDB**: No-Code-Datenbank-UI auf Basis von SQL-Datenbanken.
- **S3**: Amazon S3-kompatibler Speicher (z.B. MinIO/RustFS).

### 1.4 Referenzen
- Implementierungsplan für Kanshi_n8n (basierend auf Pflichtenheft Kapitel 1-3).
- n8n-Dokumentation: https://docs.n8n.io/
- OpenPose, YOLO, OSNet: Standard-KI-Modelle für Pose- und Objekterkennung.

### 1.5 Überblick
Das Dokument gliedert sich in Einleitung, Ziele, funktionale und nicht-funktionale Anforderungen, Datenmodell, Workflows, Architektur, Deployment, Risiken und Anhänge.

## 2. Ziele und Rahmenbedingungen

### 2.1 Geschäftsziele
- Automatisierung der Medienanalyse zur Reduzierung manueller Arbeit um >80%.
- Erstellung von Dossiers (Profilen) für Modelle basierend auf analytischen Daten.
- Sicherstellung von Datenschutz und Compliance (z.B. GDPR-konform, keine personenbezogenen Daten ohne Pseudonymisierung).
- Skalierbare Verarbeitung von bis zu 1000 Frames/Tag bei begrenzten Ressourcen (CPU-fokussiert, optional GPU).

### 2.2 Funktionale Ziele
- Import und Verarbeitung von Videos/Bildern.
- KI-basierte Analyse: Pose-Klassifikation, Outfit- und Restraint-Detektion, Person-ReID, semantische Zusammenfassung.
- Speicherung und Abfrage von Analysedaten.
- UI für Visualisierung und manuelle Korrektur.

### 2.3 Nicht-funktionale Ziele
- Performance: <2s pro Frame-Analyse (CPU), <1s mit GPU.
- Verfügbarkeit: 99% Uptime.
- Skalierbarkeit: Horizontal skalierbar via Docker.
- Sicherheit: Authentifizierung, Verschlüsselung von Sensiblen Daten.

### 2.4 Rahmenbedingungen
- **Technische**: Windows/Linux-Umgebung, Docker-Compose für Deployment, PostgreSQL als DB, n8n als Workflow-Engine.
- **Organisatorisch**: Entwicklungsdauer: 3-4 Wochen, Team: 1-2 Entwickler.
- **Rechtlich**: Datenschutz (Pseudonymisierung von Identitäten), keine Speicherung roher Frames länger als 90 Tage.
- **Budget**: Open-Source-Tools priorisieren, optionale API-Kosten (z.B. Grok) <100€/Monat.

## 3. Funktionale Anforderungen

### 3.1 Media-Import und -Verarbeitung
- **FR-1.1**: Automatischer Import von Videos/Bildern aus S3-Bucket (/import/).
- **FR-1.2**: Hash-basiierte Duplicate-Detektion (MD5/SHA256).
- **FR-1.3**: Frame-Extraktion mit FFmpeg (z.B. 1 Frame/10s, max. 1000 Frames/Video).
- **FR-1.4**: Speicherung von Frames in S3 (/frames/), Metadaten in DB (media_item, media_frame).

### 3.2 KI-Analyse
- **FR-2.1**: Pose-Erkennung mit OpenPose (Keypoints, Pose-Klasse: z.B. standing, hogtie).
- **FR-2.2**: Outfit-Detektion (YOLO-basiert: Kleidung, Materialien wie latex).
- **FR-2.3**: Restraint-Detektion (z.B. Rope, Cuffs; Kategorien: wrists_back, ankles).
- **FR-2.4**: Embedding-Generierung (OSNet, 512-Dim) für ReID.
- **FR-2.5**: ReID-Matching (Cosine-Similarity >0.8, Fallback Top-5).
- **FR-2.6**: Semantische Analyse via Grok-API (Prompt: Beschreibung basierend auf Pose/Outfit/Restraint, Output: Tags/Summary).

### 3.3 Datenmanagement
- **FR-3.1**: Erstellung von Model-Profilen (model_identity: first_seen, total_instances, embedding).
- **FR-3.2**: Update von Instanzen (model_instance: pose, outfit_items, restraint_items, semantic_tags).
- **FR-3.3**: Views für Statistiken (vw_model_item_stats: Häufigkeiten von Posen/Outfits).

### 3.4 UI und Interaktion
- **FR-4.1**: NocoDB-Integration für CRUD-Operationen (Rollen: Admin, Analyst).
- **FR-4.2**: Dossier-Views (Filter nach Tags, Zeitraum).
- **FR-4.3**: Manuelle Merge von Identitäten bei ReID-Unsicherheit.

### 3.5 Wartung
- **FR-5.1**: Automatisierte Backups (pg_dump zu S3, 30-90 Tage).
- **FR-5.2**: Cleanup (Löschen alter Frames >90 Tage).
- **FR-5.3**: Alerts bei Fehlern/Kostenüberschreitung.

## 4. Nicht-funktionale Anforderungen

### 4.1 Performance
- **NFR-1.1**: Latenz: 1000-1500ms pro Analyse-Instanz.
- **NFR-1.2**: Durchsatz: 1 Frame/s (CPU), skalierbar mit Workern.
- **NFR-1.3**: Speicher: <16GB RAM für 8 vCPUs.

### 4.2 Sicherheit
- **NFR-2.1**: BASIC_AUTH für n8n, Rollenbasierte Zugriffe in NocoDB.
- **NFR-2.2**: Verschlüsselung: HTTPS/TLS, Secrets in .env.
- **NFR-2.3**: Audit-Logs für Änderungen.

### 4.3 Zuverlässigkeit
- **NFR-3.1**: Retries: 3x für Import, 5x für Analyse.
- **NFR-3.2**: Fallbacks: CPU bei GPU-Fehler, manuelle Review bei ReID <0.75.
- **NFR-3.3**: ACID-Compliance in DB.

### 4.4 Skalierbarkeit und Wartbarkeit
- **NFR-4.1**: Docker-Compose für einfaches Scaling.
- **NFR-4.2**: Monitoring: n8n-Metrics, Prometheus-optional.
- **NFR-4.3**: Erweiterbarkeit: Modulare Workflows (JSON-Export).

### 4.5 Usability
- **NFR-5.1**: Intuitive NocoDB-UI, Drag-and-Drop in n8n.
- **NFR-5.2**: Dokumentation: README, API-Docs.

## 5. Systemarchitektur

### 5.1 Komponenten
- **Workflow-Engine**: n8n (Nodes: S3-Trigger, FFmpeg, ONNX-Runtime, HTTP-Grok, SQL).
- **Datenbank**: TimescaleDB (PostgreSQL-Extension) mit pgvector (Hypertables für Zeitreihen, Tabellen: media_item, media_frame, model_instance, model_identity, lookup_outfit/restraint).
- **Speicher**: RustFS (S3-kompatibler Emulator für /import/ und /frames/).
- **UI**: NocoDB (No-Code-CRUD mit Rollen, Views und Merge-Funktionen).
- **KI-Modelle**: ONNX-Modelle (OpenPose für Pose-Erkennung, RF-DETR für Outfit-Detektion, RT-DETR für Restraint-Detektion, OSNet für ReID), geladen via ONNX-Runtime.

### 5.2 Datenfluss
1. S3-Upload → n8n-Trigger → Hash/Duplicate-Check → Frame-Extraktion → Analyse (parallele Nodes) → DB-Insert/Update → Semantik → Dossier-Update.
2. Cron-Jobs: ReID-Refresh, Cleanup, Backups.

### 5.3 Schnittstellen
- **Externe APIs**: Grok (Semantik), optional externe S3.
- **Interne**: SQL-Queries, n8n-Webhooks.

## 6. Datenmodell

### 6.1 Entitäten
- **media_item**: id, hash, filename, upload_date, status.
- **media_frame**: id, media_item_id, frame_number, s3_path, timestamp.
- **model_instance**: id, frame_id, keypoints (JSON), pose_class, outfit_items (Array), restraint_items (Array), embedding (vector), analysis_failed (bool).
- **model_identity**: id, first_seen, last_seen, total_instances, embedding (vector), semantic_summary.
- **model_pose_point**: id, instance_id, point_type, x, y, confidence.
- **model_outfit_item / model_restraint_item**: id, instance_id, type, category, material, confidence.
- **Lookups**: lookup_outfit_items (code, category, material), lookup_restraint_items (type, position).

### 6.2 Views und Indizes
- **vw_model_item_stats**: Aggregierte Statistiken (Counts pro Pose/Outfit).
- Indizes: B-Tree auf IDs, IVFFlat auf Embeddings (HNSW für ReID).

### 6.3 Constraints
- FKs mit CASCADE-Delete.
- CHECKs: Confidence >0.5, Embeddings normiert.

## 7. Workflows

### 7.1 Import-Workflows
- **Media Import Watcher**: S3-Trigger → Hash → INSERT media_item (if new).
- **Video Frame Extraction**: FFmpeg mit Scene-Detection (Threshold 0.3, dynamisch nach Länge) → Loop-Upload zu RustFS (/frames/) → INSERT media_frame.

### 7.2 Analyse-Workflows
- **Basis-Analyse**: Frame-Trigger → ONNX (Pose/Outfit/Restraint/Embedding) → INSERT model_instance.
- **ReID Match**: New Instance → Cosine-Search (pgvector) → UPDATE identity oder INSERT new.
- **Profil Refresh**: Cron → Average Embeddings → UPDATE model_identity.

### 7.3 Semantik-Workflow
- **Semantic Analysis**: Trigger on new instance → Multi-Call Prompt-Builder (Tags + Summary, >2000 Tokens) → Grok-API → Parse JSON → UPDATE semantic_tags/summary.

### 7.4 Wartungs-Workflows
- **Backup**: Cron → pg_dump → S3.
- **Cleanup**: Cron → DELETE old frames (>90 Tage).
- **Alerts**: Thresholds (Errors, Tokens) → Webhook/Email.

## 8. Deployment und Betrieb

### 8.1 Umgebung
- **Hardware**: Min. 8 vCPUs, 16GB RAM, 1TB Storage.
- **Software**: Docker-Compose (Services: postgres, n8n, nocodb, rustfs).
- **Konfiguration**: .env (DB-Pass, API-Keys, Thresholds: REID_THRESHOLD=0.8, GROK_TIMEOUT=15s).

### 8.2 Installation
- docker-compose up -d.
- Initial SQL-Skripte für Schema/Views.
- n8n-Workflows importieren (JSON).

### 8.3 Monitoring und Kosten
- **Metrics**: n8n built-in, optional Prometheus.
- **Kosten**: Track Grok-Tokens (<1000/Tag), Alerts bei Überschreitung.
- **Skalierung**: Mehr Worker-Container, externe Vektor-DB.

## 9. Offene Punkte und Risiken

### 9.1 Gelöste Klärungen
- **9.1.1**: Maximale Frames/Video: Dynamische Grenze basierend auf Video-Länge (Max. 200 Frames für <5 Min., 500 für 5-20 Min., 1000 für >20 Min.). FFmpeg mit Scene-Detection (Threshold 0.3) für intelligente Extraktion.
- **9.1.2**: Lexika-Details: Erweitertes Lexikon (ca. 50-80 Kategorien) mit Unterkategorien (z. B. Typ + Material + Farbe für Outfits, Typ + Position + Intensität für Restraints). Implementiert in lookup-Tabellen (init.sql).
- **9.1.3**: Prompt-Engineering für Grok: Multi-Call-Prompts (modular: Tags → Summary, >2000 Tokens total) mit Chain-of-Thought-Elementen und Fallbacks bei Token-Überschreitung. Kosten-Monitoring in n8n.
- **9.1.4**: ReID-Schwellwerte: Ausgewogener Schwellwert (0.80 für Match, 0.70-0.80 für Kandidaten), mit manueller Bestätigung im UI (z. B. Vorschläge und Merge-Funktion in NocoDB). pgvector HNSW-Index für Top-5-Suchen.

### 9.2 Annahmen
- **9.2.1**: NocoDB für UI (keine Custom-Frontend).
- **9.2.2**: Traefik optional für TLS.
- **9.2.3**: Retention: Frames 90 Tage, Backups 30 Tage.

### 9.3 Erweiterungen
- Session-Tabelle (Start/End-Frame).
- Audio-Analyse (Whisper).
- Export (PDF-Dossiers).
- Tag-Clustering.

### 9.4 Risiken
- **Ungenaue KI**: Mitigation: Threshold-Tuning, Fallbacks, manuelle Review.
- **Hohe Kosten**: Limits, Monitoring.
- **Hardware**: Backups, Failover.
- **Skalierbarkeit**: Test mit Load (1000 Frames).

## 10. Validierung und Akzeptanzkriterien
- **Tests**: End-to-End (Import → Analyse → Dossier), Performance (1 Frame/s), Reproduzierbarkeit.
- **Akzeptanz**: Alle Workflows laufen fehlerfrei mit Stock-Material, UI funktional, Kosten unter Budget.
- **Iteration**: Basierend auf Tests anpassen.

## Anhänge
- **A1**: SQL-Schema-Skript (init.sql: TimescaleDB + pgvector, Entitäten/Views/Lexika/Indizes).
- **A2**: Beispiel-Workflow-JSON (n8n: Import/Analyse/Semantik/Wartung).
- **A3**: Prompt-Templates für Grok (Multi-Call: Tags/Summary-Beispiele).

**Version**: 2.0 (Final – Alle Klärungen gelöst, Schema implementiert)  
**Datum**: 2025-12-11  
**Autor**: Trae IDE Assistant