CREATE TABLE IF NOT EXISTS workspace_run_status (
    run_id TEXT NOT NULL PRIMARY KEY REFERENCES workspace_runs(id),
    status TEXT NOT NULL DEFAULT 'starting',
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
