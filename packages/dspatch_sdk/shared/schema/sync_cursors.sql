CREATE TABLE IF NOT EXISTS sync_cursors (
    device_id TEXT NOT NULL,
    table_name TEXT NOT NULL,
    high_water_mark INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (device_id, table_name)
);