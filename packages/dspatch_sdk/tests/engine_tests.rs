//! Tests for the engine startup module.

use dspatch_sdk::engine::config::EngineConfig;
use dspatch_sdk::engine::startup::EngineRuntime;

#[test]
fn engine_runtime_creation_records_start_time() {
    let config = EngineConfig::default();
    let runtime = EngineRuntime::new(config);
    assert!(runtime.uptime_seconds() < 2);
}

#[test]
fn engine_runtime_exposes_config() {
    let mut config = EngineConfig::default();
    config.client_api_port = 12345;
    let runtime = EngineRuntime::new(config);
    assert_eq!(runtime.config().client_api_port, 12345);
}

#[test]
fn engine_open_database_creates_and_migrates() {
    use dspatch_sdk::engine::startup::open_database;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");

    let db = open_database(&db_path).expect("open_database should succeed");

    let conn = db.conn();
    let count: i32 = conn
        .query_row("SELECT COUNT(*) FROM workspaces", [], |row| row.get(0))
        .expect("workspaces table should exist");
    assert_eq!(count, 0);
}

#[test]
fn engine_open_database_is_idempotent() {
    use dspatch_sdk::engine::startup::open_database;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");

    let _db1 = open_database(&db_path).expect("first open should succeed");
    drop(_db1);
    let db2 = open_database(&db_path).expect("second open should succeed");

    let conn = db2.conn();
    let count: i32 = conn
        .query_row("SELECT COUNT(*) FROM workspaces", [], |row| row.get(0))
        .expect("workspaces table should exist on re-open");
    assert_eq!(count, 0);
}
