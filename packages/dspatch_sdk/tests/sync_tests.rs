// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the P2P sync engine.

use std::collections::HashMap;
use std::sync::Arc;

use dspatch_sdk::db::Database;
use dspatch_sdk::sync::message::{SyncChange, SyncMessage, SyncOp};
use dspatch_sdk::sync::peer_connection::PeerConnectionManager;
use dspatch_sdk::sync::sync_engine::SyncEngine;

use ed25519_dalek::SigningKey;
use rand::rngs::OsRng;
use tokio::sync::{mpsc, Mutex};

/// Helper: create an in-memory database for tests.
fn test_db() -> Arc<Database> {
    Arc::new(Database::open_in_memory().expect("Failed to open in-memory db"))
}

/// Helper: create a sync engine with a dummy peer manager (no encryption).
fn test_engine(device_id: &str) -> SyncEngine {
    let db = test_db();
    let signing_key = SigningKey::generate(&mut OsRng);
    let signal_mgr = dspatch_sdk::signal::SignalManager::new(
        Arc::clone(&db),
        1,
        signing_key,
    );
    let peer_mgr = Arc::new(PeerConnectionManager::new(Arc::new(Mutex::new(signal_mgr))));
    SyncEngine::new(db, peer_mgr, device_id)
}

/// Helper: create a pair of engines that share a peer connection.
async fn test_engine_pair() -> (SyncEngine, SyncEngine) {
    let db_a = test_db();
    let db_b = test_db();

    let signing_key_a = SigningKey::generate(&mut OsRng);
    let signing_key_b = SigningKey::generate(&mut OsRng);

    let signal_a = Arc::new(Mutex::new(dspatch_sdk::signal::SignalManager::new(
        Arc::clone(&db_a), 1, signing_key_a,
    )));
    let signal_b = Arc::new(Mutex::new(dspatch_sdk::signal::SignalManager::new(
        Arc::clone(&db_b), 2, signing_key_b,
    )));

    let peer_mgr_a = Arc::new(PeerConnectionManager::new(signal_a));
    let peer_mgr_b = Arc::new(PeerConnectionManager::new(signal_b));

    // Wire up bidirectional channels.
    let (tx_a2b, rx_a2b) = mpsc::channel(64);
    let (tx_b2a, rx_b2a) = mpsc::channel(64);

    peer_mgr_a.register_peer("device-b", tx_a2b, rx_b2a).await;
    peer_mgr_b.register_peer("device-a", tx_b2a, rx_a2b).await;

    let engine_a = SyncEngine::new(db_a, peer_mgr_a, "device-a");
    let engine_b = SyncEngine::new(db_b, peer_mgr_b, "device-b");

    (engine_a, engine_b)
}

// -------------------------------------------------------------------------
// Test 1: SyncChange serialization / deserialization
// -------------------------------------------------------------------------

#[test]
fn test_sync_change_serde_roundtrip() {
    let change = SyncChange {
        id: "change-1".to_string(),
        table: "workspaces".to_string(),
        row_id: "ws-123".to_string(),
        operation: SyncOp::Insert,
        data: serde_json::json!({"name": "My Workspace", "project_path": "/tmp/ws"}),
        lamport_ts: 42,
        device_id: "device-a".to_string(),
    };

    let json = serde_json::to_string(&change).unwrap();
    let deserialized: SyncChange = serde_json::from_str(&json).unwrap();

    assert_eq!(deserialized.id, "change-1");
    assert_eq!(deserialized.table, "workspaces");
    assert_eq!(deserialized.row_id, "ws-123");
    assert_eq!(deserialized.operation, SyncOp::Insert);
    assert_eq!(deserialized.lamport_ts, 42);
    assert_eq!(deserialized.device_id, "device-a");
    assert_eq!(deserialized.data["name"], "My Workspace");
}

// -------------------------------------------------------------------------
// Test 2: SyncMessage variants roundtrip
// -------------------------------------------------------------------------

#[test]
fn test_sync_message_variants_roundtrip() {
    // Changes variant
    let changes_msg = SyncMessage::Changes(vec![SyncChange {
        id: "c1".into(),
        table: "agents".into(),
        row_id: "a1".into(),
        operation: SyncOp::Update,
        data: serde_json::json!({"status": "running"}),
        lamport_ts: 10,
        device_id: "dev-1".into(),
    }]);
    let json = serde_json::to_string(&changes_msg).unwrap();
    let _: SyncMessage = serde_json::from_str(&json).unwrap();

    // Ack variant
    let ack_msg = SyncMessage::Ack {
        last_id: "c1".into(),
    };
    let json = serde_json::to_string(&ack_msg).unwrap();
    let deserialized: SyncMessage = serde_json::from_str(&json).unwrap();
    match deserialized {
        SyncMessage::Ack { last_id } => assert_eq!(last_id, "c1"),
        _ => panic!("Expected Ack variant"),
    }

    // CursorExchange variant
    let mut cursors = HashMap::new();
    cursors.insert("workspaces".to_string(), 100_i64);
    cursors.insert("agents".to_string(), 50_i64);
    let cursor_msg = SyncMessage::CursorExchange(cursors);
    let json = serde_json::to_string(&cursor_msg).unwrap();
    let deserialized: SyncMessage = serde_json::from_str(&json).unwrap();
    match deserialized {
        SyncMessage::CursorExchange(c) => {
            assert_eq!(c["workspaces"], 100);
            assert_eq!(c["agents"], 50);
        }
        _ => panic!("Expected CursorExchange variant"),
    }

    // RequestChanges variant
    let req_msg = SyncMessage::RequestChanges {
        table: "logs".into(),
        since_lamport: 25,
    };
    let json = serde_json::to_string(&req_msg).unwrap();
    let deserialized: SyncMessage = serde_json::from_str(&json).unwrap();
    match deserialized {
        SyncMessage::RequestChanges {
            table,
            since_lamport,
        } => {
            assert_eq!(table, "logs");
            assert_eq!(since_lamport, 25);
        }
        _ => panic!("Expected RequestChanges variant"),
    }
}

// -------------------------------------------------------------------------
// Test 3: Outbox recording and querying
// -------------------------------------------------------------------------

#[test]
fn test_outbox_recording_and_querying() {
    let engine = test_engine("device-a");

    // Record changes to different tables.
    engine
        .record_change(
            "workspaces",
            "ws-1",
            SyncOp::Insert,
            serde_json::json!({"name": "WS1"}),
        )
        .unwrap();

    engine
        .record_change(
            "workspaces",
            "ws-2",
            SyncOp::Insert,
            serde_json::json!({"name": "WS2"}),
        )
        .unwrap();

    engine
        .record_change(
            "agents",
            "a-1",
            SyncOp::Insert,
            serde_json::json!({"key": "agent1"}),
        )
        .unwrap();

    // Query all outbox entries.
    let all = engine.get_all_outbox().unwrap();
    assert_eq!(all.len(), 3);

    // Query only workspaces since lamport 0 (all).
    let ws_changes = engine.get_outbox_since("workspaces", 0).unwrap();
    assert_eq!(ws_changes.len(), 2);

    // Query only workspaces since the first change's lamport.
    let ws_changes_since = engine
        .get_outbox_since("workspaces", ws_changes[0].lamport_ts)
        .unwrap();
    assert_eq!(ws_changes_since.len(), 1);
    assert_eq!(ws_changes_since[0].row_id, "ws-2");
}

// -------------------------------------------------------------------------
// Test 4: Cursor management (get / update)
// -------------------------------------------------------------------------

#[test]
fn test_cursor_management() {
    let engine = test_engine("device-a");

    // Default cursor is 0.
    let cursor = engine.get_cursor("device-b", "workspaces").unwrap();
    assert_eq!(cursor, 0);

    // Update cursor.
    engine.update_cursor("device-b", "workspaces", 42).unwrap();
    let cursor = engine.get_cursor("device-b", "workspaces").unwrap();
    assert_eq!(cursor, 42);

    // Update same cursor to a higher value.
    engine.update_cursor("device-b", "workspaces", 100).unwrap();
    let cursor = engine.get_cursor("device-b", "workspaces").unwrap();
    assert_eq!(cursor, 100);

    // Different table has its own cursor.
    let cursor = engine.get_cursor("device-b", "agents").unwrap();
    assert_eq!(cursor, 0);

    // Different device has its own cursor.
    let cursor = engine.get_cursor("device-c", "workspaces").unwrap();
    assert_eq!(cursor, 0);
}

// -------------------------------------------------------------------------
// Test 5: Lamport clock increments
// -------------------------------------------------------------------------

#[test]
fn test_lamport_clock_increments() {
    let engine = test_engine("device-a");

    assert_eq!(engine.current_lamport(), 0);

    let c1 = engine
        .record_change("t", "r1", SyncOp::Insert, serde_json::json!({}))
        .unwrap();
    assert_eq!(c1.lamport_ts, 1);
    assert_eq!(engine.current_lamport(), 1);

    let c2 = engine
        .record_change("t", "r2", SyncOp::Insert, serde_json::json!({}))
        .unwrap();
    assert_eq!(c2.lamport_ts, 2);
    assert_eq!(engine.current_lamport(), 2);

    let c3 = engine
        .record_change("t", "r3", SyncOp::Update, serde_json::json!({}))
        .unwrap();
    assert_eq!(c3.lamport_ts, 3);
}

// -------------------------------------------------------------------------
// Test 6: Apply remote changes with insert / update / delete
// -------------------------------------------------------------------------

#[test]
fn test_apply_remote_changes() {
    let engine = test_engine("device-a");

    let changes = vec![
        SyncChange {
            id: "remote-1".into(),
            table: "workspaces".into(),
            row_id: "ws-1".into(),
            operation: SyncOp::Insert,
            data: serde_json::json!({"name": "Remote WS"}),
            lamport_ts: 5,
            device_id: "device-b".into(),
        },
        SyncChange {
            id: "remote-2".into(),
            table: "workspaces".into(),
            row_id: "ws-1".into(),
            operation: SyncOp::Update,
            data: serde_json::json!({"name": "Updated Remote WS"}),
            lamport_ts: 6,
            device_id: "device-b".into(),
        },
        SyncChange {
            id: "remote-3".into(),
            table: "agents".into(),
            row_id: "a-1".into(),
            operation: SyncOp::Delete,
            data: serde_json::Value::Null,
            lamport_ts: 7,
            device_id: "device-b".into(),
        },
    ];

    let applied = engine.apply_remote_changes(changes).unwrap();
    assert_eq!(applied, 3);

    // The Lamport clock should have merged to at least 7.
    assert!(engine.current_lamport() >= 7);

    // Remote changes should be in the outbox.
    let outbox = engine.get_all_outbox().unwrap();
    assert_eq!(outbox.len(), 3);

    // Cursor should be updated for device-b.
    let cursor = engine.get_cursor("device-b", "agents").unwrap();
    assert_eq!(cursor, 7);
}

// -------------------------------------------------------------------------
// Test 7: Reconcile flow between two engines
// -------------------------------------------------------------------------

#[tokio::test]
async fn test_reconcile_flow() {
    let (engine_a, engine_b) = test_engine_pair().await;

    // Device A records some changes.
    engine_a
        .record_change(
            "workspaces",
            "ws-1",
            SyncOp::Insert,
            serde_json::json!({"name": "WS from A"}),
        )
        .unwrap();
    engine_a
        .record_change(
            "workspaces",
            "ws-2",
            SyncOp::Insert,
            serde_json::json!({"name": "WS2 from A"}),
        )
        .unwrap();

    // Reconcile A → B: sends cursor exchange and changes.
    engine_a.reconcile("device-b").await.unwrap();

    // Read messages from B's channel and apply them.
    // The peer_manager for B should have received raw bytes on its channel.
    // In a real scenario, the engine would consume these via incoming_messages().
    // Here we manually read and apply.
    let peer_mgr_b = Arc::clone(engine_b.peer_manager());

    // First message: CursorExchange.
    let raw1 = peer_mgr_b.recv_raw("device-a").await.unwrap().unwrap();
    let msg1: SyncMessage = serde_json::from_slice(&raw1).unwrap();
    match msg1 {
        SyncMessage::CursorExchange(cursors) => {
            assert!(cursors.contains_key("workspaces"));
        }
        _ => panic!("Expected CursorExchange"),
    }

    // Second message: Changes.
    let raw2 = peer_mgr_b.recv_raw("device-a").await.unwrap().unwrap();
    let msg2: SyncMessage = serde_json::from_slice(&raw2).unwrap();
    match msg2 {
        SyncMessage::Changes(changes) => {
            assert_eq!(changes.len(), 2);
            let applied = engine_b.apply_remote_changes(changes).unwrap();
            assert_eq!(applied, 2);
        }
        _ => panic!("Expected Changes"),
    }

    // B should now have the changes in its outbox.
    let b_outbox = engine_b.get_all_outbox().unwrap();
    assert_eq!(b_outbox.len(), 2);
}

// -------------------------------------------------------------------------
// Test 8: Conflict resolution — last-writer-wins by lamport timestamp
// -------------------------------------------------------------------------

#[test]
fn test_conflict_resolution_last_writer_wins() {
    let engine = test_engine("device-a");

    // Local device writes at lamport 5.
    engine
        .record_change(
            "workspaces",
            "ws-1",
            SyncOp::Update,
            serde_json::json!({"name": "Local Version"}),
        )
        .unwrap();

    let local_ts = engine.current_lamport();

    // Remote device sends a change with LOWER lamport — should be rejected.
    let remote_lower = vec![SyncChange {
        id: "remote-old".into(),
        table: "workspaces".into(),
        row_id: "ws-1".into(),
        operation: SyncOp::Update,
        data: serde_json::json!({"name": "Older Remote"}),
        lamport_ts: local_ts - 1,
        device_id: "device-b".into(),
    }];
    let applied = engine.apply_remote_changes(remote_lower).unwrap();
    assert_eq!(applied, 0, "Lower lamport change should be rejected");

    // Remote device sends a change with HIGHER lamport — should be accepted.
    let remote_higher = vec![SyncChange {
        id: "remote-new".into(),
        table: "workspaces".into(),
        row_id: "ws-1".into(),
        operation: SyncOp::Update,
        data: serde_json::json!({"name": "Newer Remote"}),
        lamport_ts: local_ts + 10,
        device_id: "device-b".into(),
    }];
    let applied = engine.apply_remote_changes(remote_higher).unwrap();
    assert_eq!(applied, 1, "Higher lamport change should be accepted");

    // Verify the outbox has both local and remote entries.
    let outbox = engine.get_all_outbox().unwrap();
    assert_eq!(outbox.len(), 2); // local + accepted remote
}

#[test]
fn test_conflict_resolution_tiebreak_by_device_id() {
    // "device-b" > "device-a" lexicographically, so device-b wins ties.
    let engine_a = test_engine("device-a");

    // Local device-a writes.
    engine_a
        .record_change(
            "workspaces",
            "ws-1",
            SyncOp::Update,
            serde_json::json!({"name": "A version"}),
        )
        .unwrap();
    let ts = engine_a.current_lamport();

    // Remote device-b sends change with SAME lamport.
    // device-b > device-a, so device-a should accept device-b's change
    // (device-a does NOT win the tiebreak).
    let remote_same = vec![SyncChange {
        id: "remote-tie".into(),
        table: "workspaces".into(),
        row_id: "ws-1".into(),
        operation: SyncOp::Update,
        data: serde_json::json!({"name": "B version"}),
        lamport_ts: ts,
        device_id: "device-b".into(),
    }];
    let applied = engine_a.apply_remote_changes(remote_same).unwrap();
    assert_eq!(
        applied, 1,
        "device-b should win tiebreak over device-a"
    );
}

#[test]
fn test_sync_op_str_roundtrip() {
    assert_eq!(SyncOp::from_str("insert"), Some(SyncOp::Insert));
    assert_eq!(SyncOp::from_str("update"), Some(SyncOp::Update));
    assert_eq!(SyncOp::from_str("delete"), Some(SyncOp::Delete));
    assert_eq!(SyncOp::from_str("unknown"), None);

    assert_eq!(SyncOp::Insert.as_str(), "insert");
    assert_eq!(SyncOp::Update.as_str(), "update");
    assert_eq!(SyncOp::Delete.as_str(), "delete");
}

#[test]
fn test_acknowledge_prunes_outbox() {
    let engine = test_engine("device-a");

    let c1 = engine
        .record_change("t", "r1", SyncOp::Insert, serde_json::json!({}))
        .unwrap();
    let _c2 = engine
        .record_change("t", "r2", SyncOp::Insert, serde_json::json!({}))
        .unwrap();
    let _c3 = engine
        .record_change("t", "r3", SyncOp::Insert, serde_json::json!({}))
        .unwrap();

    assert_eq!(engine.get_all_outbox().unwrap().len(), 3);

    // Acknowledge up to c1 — should prune c1 only.
    engine.acknowledge_up_to(&c1.id).unwrap();
    let remaining = engine.get_all_outbox().unwrap();
    assert_eq!(remaining.len(), 2);
    assert!(remaining.iter().all(|c| c.lamport_ts > c1.lamport_ts));
}
