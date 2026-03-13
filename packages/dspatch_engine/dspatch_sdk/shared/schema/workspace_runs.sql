CREATE TABLE IF NOT EXISTS workspace_runs (
    id TEXT NOT NULL PRIMARY KEY,
    workspace_id TEXT NOT NULL REFERENCES workspaces(id),
    run_number INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'starting',
    container_id TEXT,
    server_port INTEGER,
    api_key TEXT,
    started_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    stopped_at TEXT
);