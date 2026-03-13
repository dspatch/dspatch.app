use dspatch_sdk::sync::outbox_hook::OutboxHook;

#[test]
fn outbox_hook_records_change_for_synced_table() {
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE api_keys (id TEXT PRIMARY KEY, name TEXT);
         CREATE TABLE sync_outbox (
             id TEXT PRIMARY KEY, table_name TEXT, row_id TEXT,
             operation TEXT, data TEXT, lamport_ts INTEGER,
             device_id TEXT, created_at TEXT
         );",
    )
    .unwrap();

    let hook = OutboxHook::new("test-device".to_string());
    hook.install(&conn);

    // Insert into a synced table.
    conn.execute(
        "INSERT INTO api_keys (id, name) VALUES ('key1', 'My Key')",
        [],
    )
    .unwrap();

    // Flush pending changes.
    OutboxHook::flush_pending(&conn);

    // Verify outbox has an entry.
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM sync_outbox", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 1);

    let (table, op): (String, String) = conn
        .query_row(
            "SELECT table_name, operation FROM sync_outbox LIMIT 1",
            [],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )
        .unwrap();
    assert_eq!(table, "api_keys");
    assert_eq!(op, "insert");
}

#[test]
fn outbox_hook_ignores_device_local_table() {
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE signal_identities (
             address TEXT, device_id INTEGER, identity_key BLOB,
             trust_level INTEGER, PRIMARY KEY (address, device_id)
         );
         CREATE TABLE sync_outbox (
             id TEXT PRIMARY KEY, table_name TEXT, row_id TEXT,
             operation TEXT, data TEXT, lamport_ts INTEGER,
             device_id TEXT, created_at TEXT
         );",
    )
    .unwrap();

    let hook = OutboxHook::new("test-device".to_string());
    hook.install(&conn);

    conn.execute(
        "INSERT INTO signal_identities (address, device_id, identity_key, trust_level) \
         VALUES ('alice', 1, X'00', 1)",
        [],
    )
    .unwrap();

    OutboxHook::flush_pending(&conn);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM sync_outbox", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 0);
}

#[test]
fn outbox_hook_ignores_outbox_writes() {
    // Writing to sync_outbox itself must not trigger recursive recording.
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE sync_outbox (
             id TEXT PRIMARY KEY, table_name TEXT, row_id TEXT,
             operation TEXT, data TEXT, lamport_ts INTEGER,
             device_id TEXT, created_at TEXT
         );",
    )
    .unwrap();

    let hook = OutboxHook::new("test-device".to_string());
    hook.install(&conn);

    conn.execute(
        "INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id, created_at) \
         VALUES ('x', 't', 'r', 'insert', '{}', 1, 'dev', '2026-01-01')",
        [],
    )
    .unwrap();

    OutboxHook::flush_pending(&conn);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM sync_outbox", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 1); // Only the explicit insert, no recursive trigger.
}
