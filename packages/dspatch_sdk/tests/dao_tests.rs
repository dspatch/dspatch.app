// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the DAO layer.

use std::sync::Arc;

use chrono::NaiveDateTime;
use futures::StreamExt;

use dspatch_sdk::db::dao::{
    ApiKeyDao, PreferenceDao, WorkspaceDao,
};
use dspatch_sdk::db::Database;
use dspatch_sdk::domain::enums::{AgentState, InquiryPriority, InquiryStatus};
use dspatch_sdk::domain::models::{
    AgentMessage, Workspace, WorkspaceAgent, WorkspaceInquiry, WorkspaceRun,
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
