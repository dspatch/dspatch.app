CREATE TABLE IF NOT EXISTS workspace_agents (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id) ON DELETE CASCADE,
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    chain_json TEXT NOT NULL DEFAULT '[]',
    status TEXT NOT NULL DEFAULT 'disconnected',
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    _lamport_ts INTEGER NOT NULL DEFAULT 0,
    _sync_device_id TEXT NOT NULL DEFAULT ''
);