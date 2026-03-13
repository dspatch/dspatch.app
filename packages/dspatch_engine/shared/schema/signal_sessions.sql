CREATE TABLE IF NOT EXISTS signal_sessions (
    address TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    record BLOB NOT NULL,
    PRIMARY KEY (address, device_id)
);