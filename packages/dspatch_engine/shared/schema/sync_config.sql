CREATE TABLE IF NOT EXISTS sync_config (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    device_id TEXT NOT NULL DEFAULT 'local'
);
INSERT OR IGNORE INTO sync_config (id, device_id) VALUES (1, 'local');
