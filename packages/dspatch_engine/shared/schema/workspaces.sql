CREATE TABLE IF NOT EXISTS workspaces (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    project_path TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    _lamport_ts INTEGER NOT NULL DEFAULT 0,
    _sync_device_id TEXT NOT NULL DEFAULT ''
);