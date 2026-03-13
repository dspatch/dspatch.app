CREATE TABLE IF NOT EXISTS signal_sender_keys (
    sender_address TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    distribution_id TEXT NOT NULL,
    record BLOB NOT NULL,
    PRIMARY KEY (sender_address, device_id, distribution_id)
);