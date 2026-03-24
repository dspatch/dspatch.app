-- Known peer devices for safe outbox pruning.
-- Populated from the backend GET /api/devices endpoint.
-- Outbox entries are only pruned when ALL known peers have received them.
CREATE TABLE IF NOT EXISTS sync_known_devices (
    device_id TEXT NOT NULL PRIMARY KEY,
    name TEXT,
    device_type TEXT,
    platform TEXT,
    last_refreshed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
