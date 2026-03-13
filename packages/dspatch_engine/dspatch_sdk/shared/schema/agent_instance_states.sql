CREATE TABLE IF NOT EXISTS agent_instance_states (
    instance_id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'idle',
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
