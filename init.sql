-- init.sql: Kanshi_n8n DB-Schema (TimescaleDB + pgvector)
-- Version: 1.0 (basierend auf Pflichtenheft 2.0)
-- Ausführen: Automatisch via Docker-Compose in TimescaleDB

-- Extensions
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
CREATE EXTENSION IF NOT EXISTS vector CASCADE;

-- Lookups (erweiterte Lexika: 50-80 Kategorien)
CREATE TABLE lookup_outfit_items (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL,  -- z.B. gloves, corset
    material VARCHAR(50) NOT NULL,  -- z.B. latex, leather
    color VARCHAR(50),              -- z.B. black, red
    description TEXT
);

CREATE TABLE lookup_restraint_items (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL,      -- z.B. rope, cuffs
    position VARCHAR(50) NOT NULL,  -- z.B. wrists_back, ankles
    intensity VARCHAR(20),          -- z.B. mild, tight
    description TEXT
);

-- Beispiel-Inserts für Lexika (erweitern auf 50-80)
INSERT INTO lookup_outfit_items (code, category, material, color, description) VALUES
('LATEX_GLOVES_BLACK', 'gloves', 'latex', 'black', 'Latex-Handschuhe schwarz'),
('LEATHER_CORSET_RED', 'corset', 'leather', 'red', 'Leder-Korsett rot');
-- ... (weitere 48+ für Outfits hinzufügen, z.B. via separatem Skript)

INSERT INTO lookup_restraint_items (code, type, position, intensity, description) VALUES
('ROPE_WRIST_MILD', 'rope', 'wrists_back', 'mild', 'Seil an Handgelenken, locker'),
('CUFFS_ANKLE_TIGHT', 'cuffs', 'ankles', 'tight', 'Handschellen an Knöcheln, fest');
-- ... (weitere 28+ für Restraints hinzufügen)

-- Haupt-Entitäten (Kapitel 6.1)
CREATE TABLE media_item (
    id SERIAL PRIMARY KEY,
    hash VARCHAR(64) UNIQUE NOT NULL,  -- MD5/SHA256
    filename VARCHAR(255) NOT NULL,
    upload_date TIMESTAMP DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'imported',  -- imported, processed, failed
    s3_path VARCHAR(500)  -- Pfad in RustFS
);

CREATE TABLE media_frame (
    id SERIAL PRIMARY KEY,
    media_item_id INTEGER REFERENCES media_item(id) ON DELETE CASCADE,
    frame_number INTEGER NOT NULL,
    s3_path VARCHAR(500) NOT NULL,
    timestamp INTERVAL,  -- z.B. 00:01:30
    created_at TIMESTAMP DEFAULT NOW()
);

-- Timescale Hypertable für Time-Queries
SELECT create_hypertable('media_frame', 'created_at');

CREATE TABLE model_instance (
    id SERIAL PRIMARY KEY,
    frame_id INTEGER REFERENCES media_frame(id) ON DELETE CASCADE,
    keypoints JSONB,  -- OpenPose: [{point_type: 'nose', x: 100, y: 200, confidence: 0.9}, ...]
    pose_class VARCHAR(50),  -- z.B. standing, hogtie
    outfit_items JSONB,  -- [{code: 'LATEX_GLOVES_BLACK', confidence: 0.8}, ...] (RF-DETR)
    restraint_items JSONB,  -- [{code: 'ROPE_WRIST_MILD', confidence: 0.7}, ...] (RT-DETR)
    embedding VECTOR(512),  -- OSNet: Normiert
    analysis_failed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Hypertable für Instanzen
SELECT create_hypertable('model_instance', 'created_at');

CREATE TABLE model_identity (
    id SERIAL PRIMARY KEY,
    first_seen TIMESTAMP DEFAULT NOW(),
    last_seen TIMESTAMP DEFAULT NOW(),
    total_instances INTEGER DEFAULT 0,
    embedding VECTOR(512),  -- Average-Embedding
    semantic_summary TEXT  -- Grok: 'Beschreibung basierend auf Multi-Call'
);

CREATE TABLE model_pose_point (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES model_instance(id) ON DELETE CASCADE,
    point_type VARCHAR(50) NOT NULL,  -- z.B. nose, left_wrist
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    confidence FLOAT CHECK (confidence > 0.5)
);

CREATE TABLE model_outfit_item (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES model_instance(id) ON DELETE CASCADE,
    lookup_id INTEGER REFERENCES lookup_outfit_items(id),
    confidence FLOAT CHECK (confidence > 0.5)
);

CREATE TABLE model_restraint_item (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES model_instance(id) ON DELETE CASCADE,
    lookup_id INTEGER REFERENCES lookup_restraint_items(id),
    confidence FLOAT CHECK (confidence > 0.5)
);

-- Views und Indizes (Kapitel 6.2)
CREATE INDEX idx_media_item_hash ON media_item(hash);
CREATE INDEX idx_model_instance_embedding ON model_instance USING hnsw (embedding vector_cosine_ops);  -- Für ReID (Cosine >0.80)
CREATE INDEX idx_model_instance_pose ON model_instance(pose_class);

CREATE VIEW vw_model_item_stats AS
SELECT 
    mi.pose_class,
    oi.material,
    ri.position,
    COUNT(*) as frequency,
    AVG(mi.confidence) as avg_confidence
FROM model_instance mi
LEFT JOIN model_outfit_item moi ON mi.id = moi.instance_id
LEFT JOIN lookup_outfit_items oi ON moi.lookup_id = oi.id
LEFT JOIN model_restraint_item mri ON mi.id = mri.instance_id
LEFT JOIN lookup_restraint_items ri ON mri.lookup_id = ri.id
GROUP BY mi.pose_class, oi.material, ri.position;

-- Constraints (Kapitel 6.3)
ALTER TABLE model_instance ADD CONSTRAINT embedding_norm CHECK (embedding <-> '[0]'::vector = 1.0);  -- L2-Norm =1
-- Weitere CHECKs/FKs bereits implizit

-- Beispiel-Query für ReID (FR-2.5)
-- SELECT * FROM model_identity ORDER BY embedding <=> '[0.1,0.2,...]'::vector LIMIT 5;  -- Top-5, Cosine >0.80