CREATE TABLE IF NOT EXISTS instance_results (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id) ON DELETE CASCADE,
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT NOT NULL,
    request_id TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);