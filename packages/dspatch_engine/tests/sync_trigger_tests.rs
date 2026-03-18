// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use rusqlite::Connection;

#[test]
fn trigger_captures_insert_with_data() {
    let conn = setup_test_db();
    conn.execute(
        "UPDATE sync_config SET device_id = 'device-a' WHERE id = 1",
        [],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider_label, encrypted_key) VALUES ('k1', 'My Key', 'openai', X'AA')",
        [],
    )
    .unwrap();
    let (op, data, device_id): (String, String, String) = conn
        .query_row(
            "SELECT operation, data, device_id FROM sync_outbox WHERE table_name = 'api_keys'",
            [],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )
        .unwrap();
    assert_eq!(op, "insert");
    assert_eq!(device_id, "device-a");
    let parsed: serde_json::Value = serde_json::from_str(&data).unwrap();
    assert_eq!(parsed["id"], "k1");
    assert_eq!(parsed["name"], "My Key");
    assert_eq!(parsed["provider_label"], "openai");
}

#[test]
fn trigger_captures_insert_on_table_with_non_id_pk() {
    let conn = setup_test_db();
    conn.execute(
        "UPDATE sync_config SET device_id = 'device-a' WHERE id = 1",
        [],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO preferences (key, value) VALUES ('theme', 'dark')",
        [],
    )
    .unwrap();
    let (op, row_id, data): (String, String, String) = conn
        .query_row(
            "SELECT operation, row_id, data FROM sync_outbox WHERE table_name = 'preferences'",
            [],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )
        .unwrap();
    assert_eq!(op, "insert");
    assert_eq!(row_id, "theme");
    let parsed: serde_json::Value = serde_json::from_str(&data).unwrap();
    assert_eq!(parsed["key"], "theme");
    assert_eq!(parsed["value"], "dark");
}

#[test]
fn trigger_does_not_fire_when_device_id_is_local() {
    let conn = setup_test_db();
    // device_id defaults to 'local', so triggers should not fire.
    conn.execute(
        "INSERT INTO api_keys (id, name, provider_label, encrypted_key) VALUES ('k2', 'Key2', 'anthropic', X'BB')",
        [],
    )
    .unwrap();
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM sync_outbox", [], |row| row.get(0))
        .unwrap();
    assert_eq!(count, 0);
}

#[test]
fn trigger_captures_update_with_new_data() {
    let conn = setup_test_db();
    conn.execute(
        "UPDATE sync_config SET device_id = 'device-a' WHERE id = 1",
        [],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider_label, encrypted_key) VALUES ('k3', 'Old', 'openai', X'CC')",
        [],
    )
    .unwrap();
    conn.execute(
        "UPDATE api_keys SET name = 'New' WHERE id = 'k3'",
        [],
    )
    .unwrap();
    // The explicit UPDATE fires an outbox entry. Version-stamp UPDATEs from
    // the INSERT trigger also produce 'update' entries. Get the latest one.
    let (op, data): (String, String) = conn
        .query_row(
            "SELECT operation, data FROM sync_outbox WHERE operation = 'update' ORDER BY lamport_ts DESC LIMIT 1",
            [],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap();
    assert_eq!(op, "update");
    let parsed: serde_json::Value = serde_json::from_str(&data).unwrap();
    assert_eq!(parsed["name"], "New");
}

#[test]
fn trigger_captures_delete_with_old_id() {
    let conn = setup_test_db();
    conn.execute(
        "UPDATE sync_config SET device_id = 'device-a' WHERE id = 1",
        [],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider_label, encrypted_key) VALUES ('k4', 'x', 'y', X'DD')",
        [],
    )
    .unwrap();
    conn.execute("DELETE FROM api_keys WHERE id = 'k4'", [])
        .unwrap();
    let (op, data): (String, String) = conn
        .query_row(
            "SELECT operation, data FROM sync_outbox WHERE operation = 'delete'",
            [],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap();
    assert_eq!(op, "delete");
    let parsed: serde_json::Value = serde_json::from_str(&data).unwrap();
    assert_eq!(parsed["id"], "k4");
}

#[test]
fn lamport_clock_increments_per_change() {
    let conn = setup_test_db();
    conn.execute(
        "UPDATE sync_config SET device_id = 'device-a' WHERE id = 1",
        [],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider_label, encrypted_key) VALUES ('a', 'k1', 'v1', X'01')",
        [],
    )
    .unwrap();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider_label, encrypted_key) VALUES ('b', 'k2', 'v2', X'02')",
        [],
    )
    .unwrap();
    let mut stmt = conn
        .prepare("SELECT lamport_ts FROM sync_outbox ORDER BY lamport_ts ASC")
        .unwrap();
    let timestamps: Vec<i64> = stmt
        .query_map([], |row| row.get(0))
        .unwrap()
        .map(|r| r.unwrap())
        .collect();
    // Each INSERT produces 2 entries (insert + version-stamp update).
    // Verify lamport clock strictly increases across all entries.
    assert!(timestamps.len() >= 2);
    for i in 1..timestamps.len() {
        assert!(timestamps[i] > timestamps[i - 1], "lamport must increase: {} > {}", timestamps[i], timestamps[i-1]);
    }
    assert_eq!(timestamps[1], 2);
}

#[test]
fn bootstrap_lamport_clock_from_outbox() {
    let conn = setup_test_db();
    // Manually insert an outbox entry with a high lamport_ts.
    conn.execute(
        "INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id, created_at) \
         VALUES ('manual', 'api_keys', 'r1', 'insert', '{}', 42, 'dev', '2026-01-01')",
        [],
    )
    .unwrap();
    dspatch_engine::sync::outbox_hook::bootstrap_lamport_clock(&conn).unwrap();
    let ts: i64 = conn
        .query_row("SELECT ts FROM sync_lamport WHERE id = 1", [], |row| {
            row.get(0)
        })
        .unwrap();
    assert_eq!(ts, 42);
}

fn setup_test_db() -> Connection {
    let conn = Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE sync_outbox (
            id TEXT NOT NULL PRIMARY KEY,
            table_name TEXT NOT NULL,
            row_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            data TEXT,
            lamport_ts INTEGER NOT NULL,
            device_id TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
        );
        CREATE TABLE sync_lamport (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            ts INTEGER NOT NULL DEFAULT 0
        );
        INSERT INTO sync_lamport (id, ts) VALUES (1, 0);
        CREATE TABLE sync_config (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            device_id TEXT NOT NULL DEFAULT 'local'
        );
        INSERT INTO sync_config (id, device_id) VALUES (1, 'local');
        CREATE TABLE api_keys (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            provider_label TEXT NOT NULL,
            encrypted_key BLOB NOT NULL,
            display_hint TEXT,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
            _lamport_ts INTEGER NOT NULL DEFAULT 0,
            _sync_device_id TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE preferences (
            key TEXT NOT NULL PRIMARY KEY,
            value TEXT NOT NULL,
            _lamport_ts INTEGER NOT NULL DEFAULT 0,
            _sync_device_id TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE sync_tombstones (
            table_name TEXT NOT NULL,
            row_id TEXT NOT NULL,
            deleted_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            device_id TEXT NOT NULL,
            lamport_ts INTEGER NOT NULL,
            PRIMARY KEY (table_name, row_id)
        );",
    )
    .unwrap();

    // Install triggers on these tables.
    dspatch_engine::sync::outbox_hook::install_outbox_triggers(&conn).unwrap();

    conn
}
