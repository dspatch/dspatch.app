CREATE TABLE IF NOT EXISTS preferences (
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL,
    _lamport_ts INTEGER NOT NULL DEFAULT 0,
    _sync_device_id TEXT NOT NULL DEFAULT ''
);