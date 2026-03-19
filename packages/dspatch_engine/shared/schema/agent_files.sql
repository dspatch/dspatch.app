CREATE TABLE IF NOT EXISTS agent_files (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id) ON DELETE CASCADE,
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    file_path TEXT NOT NULL,
    operation TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);