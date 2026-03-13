CREATE TABLE IF NOT EXISTS sync_outbox (
    id TEXT NOT NULL PRIMARY KEY,
    table_name TEXT NOT NULL,
    row_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    data TEXT,
    lamport_ts INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);