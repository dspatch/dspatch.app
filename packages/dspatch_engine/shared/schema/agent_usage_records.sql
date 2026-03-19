CREATE TABLE IF NOT EXISTS agent_usage_records (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id) ON DELETE CASCADE,
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    model TEXT NOT NULL,
    input_tokens INTEGER NOT NULL,
    output_tokens INTEGER NOT NULL,
    cache_read_tokens INTEGER NOT NULL,
    cache_write_tokens INTEGER NOT NULL,
    cost_usd REAL NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    _lamport_ts INTEGER NOT NULL DEFAULT 0,
    _sync_device_id TEXT NOT NULL DEFAULT ''
);