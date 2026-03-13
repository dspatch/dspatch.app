use dspatch_engine::sync::materializer::ChangeMaterializer;
use dspatch_engine::sync::message::{SyncChange, SyncOp};
use serde_json::json;

fn test_db() -> rusqlite::Connection {
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE api_keys (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            provider TEXT NOT NULL,
            encrypted_key BLOB
        );",
    )
    .unwrap();
    conn
}

#[test]
fn materializer_inserts_row() {
    let conn = test_db();

    let change = SyncChange {
        id: "c1".into(),
        table: "api_keys".into(),
        row_id: "key1".into(),
        operation: SyncOp::Insert,
        data: json!({
            "id": "key1",
            "name": "My Key",
            "provider": "openai",
            "encrypted_key": null
        }),
        lamport_ts: 1,
        device_id: "remote-device".into(),
    };

    ChangeMaterializer::apply(&conn, &change).unwrap();

    let name: String = conn
        .query_row("SELECT name FROM api_keys WHERE id = 'key1'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(name, "My Key");
}

#[test]
fn materializer_updates_row() {
    let conn = test_db();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider) VALUES ('key1', 'Old', 'openai')",
        [],
    )
    .unwrap();

    let change = SyncChange {
        id: "c2".into(),
        table: "api_keys".into(),
        row_id: "key1".into(),
        operation: SyncOp::Update,
        data: json!({
            "id": "key1",
            "name": "Updated",
            "provider": "anthropic",
            "encrypted_key": null
        }),
        lamport_ts: 2,
        device_id: "remote-device".into(),
    };

    ChangeMaterializer::apply(&conn, &change).unwrap();

    let name: String = conn
        .query_row("SELECT name FROM api_keys WHERE id = 'key1'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(name, "Updated");
}

#[test]
fn materializer_deletes_row() {
    let conn = test_db();
    conn.execute(
        "INSERT INTO api_keys (id, name, provider) VALUES ('key1', 'ToDelete', 'openai')",
        [],
    )
    .unwrap();

    let change = SyncChange {
        id: "c3".into(),
        table: "api_keys".into(),
        row_id: "key1".into(),
        operation: SyncOp::Delete,
        data: json!(null),
        lamport_ts: 3,
        device_id: "remote-device".into(),
    };

    ChangeMaterializer::apply(&conn, &change).unwrap();

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM api_keys", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 0);
}
