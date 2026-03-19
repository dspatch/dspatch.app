// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the DAO layer.

use std::sync::Arc;

use chrono::NaiveDateTime;
use futures::StreamExt;

use dspatch_engine::db::dao::{
    ApiKeyDao, PreferenceDao, WorkspaceDao,
};
use dspatch_engine::db::dao::agent_instance_state_dao::AgentInstanceStateDao;
use dspatch_engine::db::dao::agent_connection_status_dao::AgentConnectionStatusDao;
use dspatch_engine::db::dao::container_health_dao::ContainerHealthDao;
use dspatch_engine::db::dao::workspace_run_status_dao::WorkspaceRunStatusDao;
use dspatch_engine::db::Database;
use dspatch_engine::domain::enums::{AgentState, InquiryPriority, InquiryStatus, LogLevel, LogSource};
use dspatch_engine::domain::models::{
    AgentActivity, AgentFile, AgentLog, AgentMessage, AgentUsage,
    Workspace, WorkspaceAgent, WorkspaceInquiry, WorkspaceRun,
};

fn now() -> NaiveDateTime {
    chrono::Utc::now().naive_utc()
}

fn db() -> Arc<Database> {
    Arc::new(Database::open_in_memory().expect("Failed to open in-memory database"))
}

// ── PreferenceDao ───────────────────────────────────────────────────

#[test]
fn test_preference_set_get_delete_roundtrip() {
    let db = db();
    let dao = PreferenceDao::new(db);

    // Initially empty.
    assert_eq!(dao.get_preference("theme").unwrap(), None);

    // Set and get.
    dao.set_preference("theme", "dark").unwrap();
    assert_eq!(dao.get_preference("theme").unwrap(), Some("dark".to_string()));

    // Overwrite.
    dao.set_preference("theme", "light").unwrap();
    assert_eq!(
        dao.get_preference("theme").unwrap(),
        Some("light".to_string())
    );

    // Delete.
    dao.delete_preference("theme").unwrap();
    assert_eq!(dao.get_preference("theme").unwrap(), None);
}

#[tokio::test]
async fn test_preference_watch_emits_on_change() {
    let db = db();
    let dao = PreferenceDao::new(Arc::clone(&db));

    let mut stream = dao.watch_preference("theme");

    // Initial emission — None.
    let first = stream.next().await.unwrap().unwrap();
    assert_eq!(first, None);

    // Set a value.
    dao.set_preference("theme", "dark").unwrap();

    // Should re-emit.
    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout waiting for second emission")
        .unwrap()
        .unwrap();
    assert_eq!(second, Some("dark".to_string()));
}

// ── ApiKeyDao ───────────────────────────────────────────────────────

#[test]
fn test_api_key_insert_get_delete() {
    let db = db();
    let dao = ApiKeyDao::new(Arc::clone(&db));

    // Insert with BLOB data.
    let encrypted = vec![0xDE, 0xAD, 0xBE, 0xEF];
    dao.insert_api_key("key-1", "My OpenAI Key", "OpenAI", &encrypted, Some("sk-...EF"))
        .unwrap();

    // Get by name.
    let key = dao.get_api_key_by_name("My OpenAI Key").unwrap().unwrap();
    assert_eq!(key.id, "key-1");
    assert_eq!(key.provider_label, "OpenAI");
    assert_eq!(key.encrypted_key, encrypted);
    assert_eq!(key.display_hint, Some("sk-...EF".to_string()));

    // Get non-existent.
    assert!(dao.get_api_key_by_name("Nonexistent").unwrap().is_none());

    // Delete.
    dao.delete_api_key("key-1").unwrap();
    assert!(dao.get_api_key_by_name("My OpenAI Key").unwrap().is_none());
}

#[tokio::test]
async fn test_api_key_watch_emits() {
    let db = db();
    let dao = ApiKeyDao::new(Arc::clone(&db));

    let mut stream = dao.watch_api_keys();

    // Initial emission — empty.
    let first = stream.next().await.unwrap().unwrap();
    assert!(first.is_empty());

    // Insert.
    dao.insert_api_key("key-1", "Test Key", "Anthropic", &[1, 2, 3], None)
        .unwrap();

    // Should re-emit with one key.
    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout")
        .unwrap()
        .unwrap();
    assert_eq!(second.len(), 1);
    assert_eq!(second[0].name, "Test Key");
}

// ── WorkspaceDao ────────────────────────────────────────────────────

fn make_workspace(id: &str, name: &str) -> Workspace {
    let now = now();
    Workspace {
        id: id.to_string(),
        name: name.to_string(),
        project_path: "/tmp/test".to_string(),
        created_at: now,
        updated_at: now,
    }
}

fn make_run(id: &str, workspace_id: &str, run_number: i64, status: &str) -> WorkspaceRun {
    let now = now();
    WorkspaceRun {
        id: id.to_string(),
        workspace_id: workspace_id.to_string(),
        run_number,
        status: status.to_string(),
        container_id: None,
        server_port: None,
        api_key: None,
        started_at: now,
        stopped_at: None,
    }
}

fn make_agent(id: &str, run_id: &str, agent_key: &str, instance_id: &str) -> WorkspaceAgent {
    let now = now();
    WorkspaceAgent {
        id: id.to_string(),
        run_id: run_id.to_string(),
        agent_key: agent_key.to_string(),
        instance_id: instance_id.to_string(),
        display_name: agent_key.to_string(),
        chain_json: "[]".to_string(),
        status: AgentState::Disconnected,
        created_at: now,
        updated_at: now,
    }
}

fn make_message(id: &str, run_id: &str, instance_id: &str, content: &str) -> AgentMessage {
    let now = now();
    AgentMessage {
        id: id.to_string(),
        run_id: run_id.to_string(),
        instance_id: instance_id.to_string(),
        role: "user".to_string(),
        content: content.to_string(),
        model: None,
        input_tokens: None,
        output_tokens: None,
        turn_id: None,
        sender_name: None,
        created_at: now,
    }
}

#[tokio::test]
async fn test_workspace_insert_and_watch() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    let mut stream = dao.watch_workspaces();

    // Initial — empty.
    let first = stream.next().await.unwrap().unwrap();
    assert!(first.is_empty());

    // Insert workspace.
    let ws = make_workspace("ws-1", "Test Workspace");
    dao.insert_workspace(&ws).unwrap();

    // Should re-emit.
    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout")
        .unwrap()
        .unwrap();
    assert_eq!(second.len(), 1);
    assert_eq!(second[0].name, "Test Workspace");
}

#[tokio::test]
async fn test_workspace_run_insert_and_watch() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();

    let mut stream = dao.watch_workspace_runs("ws-1");

    // Initial — empty.
    let first = stream.next().await.unwrap().unwrap();
    assert!(first.is_empty());

    // Insert run.
    let run = make_run("run-1", "ws-1", 1, "starting");
    dao.insert_workspace_run(&run).unwrap();

    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout")
        .unwrap()
        .unwrap();
    assert_eq!(second.len(), 1);
    assert_eq!(second[0].status, "starting");
}

#[tokio::test]
async fn test_workspace_agent_insert_and_watch() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();

    let mut stream = dao.watch_workspace_agents("run-1");

    let first = stream.next().await.unwrap().unwrap();
    assert!(first.is_empty());

    let agent = make_agent("ag-1", "run-1", "coder", "inst-1");
    dao.insert_workspace_agent(&agent).unwrap();

    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout")
        .unwrap()
        .unwrap();
    assert_eq!(second.len(), 1);
    assert_eq!(second[0].agent_key, "coder");
}

#[tokio::test]
async fn test_message_insert_and_watch() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();

    let mut stream = dao.watch_agent_messages("run-1", "inst-1");

    let first = stream.next().await.unwrap().unwrap();
    assert!(first.is_empty());

    let msg = make_message("msg-1", "run-1", "inst-1", "Hello");
    dao.insert_agent_message(&msg).unwrap();

    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout")
        .unwrap()
        .unwrap();
    assert_eq!(second.len(), 1);
    assert_eq!(second[0].content, "Hello");
}

#[test]
fn test_append_agent_message_content() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();

    let msg = make_message("msg-1", "run-1", "inst-1", "Hello");
    dao.insert_agent_message(&msg).unwrap();

    // Append content.
    dao.append_agent_message_content("msg-1", " World").unwrap();

    // Verify.
    let _messages = dao.get_messages_for_turn("inst-1", "").ok();
    // The turn_id is None, so try reading directly.
    let conn = db.conn();
    let content: String = conn
        .query_row(
            "SELECT content FROM agent_messages WHERE id = 'msg-1'",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(content, "Hello World");
}

#[test]
fn test_cascading_delete_workspace() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    // Set up hierarchy.
    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "stopped"))
        .unwrap();
    dao.insert_workspace_agent(&make_agent("ag-1", "run-1", "coder", "inst-1"))
        .unwrap();
    dao.insert_agent_message(&make_message("msg-1", "run-1", "inst-1", "Hi"))
        .unwrap();

    // Insert an inquiry too.
    let inquiry = WorkspaceInquiry {
        id: "inq-1".to_string(),
        run_id: "run-1".to_string(),
        agent_key: "coder".to_string(),
        instance_id: "inst-1".to_string(),
        status: InquiryStatus::Pending,
        priority: InquiryPriority::Normal,
        content_markdown: "What should I do?".to_string(),
        attachments_json: None,
        suggestions_json: None,
        response_text: None,
        response_suggestion_index: None,
        responded_by_agent_key: None,
        forwarding_chain_json: None,
        created_at: now(),
        responded_at: None,
    };
    dao.insert_workspace_inquiry(&inquiry).unwrap();

    // Delete workspace — should cascade.
    dao.delete_workspace("ws-1").unwrap();

    // Verify everything is gone.
    let conn = db.conn();
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM workspaces", [], |row| row.get(0))
        .unwrap();
    assert_eq!(count, 0);

    let run_count: i64 = conn
        .query_row("SELECT COUNT(*) FROM workspace_runs", [], |row| row.get(0))
        .unwrap();
    assert_eq!(run_count, 0);

    let agent_count: i64 = conn
        .query_row("SELECT COUNT(*) FROM workspace_agents", [], |row| row.get(0))
        .unwrap();
    assert_eq!(agent_count, 0);

    let msg_count: i64 = conn
        .query_row("SELECT COUNT(*) FROM agent_messages", [], |row| row.get(0))
        .unwrap();
    assert_eq!(msg_count, 0);

    let inq_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM workspace_inquiries",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(inq_count, 0);
}

#[tokio::test]
async fn test_watch_all_inquiries_join() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    // Set up.
    dao.insert_workspace(&make_workspace("ws-1", "My Workspace"))
        .unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();

    let inquiry = WorkspaceInquiry {
        id: "inq-1".to_string(),
        run_id: "run-1".to_string(),
        agent_key: "coder".to_string(),
        instance_id: "inst-1".to_string(),
        status: InquiryStatus::Pending,
        priority: InquiryPriority::High,
        content_markdown: "Need help".to_string(),
        attachments_json: None,
        suggestions_json: None,
        response_text: None,
        response_suggestion_index: None,
        responded_by_agent_key: None,
        forwarding_chain_json: None,
        created_at: now(),
        responded_at: None,
    };
    dao.insert_workspace_inquiry(&inquiry).unwrap();

    let mut stream = dao.watch_all_inquiries();

    let first = stream.next().await.unwrap().unwrap();
    assert_eq!(first.len(), 1);
    assert_eq!(first[0].workspace_name, "My Workspace");
    assert_eq!(first[0].workspace_id, "ws-1");
    assert_eq!(first[0].inquiry.id, "inq-1");
}

#[tokio::test]
async fn test_watch_pending_inquiry_count() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();

    let mut stream = dao.watch_pending_inquiry_count();

    // Initial — 0.
    let first = stream.next().await.unwrap().unwrap();
    assert_eq!(first, 0);

    // Add a pending inquiry.
    let inquiry = WorkspaceInquiry {
        id: "inq-1".to_string(),
        run_id: "run-1".to_string(),
        agent_key: "coder".to_string(),
        instance_id: "inst-1".to_string(),
        status: InquiryStatus::Pending,
        priority: InquiryPriority::Normal,
        content_markdown: "Question".to_string(),
        attachments_json: None,
        suggestions_json: None,
        response_text: None,
        response_suggestion_index: None,
        responded_by_agent_key: None,
        forwarding_chain_json: None,
        created_at: now(),
        responded_at: None,
    };
    dao.insert_workspace_inquiry(&inquiry).unwrap();

    let second = tokio::time::timeout(std::time::Duration::from_secs(2), stream.next())
        .await
        .expect("Timeout")
        .unwrap()
        .unwrap();
    assert_eq!(second, 1);
}

#[test]
fn test_next_run_number() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();

    // No runs yet — should be 1.
    assert_eq!(dao.next_run_number("ws-1").unwrap(), 1);

    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "stopped"))
        .unwrap();
    assert_eq!(dao.next_run_number("ws-1").unwrap(), 2);

    dao.insert_workspace_run(&make_run("run-2", "ws-1", 2, "running"))
        .unwrap();
    assert_eq!(dao.next_run_number("ws-1").unwrap(), 3);
}

#[test]
fn test_get_active_run() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();

    // No runs.
    assert!(dao.get_active_run("ws-1").unwrap().is_none());

    // Stopped run — not active.
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "stopped"))
        .unwrap();
    assert!(dao.get_active_run("ws-1").unwrap().is_none());

    // Running run.
    dao.insert_workspace_run(&make_run("run-2", "ws-1", 2, "running"))
        .unwrap();
    let active = dao.get_active_run("ws-1").unwrap().unwrap();
    assert_eq!(active.id, "run-2");
}

#[test]
fn test_update_run_status_and_deployment() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "starting"))
        .unwrap();

    // Update status.
    dao.update_run_status("run-1", "running", None).unwrap();
    let active = dao.get_active_run("ws-1").unwrap().unwrap();
    assert_eq!(active.status, "running");

    // Update deployment.
    dao.update_run_deployment("run-1", Some("ctr-abc"), Some(8080), Some("key-xyz"))
        .unwrap();

    // Verify via direct query.
    let conn = db.conn();
    let (cid, port, key): (String, i64, String) = conn
        .query_row(
            "SELECT container_id, server_port, api_key FROM workspace_runs WHERE id = 'run-1'",
            [],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )
        .unwrap();
    assert_eq!(cid, "ctr-abc");
    assert_eq!(port, 8080);
    assert_eq!(key, "key-xyz");
}

#[test]
fn test_update_agent_status() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();
    dao.insert_workspace_agent(&make_agent("ag-1", "run-1", "coder", "inst-1"))
        .unwrap();

    // Update status.
    dao.update_agent_status("inst-1", &AgentState::Generating)
        .unwrap();

    let agent = dao
        .find_workspace_agent_by_instance_id("run-1", "inst-1")
        .unwrap()
        .unwrap();
    assert_eq!(agent.status, AgentState::Generating);
}

#[test]
fn test_insert_instance_result() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-1", 1, "running"))
        .unwrap();

    dao.insert_instance_result("res-1", "run-1", "coder", "inst-1", "turn-1", Some("req-1"))
        .unwrap();

    // Verify.
    let conn = db.conn();
    let count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM instance_results WHERE id = 'res-1'",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(count, 1);
}

// ── Helper: set up workspace + run for ephemeral DAO tests ─────────

fn setup_workspace_and_run(db: &Arc<Database>, ws_id: &str, run_id: &str) {
    let dao = WorkspaceDao::new(Arc::clone(db));
    dao.insert_workspace(&make_workspace(ws_id, "Test WS")).unwrap();
    dao.insert_workspace_run(&make_run(run_id, ws_id, 1, "running")).unwrap();
}

fn setup_two_runs(db: &Arc<Database>) {
    let dao = WorkspaceDao::new(Arc::clone(db));
    dao.insert_workspace(&make_workspace("ws-e", "Test WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-1", "ws-e", 1, "running")).unwrap();
    dao.insert_workspace_run(&make_run("run-2", "ws-e", 2, "running")).unwrap();
}

// ── AgentInstanceStateDao ──────────────────────────────────────────

#[test]
fn test_agent_instance_state_upsert_and_get() {
    let db = db();
    setup_workspace_and_run(&db, "ws-e", "run-1");
    let dao = AgentInstanceStateDao::new();
    let conn = db.conn();

    // Initially empty.
    assert!(dao.get(&conn, "inst-1").unwrap().is_none());

    // Upsert.
    dao.upsert(&conn, "inst-1", "run-1", "coder", "idle").unwrap();
    let state = dao.get(&conn, "inst-1").unwrap().unwrap();
    assert_eq!(state.instance_id, "inst-1");
    assert_eq!(state.run_id, "run-1");
    assert_eq!(state.agent_key, "coder");
    assert_eq!(state.state, "idle");

    // Upsert again — should update state.
    dao.upsert(&conn, "inst-1", "run-1", "coder", "generating").unwrap();
    let state = dao.get(&conn, "inst-1").unwrap().unwrap();
    assert_eq!(state.state, "generating");
}

#[test]
fn test_agent_instance_state_delete_for_run() {
    let db = db();
    setup_two_runs(&db);
    let dao = AgentInstanceStateDao::new();
    let conn = db.conn();

    dao.upsert(&conn, "inst-1", "run-1", "coder", "idle").unwrap();
    dao.upsert(&conn, "inst-2", "run-1", "reviewer", "idle").unwrap();
    dao.upsert(&conn, "inst-3", "run-2", "coder", "idle").unwrap();

    // Delete for run-1.
    dao.delete_for_run(&conn, "run-1").unwrap();

    // run-1 instances gone.
    assert!(dao.get(&conn, "inst-1").unwrap().is_none());
    assert!(dao.get(&conn, "inst-2").unwrap().is_none());
    // run-2 instance remains.
    assert!(dao.get(&conn, "inst-3").unwrap().is_some());
}

// ── AgentConnectionStatusDao ───────────────────────────────────────

#[test]
fn test_agent_connection_status_upsert_and_get() {
    let db = db();
    setup_workspace_and_run(&db, "ws-e", "run-1");
    let dao = AgentConnectionStatusDao::new();
    let conn = db.conn();

    // Initially empty.
    assert!(dao.get(&conn, "coder", "run-1").unwrap().is_none());

    // Upsert connected.
    dao.upsert(&conn, "coder", "run-1", true).unwrap();
    let status = dao.get(&conn, "coder", "run-1").unwrap().unwrap();
    assert!(status.connected);
    assert_eq!(status.agent_key, "coder");
    assert_eq!(status.run_id, "run-1");

    // Upsert disconnected.
    dao.upsert(&conn, "coder", "run-1", false).unwrap();
    let status = dao.get(&conn, "coder", "run-1").unwrap().unwrap();
    assert!(!status.connected);
}

#[test]
fn test_agent_connection_status_disconnect_all_for_run() {
    let db = db();
    setup_two_runs(&db);
    let dao = AgentConnectionStatusDao::new();
    let conn = db.conn();

    dao.upsert(&conn, "coder", "run-1", true).unwrap();
    dao.upsert(&conn, "reviewer", "run-1", true).unwrap();
    dao.upsert(&conn, "coder", "run-2", true).unwrap();

    // Disconnect all for run-1.
    dao.disconnect_all_for_run(&conn, "run-1").unwrap();

    assert!(!dao.get(&conn, "coder", "run-1").unwrap().unwrap().connected);
    assert!(!dao.get(&conn, "reviewer", "run-1").unwrap().unwrap().connected);
    // run-2 unaffected.
    assert!(dao.get(&conn, "coder", "run-2").unwrap().unwrap().connected);
}

// ── ContainerHealthDao ─────────────────────────────────────────────

#[test]
fn test_container_health_upsert_and_get() {
    let db = db();
    setup_workspace_and_run(&db, "ws-e", "run-1");
    let dao = ContainerHealthDao::new();
    let conn = db.conn();

    // Initially empty.
    assert!(dao.get(&conn, "run-1").unwrap().is_none());

    // Upsert healthy.
    dao.upsert(&conn, "run-1", "healthy", None).unwrap();
    let health = dao.get(&conn, "run-1").unwrap().unwrap();
    assert_eq!(health.status, "healthy");
    assert!(health.error_message.is_none());

    // Upsert unhealthy with error.
    dao.upsert(&conn, "run-1", "unhealthy", Some("OOM killed")).unwrap();
    let health = dao.get(&conn, "run-1").unwrap().unwrap();
    assert_eq!(health.status, "unhealthy");
    assert_eq!(health.error_message.as_deref(), Some("OOM killed"));
}

// ── WorkspaceRunStatusDao ──────────────────────────────────────────

#[test]
fn test_workspace_run_status_upsert_and_get() {
    let db = db();
    setup_workspace_and_run(&db, "ws-e", "run-1");
    let dao = WorkspaceRunStatusDao::new();
    let conn = db.conn();

    // Initially empty.
    assert!(dao.get(&conn, "run-1").unwrap().is_none());

    // Upsert.
    dao.upsert(&conn, "run-1", "starting").unwrap();
    let status = dao.get(&conn, "run-1").unwrap().unwrap();
    assert_eq!(status.run_id, "run-1");
    assert_eq!(status.status, "starting");

    // Upsert again — should update.
    dao.upsert(&conn, "run-1", "running").unwrap();
    let status = dao.get(&conn, "run-1").unwrap().unwrap();
    assert_eq!(status.status, "running");
}

// ── Transaction safety: multi-step deletes ─────────────────────────

/// Populate every child table for a run so delete tests can verify
/// all rows are removed. The `prefix` is used to make IDs unique across
/// multiple calls (e.g. different runs in the same test).
fn populate_run_children(dao: &WorkspaceDao, run_id: &str, instance_id: &str, prefix: &str) {
    let ts = now();

    // workspace_agents
    dao.insert_workspace_agent(&make_agent(
        &format!("{prefix}-ag"),
        run_id,
        "coder",
        instance_id,
    ))
    .unwrap();

    // agent_messages
    dao.insert_agent_message(&make_message(
        &format!("{prefix}-msg"),
        run_id,
        instance_id,
        "hello",
    ))
    .unwrap();

    // agent_activity_events
    dao.insert_agent_activity(&AgentActivity {
        id: format!("{prefix}-act"),
        run_id: run_id.to_string(),
        agent_key: "coder".to_string(),
        instance_id: instance_id.to_string(),
        turn_id: None,
        event_type: "tool_call".to_string(),
        data_json: None,
        content: None,
        timestamp: ts,
    })
    .unwrap();

    // agent_logs
    dao.insert_agent_log(&AgentLog {
        id: format!("{prefix}-log"),
        run_id: run_id.to_string(),
        agent_key: "coder".to_string(),
        instance_id: instance_id.to_string(),
        turn_id: None,
        level: LogLevel::Info,
        message: "test".to_string(),
        source: LogSource::Agent,
        timestamp: ts,
    })
    .unwrap();

    // agent_usage_records
    dao.insert_agent_usage(&AgentUsage {
        id: format!("{prefix}-usage"),
        run_id: run_id.to_string(),
        agent_key: "coder".to_string(),
        instance_id: instance_id.to_string(),
        turn_id: None,
        model: "claude-3".to_string(),
        input_tokens: 100,
        output_tokens: 50,
        cache_read_tokens: 0,
        cache_write_tokens: 0,
        cost_usd: 0.001,
        timestamp: ts,
    })
    .unwrap();

    // agent_files
    dao.insert_agent_file(&AgentFile {
        id: format!("{prefix}-file"),
        run_id: run_id.to_string(),
        agent_key: "coder".to_string(),
        instance_id: instance_id.to_string(),
        turn_id: None,
        file_path: "/tmp/test.txt".to_string(),
        operation: "write".to_string(),
        timestamp: ts,
    })
    .unwrap();

    // workspace_inquiries
    dao.insert_workspace_inquiry(&WorkspaceInquiry {
        id: format!("{prefix}-inq"),
        run_id: run_id.to_string(),
        agent_key: "coder".to_string(),
        instance_id: instance_id.to_string(),
        status: InquiryStatus::Pending,
        priority: InquiryPriority::Normal,
        content_markdown: "question".to_string(),
        attachments_json: None,
        suggestions_json: None,
        response_text: None,
        response_suggestion_index: None,
        responded_by_agent_key: None,
        forwarding_chain_json: None,
        created_at: ts,
        responded_at: None,
    })
    .unwrap();

    // instance_results
    dao.insert_instance_result(
        &format!("{prefix}-res"),
        run_id,
        "coder",
        instance_id,
        "turn-1",
        None,
    )
    .unwrap();
}

fn count_rows(conn: &rusqlite::Connection, table: &str, col: &str, val: &str) -> i64 {
    conn.query_row(
        &format!("SELECT COUNT(*) FROM {table} WHERE {col} = ?1"),
        rusqlite::params![val],
        |row| row.get(0),
    )
    .unwrap()
}

#[test]
fn test_delete_workspace_run_removes_all_child_tables() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-t1", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-t1", "ws-t1", 1, "stopped"))
        .unwrap();
    populate_run_children(&dao, "run-t1", "inst-t1", "t1");

    // Sanity: child rows exist before delete.
    {
        let conn = db.conn();
        assert_eq!(count_rows(&conn, "workspace_agents", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "agent_messages", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "agent_activity_events", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "agent_logs", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "agent_usage_records", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "agent_files", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "workspace_inquiries", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "instance_results", "run_id", "run-t1"), 1);
        assert_eq!(count_rows(&conn, "workspace_runs", "id", "run-t1"), 1);
    }

    // Execute the transactional delete.
    dao.delete_workspace_run("run-t1").unwrap();

    // All rows must be gone.
    let conn = db.conn();
    assert_eq!(count_rows(&conn, "workspace_agents", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "agent_messages", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "agent_activity_events", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "agent_logs", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "agent_usage_records", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "agent_files", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "workspace_inquiries", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "instance_results", "run_id", "run-t1"), 0);
    assert_eq!(count_rows(&conn, "workspace_runs", "id", "run-t1"), 0);
}

#[test]
fn test_delete_agent_instance_removes_all_child_tables() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-t2", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-t2", "ws-t2", 1, "running"))
        .unwrap();
    populate_run_children(&dao, "run-t2", "inst-t2", "t2");

    // Sanity: child rows exist.
    {
        let conn = db.conn();
        assert_eq!(count_rows(&conn, "workspace_agents", "instance_id", "inst-t2"), 1);
        assert_eq!(count_rows(&conn, "agent_messages", "instance_id", "inst-t2"), 1);
    }

    // Execute the transactional delete.
    dao.delete_agent_instance("inst-t2").unwrap();

    // All per-instance rows must be gone.
    let conn = db.conn();
    assert_eq!(count_rows(&conn, "workspace_agents", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "agent_messages", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "agent_activity_events", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "agent_logs", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "agent_usage_records", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "agent_files", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "workspace_inquiries", "instance_id", "inst-t2"), 0);
    assert_eq!(count_rows(&conn, "instance_results", "instance_id", "inst-t2"), 0);

    // The run itself should still exist (delete_agent_instance only clears
    // per-instance data, not the run row).
    assert_eq!(count_rows(&conn, "workspace_runs", "id", "run-t2"), 1);
}

#[test]
fn test_delete_workspace_is_fully_atomic_across_all_runs() {
    let db = db();
    let dao = WorkspaceDao::new(Arc::clone(&db));

    dao.insert_workspace(&make_workspace("ws-t3", "WS")).unwrap();
    dao.insert_workspace_run(&make_run("run-t3a", "ws-t3", 1, "stopped"))
        .unwrap();
    dao.insert_workspace_run(&make_run("run-t3b", "ws-t3", 2, "stopped"))
        .unwrap();
    populate_run_children(&dao, "run-t3a", "inst-t3a", "t3a");
    populate_run_children(&dao, "run-t3b", "inst-t3b", "t3b");

    // Delete the entire workspace in one transaction.
    dao.delete_workspace("ws-t3").unwrap();

    let conn = db.conn();
    // Workspace row gone.
    assert_eq!(count_rows(&conn, "workspaces", "id", "ws-t3"), 0);
    // Both runs gone.
    assert_eq!(count_rows(&conn, "workspace_runs", "id", "run-t3a"), 0);
    assert_eq!(count_rows(&conn, "workspace_runs", "id", "run-t3b"), 0);
    // All child data gone.
    assert_eq!(count_rows(&conn, "agent_messages", "run_id", "run-t3a"), 0);
    assert_eq!(count_rows(&conn, "agent_messages", "run_id", "run-t3b"), 0);
    assert_eq!(count_rows(&conn, "agent_logs", "run_id", "run-t3a"), 0);
    assert_eq!(count_rows(&conn, "workspace_inquiries", "run_id", "run-t3b"), 0);
}
