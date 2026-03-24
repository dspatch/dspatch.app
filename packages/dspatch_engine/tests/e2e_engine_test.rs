// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! End-to-end smoke test for the full engine lifecycle.
//!
//! Starts a real engine on an ephemeral port, connects via WebSocket,
//! authenticates, sends a command, and verifies the response.

use std::sync::Arc;
use std::time::Duration;

use dspatch_engine::client_api::invalidation::InvalidationBroadcaster;
use dspatch_engine::client_api::server::start_client_api;
use dspatch_engine::engine::config::EngineConfig;
use dspatch_engine::engine::service_registry::ServiceRegistry;
use dspatch_engine::engine::startup::{open_database, ClientApiRuntime};

use futures::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio::time::timeout;
use tokio_tungstenite::{connect_async, tungstenite::Message};

/// Bind an ephemeral port, return the port, then drop the listener.
/// There's a small race window, but it works for tests.
fn find_free_port() -> u16 {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    listener.local_addr().unwrap().port()
}

/// Start the engine on the given port.
async fn start_engine_on_port(
    tmp_dir: &std::path::Path,
    port: u16,
) -> Arc<ClientApiRuntime> {
    let config = EngineConfig {
        client_api_port: port,
        db_dir: tmp_dir.to_path_buf(),
        log_level: "error".to_string(),
        agent_server_port: 0,
        invalidation_debounce_ms: 10,
    };

    std::fs::create_dir_all(&config.db_dir).unwrap();
    let db_path = config.db_dir.join("engine.db");
    let db = Arc::new(open_database(&db_path).unwrap());

    let broadcaster = InvalidationBroadcaster::new(db.tracker().clone(), 10);
    let invalidation_handle = broadcaster.start();

    let registry = Arc::new(ServiceRegistry::new(db, config.db_dir.clone(), None));
    let runtime = Arc::new(ClientApiRuntime::with_services_and_invalidation(
        config,
        registry,
        invalidation_handle,
    ));

    let api_runtime = runtime.clone();
    let shutdown_rx = runtime.subscribe_shutdown();

    tokio::spawn(async move {
        if let Err(e) = start_client_api(api_runtime, shutdown_rx, None).await {
            eprintln!("client API error: {e}");
        }
    });

    // Give the server a moment to bind.
    tokio::time::sleep(Duration::from_millis(200)).await;

    runtime
}

#[tokio::test]
async fn engine_lifecycle_smoke_test() {
    let tmp = tempfile::tempdir().unwrap();
    let port = find_free_port();
    let runtime = start_engine_on_port(tmp.path(), port).await;

    // 1. Health check via HTTP
    let health_url = format!("http://127.0.0.1:{port}/health");
    let health_resp = reqwest::get(&health_url).await.expect("health request failed");
    assert_eq!(health_resp.status(), 200);
    let health: Value = health_resp.json().await.unwrap();
    assert_eq!(health["status"], "running");

    // 2. Anonymous auth via HTTP
    let auth_url = format!("http://127.0.0.1:{port}/auth/anonymous");
    let auth_resp = reqwest::Client::new()
        .post(&auth_url)
        .json(&json!({}))
        .send()
        .await
        .expect("auth request failed");
    assert_eq!(auth_resp.status(), 200);
    let auth: Value = auth_resp.json().await.unwrap();
    let token = auth["session_token"].as_str().expect("no session_token in auth response");
    assert!(!token.is_empty());

    // 3. Connect WebSocket with session token
    let ws_url = format!("ws://127.0.0.1:{port}/ws?token={token}");
    let (mut ws, _) = connect_async(&ws_url)
        .await
        .expect("WebSocket connect failed");

    // 4. Read the welcome event (sent on connect)
    let welcome = timeout(Duration::from_secs(5), ws.next())
        .await
        .expect("timed out waiting for welcome")
        .expect("stream ended")
        .expect("read error");

    let welcome_val: Value = match welcome {
        Message::Text(t) => serde_json::from_str(t.as_ref()).unwrap(),
        other => panic!("expected text, got {other:?}"),
    };
    // The welcome message has type "event" with event name "welcome".
    assert_eq!(welcome_val["type"], "event");

    // 5. Send a list_workspaces command
    let cmd = json!({
        "id": "cmd_1",
        "type": "command",
        "method": "list_workspaces",
        "params": {}
    });
    ws.send(Message::Text(cmd.to_string().into())).await.unwrap();

    // 6. Read the response
    let resp_msg = timeout(Duration::from_secs(5), ws.next())
        .await
        .expect("timed out waiting for response")
        .expect("stream ended")
        .expect("read error");

    let resp: Value = match resp_msg {
        Message::Text(t) => serde_json::from_str(t.as_ref()).unwrap(),
        other => panic!("expected text, got {other:?}"),
    };
    assert_eq!(resp["id"], "cmd_1");
    // The server dispatched the command and returned a response frame.
    // Accept "result" or "error" — either means the engine processed it.
    assert!(
        resp["type"] == "result" || resp["type"] == "error",
        "unexpected response type: {}",
        resp["type"]
    );

    // 7. Close and shutdown
    ws.close(None).await.ok();
    runtime.trigger_shutdown();
    tokio::time::sleep(Duration::from_millis(300)).await;
}

#[tokio::test]
async fn health_endpoint_works_before_auth() {
    let tmp = tempfile::tempdir().unwrap();
    let port = find_free_port();
    let runtime = start_engine_on_port(tmp.path(), port).await;

    let health_url = format!("http://127.0.0.1:{port}/health");
    let resp = reqwest::get(&health_url).await.unwrap();
    assert_eq!(resp.status(), 200);

    let body: Value = resp.json().await.unwrap();
    assert_eq!(body["status"], "running");
    assert!(body["uptime_seconds"].as_f64().unwrap() >= 0.0);

    runtime.trigger_shutdown();
    tokio::time::sleep(Duration::from_millis(200)).await;
}
