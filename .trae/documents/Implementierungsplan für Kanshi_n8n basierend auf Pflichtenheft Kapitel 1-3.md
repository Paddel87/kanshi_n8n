### Finaler Implementierungsplan für Kanshi_n8n

#### Phase 1: Minimal Funktionsfähige Pipeline (MVP) – Priorität: Hoch, Dauer: 5-7 Tage (Kapitel 9.5, 1-3, 8)
- **Konfiguration & Setup (Kapitel 8.1-8.3)**: Erstelle .env (Sicherheitsvariablen: POSTGRES_PASSWORD, GROK_API_KEY etc.; Konfig: USE_DIRECTML=true, EXECUTIONS_TIMEOUT=120, MAX_WORKERS=4). docker-compose.yml: Services postgres (kanshi DB, pgvector), n8n (BASIC_AUTH, METRICS=true), nocodb, rustfs (S3_KEYS). Volumes (pgdata, rustfsdata). Starte Stack, teste Ressourcen (8 vCPUs/16 GB min., 1 TB Storage). S3-Prefixe (/import/, /frames/). Adressiere 9.2.2: Optional Traefik für TLS/LAN.
- **Datenmodell Basis (Kapitel 6)**: SQL-Skript: Kern-Tabellen (media_item, media_frame, model_instance, model_pose_point, model_outfit_item, model_restraint_item, model_embedding). Basis-Constraints (CHECKs, FKs/CASCADE). View vw_model_item_stats. Indizes (ivfflat für Embeddings). Teste Integrität/ACID.
- **Import-Workflows (Kapitel 7.1, 9.1.1)**: „Media Import Watcher“: S3 Trigger → Hashing → Duplicate-Check → INSERT media_item. „Video Frame Extraction“: FFmpeg → Upload → INSERT media_frame/UPDATE status. Retries 3x/5x. Teste mit Stock-Video (1-2 GB, 1000 Frames max.).
- **Basis-Analyse (Kapitel 4.5, 7.2, 9.1.1)**: Wähle ONNX-Modelle (z. B. OpenPose für Keypoints/Pose, YOLO für Detection; Embedding: OSNet 512-Dim). Code Node: JSON-Output (keypoints/pose_class/outfit/restraint). INSERTs in Tabellen. Fallback CPU. Teste Latenz (1000-1500 ms/Instanz; 8.4.2). Flag analysis_failed bei Fehlern.
- **NocoDB Initial (Kapitel 4.2, 9.2.1)**: Verbinde, UI für Basis-Tabellen. Rollen: Admin/Analyst (Editing stage_name etc.). Teste Views.
- **Risiken (9.4)**: Teste Speicher (Clean-Up optional), Model-Präzision mit Samples.

#### Phase 2: ReID-Integration – Priorität: Hoch, Dauer: 3-4 Tage (Kapitel 5.4, 7.3, 9.1.4)
- **ReID-Workflows (Kapitel 7.3)**: „ReID Match“: Select Embedding → Cosine (Schwellwert 0.8 aus .env, empirisch testen) → Fallback Top-5 → UPDATE model_instance (identity_id/confidence) oder INSERT model_identity. „Profil Refresh“: Täglicher Cron → Mittelwert (neue Instanzen gewichten) → model_identity_embedding.
- **Dossier-Basis (Kapitel 5.2)**: INSERT model_identity bei No-Match. Update first/last_seen_at/total_instances (via Trigger/View).
- **Offene Klärung (9.1.4)**: Teste Schwellwerte auf Stock-Material (0.75-0.85), flag manual_review bei unclear.
- **Risiken**: Ungenaue ReID – Gegenmaßnahme: Threshold-Tuning, Logging Entscheidungen.

#### Phase 3: Semantik & Kosten – Priorität: Mittel, Dauer: 2-3 Tage (Kapitel 5.5, 7.4, 8.5, 9.1.3)
- **Semantik-Workflow (Kapitel 7.4)**: Trigger (neue Instanz) → Prompt Builder (JSON: pose/outfit/restraint, 120-150 Tokens) → HTTP Grok (15s Timeout, Retry 1x) → Parse (summary/tags) → UPDATE model_instance. Bei Fehler: semantic_missing=true.
- **Kostenmonitor (Kapitel 8.5.2)**: Neuer Workflow: Täglich Tokens tracken (Schwelle 1000/Tag), Alert via Webhook, Failsafe (Deaktivierung bei Overuse).
- **Offene Klärung (9.1.3)**: Finalisiere Prompt (Detailtiefe/Tag-Set: hogtie, latex etc.), teste Output (80-120 Tokens).
- **Risiken**: Hohe Kosten – Gegenmaßnahme: Limits enforcen, Logging (Tokens/Dauer).

#### Phase 4: Dossier, UI & Klassifikationen – Priorität: Mittel, Dauer: 3-4 Tage (Kapitel 5.2/5.6, 9.1.2/9.2)
- **Dossier-UI (Kapitel 4.2, 9.2.1)**: NocoDB-Layouts für Dossiers (Views: Häufigkeiten via vw_model_item_stats). Manuelle Merge/Editing (Rollen: Analyst darf korrigieren).
- **Lexika (9.1.2)**: Erstelle Referenztabellen (lookup_outfit_items: Codes/Kategorien/Materialien; lookup_restraint_items: Typen/Positionen, z. B. Rope wrists_back). Integriere in INSERTs (Enums erweitern).
- **Statistik (Kapitel 5.6)**: Erweitere View um Pose-Counts. Teste Filter (z. B. „Modelle mit Hogtie“).
- **Offene Klärung (9.2.3)**: Setze Defaults (Frames 90 Tage, Backups 30 Tage). Cleanup-Workflow (Kapitel 7.5.2).
- **Risiken**: Datenveränderung – Gegenmaßnahme: Auth/Rollen.

#### Phase 5: Wartung, Monitoring & Erweiterungen – Priorität: Niedrig, Dauer: 2-3 Tage (Kapitel 7.5, 8.6-8.8, 9.3)
- **Wartung-Workflows (Kapitel 7.5, 8.6)**: „Backup“ (pg_dump/S3, 30-90 Tage), „Cleanup“ (90 Tage), „Alerts“ (Logs/Metriken: Errors/Kosten, Prometheus-optional).
- **Monitoring (Kapitel 8.7)**: n8n-Metrics (Instanzen/min), Slow Queries, Storage-Track. Alerts für Overuse/Hardware.
- **Erweiterungen (9.3, optional)**: Session-Tabelle (Start/Endframe), Tag-Clustering. Später: Audio (Whisper), Export (PDF-Dossiers).
- **Skalierbarkeit (8.8)**: Teste Worker-Container, externe Vektor-DB.
- **Risiken**: Hardwareausfall – Gegenmaßnahme: Backups, Failover-Host.

#### Gesamte Validierung & Iteration (Priorität: Hoch, Dauer: Laufend)
- **Tests**: End-to-End-MVP (Import → Analyse → ReID → Semantik → Dossier). Reproduzierbarkeit (gleiche Frames → gleiche Results; Kapitel 1.7), Performance (1 Frame/s CPU; 8.4), Kosten (Kapitel 8.5). Stock-Material, Risiko-Simulation (z. B. GPU-Fail).
- **Offene Klärungen (9.1-9.2)**: Sammle Entscheidungen (z. B. Modelle: OpenPose/OSNet; Schwellwert: 0.8; Rollen: 3 Level). Integriere in .env/Tabellen.
- **Deployment**: docker-compose up/down-Skripte. Versioniere Workflows (JSON). Gesamtdauer: 3-4 Wochen.
- **Tools-Nutzung**: TodoWrite für Phasen-Tracking; RunCommand für Tests (docker/FFmpeg); SearchCodebase für Konsistenz. Risiken minimieren (9.4: Nachtraining bei Ungenauigkeit).

Dieser Plan folgt dem Pflichtenheft strikt, startet mit MVP (Phase 1) und adressiert Offenes iterativ. Er gewährleistet Modularität, Robustheit und Erweiterbarkeit. Bestätige bitte, um Phase 1 zu starten – ich warte auf deine Freigabe vor Tools wie Write/RunCommand.