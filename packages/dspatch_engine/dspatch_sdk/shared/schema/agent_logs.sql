CREATE TABLE IF NOT EXISTS agent_logs (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    level TEXT NOT NULL,
    message TEXT NOT NULL,
    source TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);