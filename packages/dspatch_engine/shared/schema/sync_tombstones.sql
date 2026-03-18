CREATE TABLE IF NOT EXISTS sync_tombstones (
    table_name TEXT NOT NULL,
    row_id TEXT NOT NULL,
    deleted_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    device_id TEXT NOT NULL,
    lamport_ts INTEGER NOT NULL,
    PRIMARY KEY (table_name, row_id)
);
