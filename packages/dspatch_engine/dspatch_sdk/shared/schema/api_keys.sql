CREATE TABLE IF NOT EXISTS api_keys (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    provider_label TEXT NOT NULL,
    encrypted_key BLOB NOT NULL,
    display_hint TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);