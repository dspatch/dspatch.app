CREATE TABLE IF NOT EXISTS agent_connection_status (
    agent_key TEXT NOT NULL,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id) ON DELETE CASCADE,
    connected INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    PRIMARY KEY (agent_key, run_id)
);
