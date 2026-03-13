CREATE TABLE IF NOT EXISTS signal_identities (
    address TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    identity_key BLOB NOT NULL,
    trust_level INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (address, device_id)
);