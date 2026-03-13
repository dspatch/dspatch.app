// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the database module.

use std::sync::Arc;

use dspatch_sdk::db::health::{open_checked, DbHealthStatus};
use dspatch_sdk::db::key_manager::DatabaseKeyManager;
use dspatch_sdk::db::migrations::SCHEMA_VERSION;
use dspatch_sdk::db::reactive::{watch_query, TableChangeTracker};
use dspatch_sdk::db::schema::TABLE_NAMES;
use dspatch_sdk::db::Database;

use futures::StreamExt;

// ---------------------------------------------------------------------------
// Schema creation
// ---------------------------------------------------------------------------

#[test]
fn test_schema_creation_all_15_tables() {
    let db = Database::open_in_memory().expect("Failed to open in-memory database");

    // Verify all 15 tables exist.
    let conn = db.conn();
    let mut stmt = conn
        .prepare(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .unwrap();

    let tables: Vec<String> = stmt
        .query_map([], |row| row.get(0))
        .unwrap()
        .filter_map(|r| r.ok())
        .collect();

    assert_eq!(tables.len(), 27, "Expected 27 tables, got: {tables:?}");

    // Verify each expected table name is present.
    for &expected in TABLE_NAMES {
        assert!(
            tables.contains(&expected.to_string()),
            "Missing table: {expected}"
        );
    }
}

#[test]
fn test_schema_version_is_set() {
    let db = Database::open_in_memory().expect("Failed to open in-memory database");
    let conn = db.conn();

    let version: i32 = conn
        .pragma_query_value(None, "user_version", |row| row.get(0))
        .unwrap();

    assert_eq!(version, SCHEMA_VERSION);
}

// ---------------------------------------------------------------------------
// Migrations
// ---------------------------------------------------------------------------

#[test]
fn test_migrations_run_without_error() {
    // Create a database with version 1 schema (before migrations), then
    // re-open to trigger migration.
    use dspatch_sdk::db::migrations::run_migrations;
    use rusqlite::Connection;

    let conn = Connection::open_in_memory().unwrap();

    // Create a minimal v1 schema: only the tables that migrations touch.
    conn.execute_batch(
        "CREATE TABLE workspaces (id TEXT PRIMARY KEY, name TEXT, project_path TEXT, created_at TEXT, updated_at TEXT);
         CREATE TABLE workspace_runs (id TEXT PRIMARY KEY, workspace_id TEXT, run_number INTEGER, status TEXT DEFAULT 'starting', container_id TEXT, server_port INTEGER, api_key TEXT, started_at TEXT, stopped_at TEXT);
         CREATE TABLE workspace_agents (id TEXT PRIMARY KEY, run_id TEXT, agent_key TEXT, instance_id TEXT, display_name TEXT, status TEXT DEFAULT 'disconnected', created_at TEXT, updated_at TEXT);
         CREATE TABLE agent_messages (id TEXT PRIMARY KEY, run_id TEXT, role TEXT, content TEXT, model TEXT, input_tokens INTEGER, output_tokens INTEGER, instance_id TEXT, turn_id TEXT, agent_key TEXT, is_partial INTEGER, created_at TEXT);
         CREATE TABLE agent_activity_events (id TEXT PRIMARY KEY, run_id TEXT, agent_key TEXT, instance_id TEXT, turn_id TEXT, event_type TEXT, data_json TEXT, timestamp TEXT);
         CREATE TABLE agent_templates (id TEXT PRIMARY KEY, name TEXT, source_type TEXT, source_path TEXT, git_url TEXT, git_branch TEXT, entry_point TEXT, description TEXT, required_env_json TEXT DEFAULT '[]', required_mounts_json TEXT DEFAULT '[]', hub_slug TEXT, hub_author TEXT, hub_category TEXT, hub_tags_json TEXT DEFAULT '[]', hub_version INTEGER, hub_repo_url TEXT, hub_commit_hash TEXT, created_at TEXT, updated_at TEXT);",
    )
    .unwrap();

    // Run all migrations from v1.
    run_migrations(&conn, 1).expect("Migrations should succeed");
}

// ---------------------------------------------------------------------------
// TableChangeTracker
// ---------------------------------------------------------------------------

#[test]
fn test_change_tracker_fires_on_notify() {
    let tracker = TableChangeTracker::new();
    let mut rx = tracker.subscribe(&["test_table"]);

    // No notification yet.
    assert!(rx.try_recv().is_err());

    // Fire notification.
    tracker.notify("test_table");

    // Should receive it.
    assert!(rx.try_recv().is_ok());
}

#[test]
fn test_change_tracker_fires_on_insert_update_delete() {
    let db = Database::open_in_memory().expect("Failed to open in-memory database");
    let tracker = db.tracker();

    let mut rx = tracker.subscribe(&["workspaces"]);

    // INSERT
    {
        let conn = db.conn();
        conn.execute(
            "INSERT INTO workspaces (id, name, project_path) VALUES (?1, ?2, ?3)",
            rusqlite::params!["ws-1", "Test Workspace", "/tmp/test"],
        )
        .unwrap();
    }
    assert!(rx.try_recv().is_ok(), "Should fire on INSERT");

    // UPDATE
    {
        let conn = db.conn();
        conn.execute(
            "UPDATE workspaces SET name = ?1 WHERE id = ?2",
            rusqlite::params!["Updated Name", "ws-1"],
        )
        .unwrap();
    }
    assert!(rx.try_recv().is_ok(), "Should fire on UPDATE");

    // DELETE
    {
        let conn = db.conn();
        conn.execute(
            "DELETE FROM workspaces WHERE id = ?1",
            rusqlite::params!["ws-1"],
        )
        .unwrap();
    }
    assert!(rx.try_recv().is_ok(), "Should fire on DELETE");
}

// ---------------------------------------------------------------------------
// watch_query
// ---------------------------------------------------------------------------

#[tokio::test]
async fn test_watch_query_emits_initial_and_on_change() {
    let db = Database::open_in_memory().expect("Failed to open in-memory database");
    let tracker = Arc::clone(db.tracker());
    let conn_arc = Arc::clone(db.conn_arc());

    let mut stream = watch_query(&tracker, &conn_arc, &["preferences"], |conn| {
        let mut stmt = conn.prepare("SELECT key, value FROM preferences").unwrap();
        let rows: Vec<(String, String)> = stmt
            .query_map([], |row| Ok((row.get(0)?, row.get(1)?)))
            .unwrap()
            .filter_map(|r| r.ok())
            .collect();
        Ok(rows)
    });

    // Initial emission — empty table.
    let first = stream.next().await.expect("Should get initial result");
    let first = first.expect("Initial query should succeed");
    assert!(first.is_empty(), "Preferences should start empty");

    // Insert a row (this happens on the same connection, which triggers the
    // update hook and the stream should re-emit).
    {
        let conn = db.conn();
        conn.execute(
            "INSERT INTO preferences (key, value) VALUES (?1, ?2)",
            rusqlite::params!["theme", "dark"],
        )
        .unwrap();
    }

    // The stream should emit again with the new data.
    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Should get second result within timeout")
        .expect("Stream should not end");
    let second = second.expect("Second query should succeed");
    assert_eq!(second.len(), 1);
    assert_eq!(second[0].0, "theme");
    assert_eq!(second[0].1, "dark");
}

// ---------------------------------------------------------------------------
// DatabaseKeyManager
// ---------------------------------------------------------------------------

#[test]
fn test_hash_username_produces_expected_output() {
    // SHA-256 of "alice" is 2bd806c9... (first 16 hex chars).
    let hash = DatabaseKeyManager::hash_username("alice");
    assert_eq!(hash.len(), 16);
    assert_eq!(hash, "2bd806c97f0e00af");
}

#[test]
fn test_hash_username_deterministic() {
    let h1 = DatabaseKeyManager::hash_username("bob");
    let h2 = DatabaseKeyManager::hash_username("bob");
    assert_eq!(h1, h2);
}

#[test]
fn test_get_or_create_key_generates_and_retrieves() {
    use dspatch_sdk::db::key_manager::testing::InMemorySecretStore;

    let store = Box::new(InMemorySecretStore::new());
    let km = DatabaseKeyManager::new(store);

    let key1 = km.get_or_create_key(None).expect("Should generate key");
    let key2 = km.get_or_create_key(None).expect("Should retrieve key");
    assert_eq!(key1, key2, "Same key should be returned on second call");

    // User-specific key should be different.
    let user_key = km
        .get_or_create_key(Some("abc123"))
        .expect("Should generate user key");
    assert_ne!(key1, user_key, "User key should differ from anonymous key");
}

// ---------------------------------------------------------------------------
// DbHealth
// ---------------------------------------------------------------------------

#[test]
fn test_open_checked_fresh_database() {
    let dir = tempfile::tempdir().unwrap();
    let db_path = dir.path().join("test.db");

    let (status, _db) = open_checked(&db_path, None).expect("Should open fresh database");
    assert_eq!(status, DbHealthStatus::Ok);
}

#[test]
fn test_open_checked_existing_healthy_database() {
    let dir = tempfile::tempdir().unwrap();
    let db_path = dir.path().join("test.db");

    // Create it first.
    {
        let _db = Database::open(&db_path, None).expect("Should create database");
    }

    // Re-open with health check.
    let (status, _db) = open_checked(&db_path, None).expect("Should open existing database");
    assert_eq!(status, DbHealthStatus::Ok);
}

#[test]
fn test_open_checked_corrupt_database_resets() {
    let dir = tempfile::tempdir().unwrap();
    let db_path = dir.path().join("test.db");

    // Write garbage to the file to simulate corruption.
    std::fs::write(&db_path, b"this is not a valid sqlite database").unwrap();

    let (status, _db) = open_checked(&db_path, None).expect("Should reset and reopen");
    assert_eq!(status, DbHealthStatus::Reset);
}

// ---------------------------------------------------------------------------
// Migration v11 — ephemeral state tables
// ---------------------------------------------------------------------------

#[test]
fn migration_v11_creates_ephemeral_state_tables() {
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    dspatch_sdk::db::migrations::create_tables(&conn).unwrap();
    conn.execute_batch(
        "INSERT INTO workspaces (id, name, project_path) VALUES ('w1', 'test', '/tmp');
         INSERT INTO workspace_runs (id, workspace_id, run_number) VALUES ('r1', 'w1', 1);"
    ).unwrap();

    conn.execute_batch(
        "INSERT INTO agent_instance_states (instance_id, run_id, agent_key, state) VALUES ('i1', 'r1', 'a1', 'idle');"
    ).unwrap();
    conn.execute_batch(
        "INSERT INTO agent_connection_status (agent_key, run_id, connected) VALUES ('a1', 'r1', 1);"
    ).unwrap();
    conn.execute_batch(
        "INSERT INTO container_health (run_id, status) VALUES ('r1', 'running');"
    ).unwrap();
    conn.execute_batch(
        "INSERT INTO workspace_run_status (run_id, status) VALUES ('r1', 'running');"
    ).unwrap();
}
