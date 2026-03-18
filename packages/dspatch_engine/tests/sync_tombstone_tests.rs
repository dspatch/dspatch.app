// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Tests for sync tombstones (soft deletes).

use dspatch_engine::sync::materializer::{ChangeMaterializer, cleanup_old_tombstones};
use dspatch_engine::sync::outbox_hook::{install_outbox_triggers, set_sync_device_id};
use dspatch_engine::sync::{SyncChange, SyncOp};

/// Helper: create an in-memory DB with all required tables for tombstone tests.
fn setup_db() -> rusqlite::Connection {
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE api_keys (id TEXT PRIMARY KEY, name TEXT);
         CREATE TABLE sync_outbox (
             id TEXT PRIMARY KEY, table_name TEXT, row_id TEXT,
             operation TEXT, data TEXT, lamport_ts INTEGER,
             device_id TEXT, created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
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
    conn
}

#[test]
fn tombstone_created_on_delete() {
    let conn = setup_db();
    install_outbox_triggers(&conn).unwrap();
    set_sync_device_id(&conn, "device-a").unwrap();

    // Insert a row, then delete it.
    conn.execute(
        "INSERT INTO api_keys (id, name) VALUES ('key1', 'My Key')",
        [],
    )
    .unwrap();
    conn.execute("DELETE FROM api_keys WHERE id = 'key1'", [])
        .unwrap();

    // Verify tombstone was created.
    let (table, row_id, device_id): (String, String, String) = conn
        .query_row(
            "SELECT table_name, row_id, device_id FROM sync_tombstones WHERE table_name = 'api_keys' AND row_id = 'key1'",
            [],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
        )
        .unwrap();
    assert_eq!(table, "api_keys");
    assert_eq!(row_id, "key1");
    assert_eq!(device_id, "device-a");

    // Verify lamport_ts is set (should be > 0).
    let ts: i64 = conn
        .query_row(
            "SELECT lamport_ts FROM sync_tombstones WHERE table_name = 'api_keys' AND row_id = 'key1'",
            [],
            |r| r.get(0),
        )
        .unwrap();
    assert!(ts > 0);
}

#[test]
fn tombstone_prevents_stale_insert() {
    let conn = setup_db();

    // Manually insert a tombstone with lamport_ts = 10.
    conn.execute(
        "INSERT INTO sync_tombstones (table_name, row_id, device_id, lamport_ts) VALUES ('api_keys', 'key1', 'device-b', 10)",
        [],
    )
    .unwrap();

    // Attempt to materialize an insert with a lower lamport_ts (5).
    let change = SyncChange {
        id: "change-1".to_string(),
        table: "api_keys".to_string(),
        row_id: "key1".to_string(),
        operation: SyncOp::Insert,
        data: serde_json::json!({"id": "key1", "name": "Stale Key"}),
        lamport_ts: 5,
        device_id: "device-a".to_string(),
    };

    // Set device_id to 'local' so triggers don't fire during materialization.
    conn.execute(
        "UPDATE sync_config SET device_id = 'local' WHERE id = 1",
        [],
    )
    .unwrap();

    ChangeMaterializer::apply(&conn, &change).unwrap();

    // Row should NOT exist — tombstone prevented the insert.
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM api_keys WHERE id = 'key1'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 0, "Stale insert should be blocked by newer tombstone");

    // Now try with a higher lamport_ts (15) — should succeed.
    let change2 = SyncChange {
        id: "change-2".to_string(),
        table: "api_keys".to_string(),
        row_id: "key1".to_string(),
        operation: SyncOp::Insert,
        data: serde_json::json!({"id": "key1", "name": "Fresh Key"}),
        lamport_ts: 15,
        device_id: "device-a".to_string(),
    };

    ChangeMaterializer::apply(&conn, &change2).unwrap();

    let name: String = conn
        .query_row(
            "SELECT name FROM api_keys WHERE id = 'key1'",
            [],
            |r| r.get(0),
        )
        .unwrap();
    assert_eq!(name, "Fresh Key");
}

#[test]
fn tombstone_cleanup_removes_old_entries() {
    let conn = setup_db();

    // Insert a tombstone with deleted_at far in the past (60 days ago).
    let old_ts = chrono::Utc::now().timestamp() - (60 * 24 * 60 * 60);
    conn.execute(
        "INSERT INTO sync_tombstones (table_name, row_id, deleted_at, device_id, lamport_ts) VALUES ('api_keys', 'old-key', ?1, 'dev', 1)",
        rusqlite::params![old_ts],
    )
    .unwrap();

    // Insert a recent tombstone.
    conn.execute(
        "INSERT INTO sync_tombstones (table_name, row_id, device_id, lamport_ts) VALUES ('api_keys', 'new-key', 'dev', 2)",
        [],
    )
    .unwrap();

    let deleted = cleanup_old_tombstones(&conn).unwrap();
    assert_eq!(deleted, 1);

    // Only the recent tombstone should remain.
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM sync_tombstones", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 1);

    let remaining: String = conn
        .query_row(
            "SELECT row_id FROM sync_tombstones",
            [],
            |r| r.get(0),
        )
        .unwrap();
    assert_eq!(remaining, "new-key");
}
