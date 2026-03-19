CREATE TABLE IF NOT EXISTS container_health (
    run_id TEXT NOT NULL PRIMARY KEY REFERENCES workspace_runs(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'unknown',
    error_message TEXT,
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
