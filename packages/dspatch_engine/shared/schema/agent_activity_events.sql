CREATE TABLE IF NOT EXISTS agent_activity_events (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    event_type TEXT NOT NULL,
    data_json TEXT,
    content TEXT,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);