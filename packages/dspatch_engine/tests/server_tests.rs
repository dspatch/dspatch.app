// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Tests for the embedded agent server modules.

use std::sync::Arc;

use dspatch_engine::db::Database;
use dspatch_engine::db::dao::WorkspaceDao;
use dspatch_engine::domain::enums::{AgentState, LogLevel};
use dspatch_engine::domain::models::{WorkspaceAgent, WorkspaceRun};
use dspatch_engine::server::inspector::{PackageDirection, PackageInspectorService};
use dspatch_engine::server::communication::CommunicationService;
use dspatch_engine::server::event::EventService;
use dspatch_engine::server::status::StatusService;
use dspatch_engine::server::packages::*;

// ═══════════════════════════════════════════════════════════════════════
// PackageInspectorService tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn inspector_ring_buffer_respects_max_entries() {
    let inspector = PackageInspectorService::new(3, true);
    let run_id = "run-1";

    for i in 0..5 {
        let json = format!(
            r#"{{"type":"agent.output.log","instance_id":"i1","level":"info","message":"msg{}"}}"#,
            i
        );
        inspector.log_inbound(run_id, &json);
    }

    let entries = inspector.entries_for_run(run_id);
    assert_eq!(entries.len(), 3, "Ring buffer should keep at most 3 entries");
    assert!(entries[0].raw_json.contains("msg2"));
    assert!(entries[1].raw_json.contains("msg3"));
    assert!(entries[2].raw_json.contains("msg4"));
}

#[test]
fn inspector_disabled_does_not_log() {
    let inspector = PackageInspectorService::new(100, false);
    inspector.log_inbound("run-1", r#"{"type":"connection.auth","api_key":"key"}"#);
    assert!(inspector.entries_for_run("run-1").is_empty());
}

#[test]
fn inspector_roundtrip_detects_mismatch() {
    let inspector = PackageInspectorService::new(100, true);
    // AuthPackage only has api_key -- extra fields should be stripped on roundtrip
    let json_with_extra =
        r#"{"type":"connection.auth","api_key":"key","extra_field":"value"}"#;
    inspector.log_inbound("run-1", json_with_extra);

    let entries = inspector.entries_for_run("run-1");
    assert_eq!(entries.len(), 1);
    assert!(entries[0].roundtrip_mismatch, "Extra field should cause mismatch");
    assert!(entries[0].roundtrip_json.is_some());
}

#[test]
fn inspector_roundtrip_no_mismatch_for_clean_package() {
    let inspector = PackageInspectorService::new(100, true);
    let json = r#"{"type":"connection.auth","api_key":"test-key"}"#;
    inspector.log_inbound("run-1", json);

    let entries = inspector.entries_for_run("run-1");
    assert_eq!(entries.len(), 1);
    assert!(
        !entries[0].roundtrip_mismatch,
        "Clean package should not cause mismatch"
    );
}

#[test]
fn inspector_clear_run_removes_entries() {
    let inspector = PackageInspectorService::new(100, true);
    inspector.log_inbound("run-1", r#"{"type":"connection.auth","api_key":"key"}"#);
    assert!(!inspector.entries_for_run("run-1").is_empty());
    inspector.clear_run("run-1");
    assert!(inspector.entries_for_run("run-1").is_empty());
}

#[test]
fn inspector_outbound_captures_sent_direction() {
    let inspector = PackageInspectorService::new(100, true);
    let json: serde_json::Value =
        serde_json::from_str(r#"{"type":"connection.auth_ack"}"#).unwrap();
    inspector.log_outbound("run-1", &json);

    let entries = inspector.entries_for_run("run-1");
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].direction, PackageDirection::Sent);
}

#[test]
fn inspector_invalid_json_records_error() {
    let inspector = PackageInspectorService::new(100, true);
    inspector.log_inbound("run-1", "not valid json");

    let entries = inspector.entries_for_run("run-1");
    assert_eq!(entries.len(), 1);
    assert!(entries[0].error.is_some(), "Invalid JSON should record an error");
}

#[test]
fn inspector_multiple_runs_are_independent() {
    let inspector = PackageInspectorService::new(100, true);
    inspector.log_inbound("run-1", r#"{"type":"connection.auth","api_key":"key1"}"#);
    inspector.log_inbound("run-2", r#"{"type":"connection.auth","api_key":"key2"}"#);

    assert_eq!(inspector.entries_for_run("run-1").len(), 1);
    assert_eq!(inspector.entries_for_run("run-2").len(), 1);

    inspector.clear_run("run-1");
    assert!(inspector.entries_for_run("run-1").is_empty());
    assert_eq!(inspector.entries_for_run("run-2").len(), 1);
}

// ═══════════════════════════════════════════════════════════════════════
// CommunicationService tests
// ═══════════════════════════════════════════════════════════════════════

fn setup_dao() -> Arc<WorkspaceDao> {
    let db = Arc::new(Database::open_in_memory().unwrap());
    Arc::new(WorkspaceDao::new(db))
}

fn setup_workspace_and_run(dao: &WorkspaceDao) -> (String, String) {
    let workspace_id = uuid::Uuid::new_v4().to_string();
    let run_id = uuid::Uuid::new_v4().to_string();
    let now = chrono::Utc::now().naive_utc();

    dao.insert_workspace(&dspatch_engine::domain::models::Workspace {
        id: workspace_id.clone(),
        name: "Test Workspace".to_string(),
        project_path: "/tmp/test".to_string(),
        created_at: now,
        updated_at: now,
    })
    .unwrap();

    dao.insert_workspace_run(&WorkspaceRun {
        id: run_id.clone(),
        workspace_id: workspace_id.clone(),
        run_number: 1,
        status: "running".to_string(),
        container_id: None,
        server_port: None,
        api_key: Some("test-key".to_string()),
        started_at: now,
        stopped_at: None,
    })
    .unwrap();

    (workspace_id, run_id)
}

#[test]
fn communication_persists_log_package() {
    let dao = setup_dao();
    let (workspace_id, run_id) = setup_workspace_and_run(&dao);
    let comm = CommunicationService::new(Arc::clone(&dao));

    let log_pkg = Package::Log(LogPackage {
        instance_id: "inst-1".to_string(),
        turn_id: None,
        ts: None,
        level: LogLevel::Info,
        message: "Test log message".to_string(),
    });

    comm.handle_output_packet(&workspace_id, "agent-1", &run_id, &log_pkg);

    // Verify it was persisted by reading from the DB.
    use futures::StreamExt;
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let mut stream = dao.watch_agent_logs(&run_id, Some("inst-1"));
        if let Some(Ok(logs)) = stream.next().await {
            assert!(!logs.is_empty(), "Should have persisted at least one log");
            assert_eq!(logs[0].message, "Test log message");
            assert_eq!(logs[0].level, LogLevel::Info);
        } else {
            panic!("No logs found");
        }
    });
}

#[test]
fn communication_persists_message_package() {
    let dao = setup_dao();
    let (workspace_id, run_id) = setup_workspace_and_run(&dao);
    let comm = CommunicationService::new(Arc::clone(&dao));

    let msg_pkg = Package::Message(MessagePackage {
        instance_id: "inst-1".to_string(),
        turn_id: None,
        ts: None,
        id: Some("msg-1".to_string()),
        role: MessageRole::Assistant,
        content: "Hello world".to_string(),
        model: Some("gpt-4".to_string()),
        input_tokens: Some(100),
        output_tokens: Some(50),
        is_delta: false,
        sender_name: None,
    });

    comm.handle_output_packet(&workspace_id, "agent-1", &run_id, &msg_pkg);

    // Verify persistence.
    use futures::StreamExt;
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let mut stream = dao.watch_agent_messages(&run_id, "inst-1");
        if let Some(Ok(msgs)) = stream.next().await {
            assert!(!msgs.is_empty(), "Should have persisted the message");
            assert_eq!(msgs[0].content, "Hello world");
            assert_eq!(msgs[0].role, "assistant");
            assert_eq!(msgs[0].model, Some("gpt-4".to_string()));
        } else {
            panic!("No messages found");
        }
    });
}

#[test]
fn communication_persists_usage_package() {
    let dao = setup_dao();
    let (workspace_id, run_id) = setup_workspace_and_run(&dao);
    let comm = CommunicationService::new(Arc::clone(&dao));

    let usage_pkg = Package::Usage(UsagePackage {
        instance_id: "inst-1".to_string(),
        turn_id: None,
        ts: None,
        model: "claude-3".to_string(),
        input_tokens: 500,
        output_tokens: 200,
        cache_read_tokens: Some(100),
        cache_write_tokens: Some(50),
        cost_usd: Some(0.05),
    });

    comm.handle_output_packet(&workspace_id, "agent-1", &run_id, &usage_pkg);

    use futures::StreamExt;
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let mut stream = dao.watch_agent_usage(&run_id, Some("inst-1"));
        if let Some(Ok(usages)) = stream.next().await {
            assert!(!usages.is_empty(), "Should have persisted usage record");
            assert_eq!(usages[0].model, "claude-3");
            assert_eq!(usages[0].input_tokens, 500);
            assert_eq!(usages[0].output_tokens, 200);
        } else {
            panic!("No usage records found");
        }
    });
}

// ═══════════════════════════════════════════════════════════════════════
// StatusService tests
// ═══════════════════════════════════════════════════════════════════════

#[tokio::test]
async fn status_try_transition_validates_state_machine() {
    let dao = setup_dao();
    let (workspace_id, run_id) = setup_workspace_and_run(&dao);

    let event_service = Arc::new(EventService::with_default_interval(Arc::clone(&dao)));
    event_service
        .register_workspace_run(&workspace_id, &run_id);

    let status_service = StatusService::new(Arc::clone(&dao), Arc::clone(&event_service));

    // Insert a workspace agent with idle status.
    let instance_id = uuid::Uuid::new_v4().to_string();
    let now = chrono::Utc::now().naive_utc();
    dao.insert_workspace_agent(&WorkspaceAgent {
        id: uuid::Uuid::new_v4().to_string(),
        run_id: run_id.clone(),
        agent_key: "agent-1".to_string(),
        instance_id: instance_id.clone(),
        display_name: "test".to_string(),
        chain_json: "[]".to_string(),
        status: AgentState::Idle,
        created_at: now,
        updated_at: now,
    })
    .unwrap();

    // Valid transition: Idle -> Generating.
    let result = status_service
        .try_transition(
            &workspace_id,
            "agent-1",
            &instance_id,
            AgentState::Generating,
            "test",
        )
        .await;
    assert!(result, "Idle -> Generating should be valid");

    // Invalid transition: Generating -> Idle -> Completed is valid,
    // but Generating -> WaitingForInquiry is also valid.
    // Test an invalid transition: refresh from DB.
    let result2 = status_service
        .try_transition(
            &workspace_id,
            "agent-1",
            &instance_id,
            AgentState::Generating,
            "test",
        )
        .await;
    assert!(!result2, "Generating -> Generating should be no-op (same state)");
}

#[tokio::test]
async fn status_handle_instance_state_changed() {
    let dao = setup_dao();
    let (workspace_id, run_id) = setup_workspace_and_run(&dao);

    let event_service = Arc::new(EventService::with_default_interval(Arc::clone(&dao)));
    event_service
        .register_workspace_run(&workspace_id, &run_id);

    let status_service = StatusService::new(Arc::clone(&dao), Arc::clone(&event_service));

    let instance_id = uuid::Uuid::new_v4().to_string();
    let now = chrono::Utc::now().naive_utc();
    dao.insert_workspace_agent(&WorkspaceAgent {
        id: uuid::Uuid::new_v4().to_string(),
        run_id: run_id.clone(),
        agent_key: "agent-1".to_string(),
        instance_id: instance_id.clone(),
        display_name: "test".to_string(),
        chain_json: "[]".to_string(),
        status: AgentState::Idle,
        created_at: now,
        updated_at: now,
    })
    .unwrap();

    // Simulate heartbeat reporting "generating".
    status_service
        .handle_instance_state_changed(
            &workspace_id,
            "agent-1",
            &instance_id,
            Some("idle"),
            "generating",
        )
        .await;

    // Verify the agent status was updated.
    let agent = dao
        .find_workspace_agent_by_instance_id(&run_id, &instance_id)
        .unwrap()
        .unwrap();
    assert_eq!(agent.status, AgentState::Generating);
}

#[tokio::test]
async fn status_handle_instance_gone_marks_disconnected() {
    let dao = setup_dao();
    let (workspace_id, run_id) = setup_workspace_and_run(&dao);

    let event_service = Arc::new(EventService::with_default_interval(Arc::clone(&dao)));
    event_service
        .register_workspace_run(&workspace_id, &run_id);

    let status_service = StatusService::new(Arc::clone(&dao), Arc::clone(&event_service));

    let instance_id = uuid::Uuid::new_v4().to_string();
    let now = chrono::Utc::now().naive_utc();
    dao.insert_workspace_agent(&WorkspaceAgent {
        id: uuid::Uuid::new_v4().to_string(),
        run_id: run_id.clone(),
        agent_key: "agent-1".to_string(),
        instance_id: instance_id.clone(),
        display_name: "test".to_string(),
        chain_json: "[]".to_string(),
        status: AgentState::Idle,
        created_at: now,
        updated_at: now,
    })
    .unwrap();

    status_service
        .handle_instance_gone(&workspace_id, "agent-1", &instance_id, "idle")
        .await;

    let agent = dao
        .find_workspace_agent_by_instance_id(&run_id, &instance_id)
        .unwrap()
        .unwrap();
    assert_eq!(agent.status, AgentState::Disconnected);
}

// ═══════════════════════════════════════════════════════════════════════
// EventService tests
// ═══════════════════════════════════════════════════════════════════════

#[tokio::test]
async fn event_service_cycle_detection() {
    // Direct cycle: A -> B -> A
    let chain = vec!["A".to_string(), "B".to_string()];
    let result = EventService::detect_cycle("A", "B", &chain);
    assert!(result.is_some(), "Should detect cycle A -> B -> A");
    assert!(result.unwrap().contains("Cyclic"));

    // No cycle: A -> B -> C
    let chain2 = vec!["A".to_string()];
    let result2 = EventService::detect_cycle("C", "B", &chain2);
    assert!(result2.is_none(), "Should not detect cycle for A -> B -> C");
}

#[tokio::test]
async fn event_service_run_tracking() {
    let dao = setup_dao();
    let event_service = EventService::with_default_interval(dao);

    event_service
        .register_workspace_run("ws-1", "run-1");

    assert_eq!(
        event_service.active_run_id("ws-1"),
        Some("run-1".to_string())
    );
    assert_eq!(
        event_service.workspace_id_for_run("run-1"),
        Some("ws-1".to_string())
    );

    event_service.deregister_workspace_run("ws-1");

    assert_eq!(event_service.active_run_id("ws-1"), None);
    assert_eq!(event_service.workspace_id_for_run("run-1"), None);
}

// ═══════════════════════════════════════════════════════════════════════
// ConnectionService heartbeat diffing tests
// ═══════════════════════════════════════════════════════════════════════

#[tokio::test]
async fn connection_heartbeat_detects_state_changes() {
    use dspatch_engine::server::connection::ConnectionService;
    use std::sync::atomic::{AtomicUsize, Ordering};

    let service = Arc::new(ConnectionService::new(None));

    let change_count = Arc::new(AtomicUsize::new(0));
    let gone_count = Arc::new(AtomicUsize::new(0));

    let cc = Arc::clone(&change_count);
    *service.on_instance_state_changed.lock().await = Some(Arc::new(
        move |_run_id, _agent, _instance_id, _old, _new| {
            cc.fetch_add(1, Ordering::SeqCst);
        },
    ));

    let gc = Arc::clone(&gone_count);
    *service.on_instance_gone.lock().await = Some(Arc::new(
        move |_run_id, _agent, _instance_id, _last| {
            gc.fetch_add(1, Ordering::SeqCst);
        },
    ));

    // First heartbeat: 2 new instances.
    let mut instances = std::collections::HashMap::new();
    instances.insert("i1".to_string(), "idle".to_string());
    instances.insert("i2".to_string(), "generating".to_string());

    service.process_heartbeat("run-1", "agent-1", &instances).await;
    assert_eq!(change_count.load(Ordering::SeqCst), 2, "Two new instances");
    assert_eq!(gone_count.load(Ordering::SeqCst), 0);

    // Second heartbeat: i1 state changed, i2 gone, i3 new.
    let mut instances2 = std::collections::HashMap::new();
    instances2.insert("i1".to_string(), "generating".to_string());
    instances2.insert("i3".to_string(), "idle".to_string());

    service.process_heartbeat("run-1", "agent-1", &instances2).await;
    assert_eq!(
        change_count.load(Ordering::SeqCst),
        4,
        "Two more changes (i1 changed + i3 new)"
    );
    assert_eq!(gone_count.load(Ordering::SeqCst), 1, "i2 is gone");
}

#[tokio::test]
async fn connection_state_report_updates_state() {
    use dspatch_engine::server::connection::ConnectionService;
    use std::sync::atomic::{AtomicUsize, Ordering};

    let service = Arc::new(ConnectionService::new(None));

    let change_count = Arc::new(AtomicUsize::new(0));
    let cc = Arc::clone(&change_count);
    *service.on_instance_state_changed.lock().await = Some(Arc::new(
        move |_run_id, _agent, _instance_id, _old, _new| {
            cc.fetch_add(1, Ordering::SeqCst);
        },
    ));

    // Process state report.
    service
        .process_state_report("run-1", "agent-1", "i1", "idle")
        .await;
    assert_eq!(change_count.load(Ordering::SeqCst), 1);

    // Same state should be a no-op.
    service
        .process_state_report("run-1", "agent-1", "i1", "idle")
        .await;
    assert_eq!(change_count.load(Ordering::SeqCst), 1, "No change for same state");

    // Different state should fire callback.
    service
        .process_state_report("run-1", "agent-1", "i1", "generating")
        .await;
    assert_eq!(change_count.load(Ordering::SeqCst), 2);
}
