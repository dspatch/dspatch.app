CREATE TABLE IF NOT EXISTS signal_signed_prekeys (
    id INTEGER PRIMARY KEY,
    record BLOB NOT NULL,
    created_at TEXT NOT NULL
);