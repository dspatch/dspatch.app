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

#[tokio::test]
async fn health_endpoint_returns_running_status() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::health::HealthResponse;
    use dspatch_sdk::client_api::server::build_router;

    use axum::body::Body;
    use http::Request;
    use tower::ServiceExt;

    let app = build_router(Arc::new(EngineRuntime::new(EngineConfig::default())));
    let req = Request::builder()
        .uri("/health")
        .body(Body::empty())
        .unwrap();

    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), http::StatusCode::OK);

    let body = axum::body::to_bytes(resp.into_body(), 1024).await.unwrap();
    let health: HealthResponse = serde_json::from_slice(&body).unwrap();

    assert_eq!(health.status, "running");
    assert!(!health.authenticated);
    assert_eq!(health.connected_devices, 0);
    assert!(health.uptime_seconds < 5);
}

#[tokio::test]
async fn client_api_server_starts_and_responds_to_health() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::health::HealthResponse;

    let mut config = EngineConfig::default();
    config.client_api_port = 0; // OS-assigned port
    let runtime = Arc::new(EngineRuntime::new(config));

    let runtime_clone = runtime.clone();

    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async move {
        let port = runtime_clone.config().client_api_port;
        let addr = format!("127.0.0.1:{port}");
        let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
        let actual_port = listener.local_addr().unwrap().port();
        let _ = port_tx.send(actual_port);

        let app = dspatch_sdk::client_api::server::build_router(runtime_clone.clone());
        let mut shutdown = runtime_clone.subscribe_shutdown();
        axum::serve(listener, app)
            .with_graceful_shutdown(async move {
                let _ = shutdown.recv().await;
            })
            .await
            .unwrap();
    });

    let port = port_rx.await.unwrap();

    let url = format!("http://127.0.0.1:{port}/health");
    let resp = reqwest::get(&url).await.expect("GET /health should succeed");
    assert_eq!(resp.status(), 200);

    let health: HealthResponse = resp.json().await.unwrap();
    assert_eq!(health.status, "running");

    runtime.trigger_shutdown();
    let _ = tokio::time::timeout(std::time::Duration::from_secs(5), server_handle).await;
}

#[test]
fn session_store_insert_and_validate() {
    use dspatch_sdk::client_api::session::{SessionStore, AuthMode};

    let store = SessionStore::new();
    let token = store.create_session(AuthMode::Anonymous, None);
    assert!(!token.is_empty());
    assert_eq!(token.len(), 64); // 32 bytes = 64 hex chars

    let session = store.validate(&token);
    assert!(session.is_some());
    let session = session.unwrap();
    assert_eq!(session.auth_mode, AuthMode::Anonymous);
    assert!(session.username.is_none());

    assert!(store.validate("bogus-token").is_none());
}

#[test]
fn session_store_remove() {
    use dspatch_sdk::client_api::session::{SessionStore, AuthMode};

    let store = SessionStore::new();
    let token = store.create_session(AuthMode::Connected, Some("alice".into()));

    assert!(store.validate(&token).is_some());
    store.remove(&token);
    assert!(store.validate(&token).is_none());
}

#[test]
fn session_store_connected_mode_has_username() {
    use dspatch_sdk::client_api::session::{SessionStore, AuthMode};

    let store = SessionStore::new();
    let token = store.create_session(AuthMode::Connected, Some("bob".into()));

    let session = store.validate(&token).unwrap();
    assert_eq!(session.auth_mode, AuthMode::Connected);
    assert_eq!(session.username.as_deref(), Some("bob"));
}

#[tokio::test]
async fn auth_anonymous_returns_session_token() {
    use std::sync::Arc;
    use axum::body::Body;
    use http::Request;
    use tower::ServiceExt;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::server::build_router;

    let runtime = Arc::new(EngineRuntime::new(EngineConfig::default()));
    let app = build_router(runtime);

    let req = Request::builder()
        .method("POST")
        .uri("/auth/anonymous")
        .body(Body::empty())
        .unwrap();

    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), http::StatusCode::OK);

    let body = axum::body::to_bytes(resp.into_body(), 4096).await.unwrap();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();

    let token = json["session_token"].as_str().unwrap();
    assert_eq!(token.len(), 64);
    assert_eq!(json["auth_mode"].as_str().unwrap(), "anonymous");
}

#[tokio::test]
async fn auth_login_without_backend_returns_error() {
    use std::sync::Arc;
    use axum::body::Body;
    use http::Request;
    use tower::ServiceExt;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::server::build_router;

    let runtime = Arc::new(EngineRuntime::new(EngineConfig::default()));
    let app = build_router(runtime);

    let req = Request::builder()
        .method("POST")
        .uri("/auth/login")
        .header("Content-Type", "application/json")
        .body(Body::from(r#"{"username":"alice","password":"secret"}"#))
        .unwrap();

    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), http::StatusCode::SERVICE_UNAVAILABLE);

    let body = axum::body::to_bytes(resp.into_body(), 4096).await.unwrap();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert!(json["error"].as_str().is_some());
}

#[tokio::test]
async fn auth_register_without_backend_returns_error() {
    use std::sync::Arc;
    use axum::body::Body;
    use http::Request;
    use tower::ServiceExt;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::server::build_router;

    let runtime = Arc::new(EngineRuntime::new(EngineConfig::default()));
    let app = build_router(runtime);

    let req = Request::builder()
        .method("POST")
        .uri("/auth/register")
        .header("Content-Type", "application/json")
        .body(Body::from(
            r#"{"username":"alice","email":"alice@example.com","password":"secret123"}"#,
        ))
        .unwrap();

    let resp = app.oneshot(req).await.unwrap();
    assert_eq!(resp.status(), http::StatusCode::SERVICE_UNAVAILABLE);
}

#[test]
fn protocol_command_frame_serialization() {
    use dspatch_sdk::client_api::protocol::ClientFrame;

    let json = r#"{"id":"cmd_1","type":"command","method":"launch_workspace","params":{"workspace_id":"abc"}}"#;
    let frame: ClientFrame = serde_json::from_str(json).unwrap();

    match frame {
        ClientFrame::Command { id, method, params } => {
            assert_eq!(id, "cmd_1");
            assert_eq!(method, "launch_workspace");
            assert_eq!(params["workspace_id"], "abc");
        }
    }
}

#[test]
fn protocol_result_frame_serialization() {
    use dspatch_sdk::client_api::protocol::ServerFrame;

    let frame = ServerFrame::Result {
        id: "cmd_1".into(),
        data: serde_json::json!({"run_id": "xyz"}),
    };
    let json = serde_json::to_string(&frame).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();

    assert_eq!(parsed["id"], "cmd_1");
    assert_eq!(parsed["type"], "result");
    assert_eq!(parsed["data"]["run_id"], "xyz");
}

#[test]
fn protocol_error_frame_serialization() {
    use dspatch_sdk::client_api::protocol::ServerFrame;

    let frame = ServerFrame::Error {
        id: Some("cmd_1".into()),
        code: "NOT_IMPLEMENTED".into(),
        message: "Command not implemented".into(),
    };
    let json = serde_json::to_string(&frame).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();

    assert_eq!(parsed["type"], "error");
    assert_eq!(parsed["id"], "cmd_1");
    assert_eq!(parsed["code"], "NOT_IMPLEMENTED");
}

#[test]
fn protocol_invalidate_frame_serialization() {
    use dspatch_sdk::client_api::protocol::ServerFrame;

    let frame = ServerFrame::Invalidate {
        tables: vec!["agent_messages".into(), "workspace_runs".into()],
    };
    let json = serde_json::to_string(&frame).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();

    assert_eq!(parsed["type"], "invalidate");
    assert_eq!(parsed["tables"][0], "agent_messages");
    assert_eq!(parsed["tables"][1], "workspace_runs");
}

#[test]
fn protocol_event_frame_serialization() {
    use dspatch_sdk::client_api::protocol::ServerFrame;

    let frame = ServerFrame::Event {
        name: "engine_shutting_down".into(),
        data: serde_json::json!({}),
    };
    let json = serde_json::to_string(&frame).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();

    assert_eq!(parsed["type"], "event");
    assert_eq!(parsed["name"], "engine_shutting_down");
}

#[test]
fn protocol_welcome_event() {
    use dspatch_sdk::client_api::protocol::ServerFrame;

    let frame = ServerFrame::welcome();
    let json = serde_json::to_string(&frame).unwrap();
    let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();

    assert_eq!(parsed["type"], "event");
    assert_eq!(parsed["name"], "welcome");
}

#[tokio::test]
async fn ws_rejects_unauthenticated_connection() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;

    let mut config = EngineConfig::default();
    config.client_api_port = 0;
    let runtime = Arc::new(EngineRuntime::new(config));

    let runtime_clone = runtime.clone();
    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async move {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let _ = port_tx.send(port);
        let app = dspatch_sdk::client_api::server::build_router(runtime_clone.clone());
        let mut shutdown = runtime_clone.subscribe_shutdown();
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { let _ = shutdown.recv().await; })
            .await
            .unwrap();
    });

    let port = port_rx.await.unwrap();

    let url = format!("ws://127.0.0.1:{port}/ws?token=invalid-token");
    let result = tokio_tungstenite::connect_async(&url).await;
    assert!(result.is_err(), "WS connect with invalid token should fail");

    runtime.trigger_shutdown();
    let _ = tokio::time::timeout(std::time::Duration::from_secs(5), server_handle).await;
}

#[tokio::test]
async fn ws_accepts_authenticated_connection_and_sends_welcome() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::session::AuthMode;
    use futures::StreamExt;

    let mut config = EngineConfig::default();
    config.client_api_port = 0;
    let runtime = Arc::new(EngineRuntime::new(config));
    let token = runtime.session_store().create_session(AuthMode::Anonymous, None);

    let runtime_clone = runtime.clone();
    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async move {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let _ = port_tx.send(port);
        let app = dspatch_sdk::client_api::server::build_router(runtime_clone.clone());
        let mut shutdown = runtime_clone.subscribe_shutdown();
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { let _ = shutdown.recv().await; })
            .await
            .unwrap();
    });

    let port = port_rx.await.unwrap();

    let url = format!("ws://127.0.0.1:{port}/ws?token={token}");
    let (mut ws, _) = tokio_tungstenite::connect_async(&url)
        .await
        .expect("WS connect with valid token should succeed");

    let msg = tokio::time::timeout(
        std::time::Duration::from_secs(5),
        ws.next(),
    )
    .await
    .expect("should receive message within timeout")
    .expect("stream should not be closed")
    .expect("message should not be an error");

    let text = msg.into_text().expect("message should be text");
    let frame: serde_json::Value = serde_json::from_str(&text).unwrap();
    assert_eq!(frame["type"], "event");
    assert_eq!(frame["name"], "welcome");
    assert_eq!(frame["data"]["protocol_version"], 1);

    runtime.trigger_shutdown();
    let _ = tokio::time::timeout(std::time::Duration::from_secs(5), server_handle).await;
}

#[tokio::test]
async fn ws_command_returns_not_implemented() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::session::AuthMode;
    use futures::{SinkExt, StreamExt};
    use tokio_tungstenite::tungstenite;

    let mut config = EngineConfig::default();
    config.client_api_port = 0;
    let runtime = Arc::new(EngineRuntime::new(config));
    let token = runtime.session_store().create_session(AuthMode::Anonymous, None);

    let runtime_clone = runtime.clone();
    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async move {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let _ = port_tx.send(port);
        let app = dspatch_sdk::client_api::server::build_router(runtime_clone.clone());
        let mut shutdown = runtime_clone.subscribe_shutdown();
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { let _ = shutdown.recv().await; })
            .await.unwrap();
    });

    let port = port_rx.await.unwrap();
    let url = format!("ws://127.0.0.1:{port}/ws?token={token}");
    let (mut ws, _) = tokio_tungstenite::connect_async(&url).await.unwrap();

    // Consume welcome.
    let _welcome = ws.next().await.unwrap().unwrap();

    // Send a command.
    let cmd = r#"{"id":"cmd_42","type":"command","method":"launch_workspace","params":{"workspace_id":"w1"}}"#;
    ws.send(tungstenite::Message::Text(cmd.into())).await.unwrap();

    let msg = tokio::time::timeout(std::time::Duration::from_secs(5), ws.next())
        .await.unwrap().unwrap().unwrap();

    let text = msg.into_text().unwrap();
    let frame: serde_json::Value = serde_json::from_str(&text).unwrap();
    assert_eq!(frame["type"], "error");
    assert_eq!(frame["id"], "cmd_42");
    assert_eq!(frame["code"], "NOT_IMPLEMENTED");
    assert!(frame["message"].as_str().unwrap().contains("launch_workspace"));

    runtime.trigger_shutdown();
    let _ = tokio::time::timeout(std::time::Duration::from_secs(5), server_handle).await;
}

#[tokio::test]
async fn ws_invalid_frame_returns_parse_error() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::session::AuthMode;
    use futures::{SinkExt, StreamExt};
    use tokio_tungstenite::tungstenite;

    let mut config = EngineConfig::default();
    config.client_api_port = 0;
    let runtime = Arc::new(EngineRuntime::new(config));
    let token = runtime.session_store().create_session(AuthMode::Anonymous, None);

    let runtime_clone = runtime.clone();
    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async move {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let _ = port_tx.send(port);
        let app = dspatch_sdk::client_api::server::build_router(runtime_clone.clone());
        let mut shutdown = runtime_clone.subscribe_shutdown();
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { let _ = shutdown.recv().await; })
            .await.unwrap();
    });

    let port = port_rx.await.unwrap();
    let url = format!("ws://127.0.0.1:{port}/ws?token={token}");
    let (mut ws, _) = tokio_tungstenite::connect_async(&url).await.unwrap();

    let _welcome = ws.next().await.unwrap().unwrap();

    ws.send(tungstenite::Message::Text("not json".into())).await.unwrap();

    let msg = tokio::time::timeout(std::time::Duration::from_secs(5), ws.next())
        .await.unwrap().unwrap().unwrap();

    let text = msg.into_text().unwrap();
    let frame: serde_json::Value = serde_json::from_str(&text).unwrap();
    assert_eq!(frame["type"], "error");
    assert_eq!(frame["code"], "INVALID_FRAME");
    assert!(frame["id"].is_null());

    runtime.trigger_shutdown();
    let _ = tokio::time::timeout(std::time::Duration::from_secs(5), server_handle).await;
}

#[tokio::test]
async fn ws_connection_stays_alive_during_idle_period() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::session::AuthMode;
    use futures::StreamExt;

    let mut config = EngineConfig::default();
    config.client_api_port = 0;
    let runtime = Arc::new(EngineRuntime::new(config));
    let token = runtime.session_store().create_session(AuthMode::Anonymous, None);

    let runtime_clone = runtime.clone();
    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async move {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let _ = port_tx.send(port);
        let app = dspatch_sdk::client_api::server::build_router(runtime_clone.clone());
        let mut shutdown = runtime_clone.subscribe_shutdown();
        axum::serve(listener, app)
            .with_graceful_shutdown(async move { let _ = shutdown.recv().await; })
            .await.unwrap();
    });

    let port = port_rx.await.unwrap();
    let url = format!("ws://127.0.0.1:{port}/ws?token={token}");
    let (mut ws, _) = tokio_tungstenite::connect_async(&url).await.unwrap();

    let _welcome = ws.next().await.unwrap().unwrap();

    // Wait a bit to verify connection doesn't drop.
    tokio::time::sleep(std::time::Duration::from_secs(2)).await;

    runtime.trigger_shutdown();

    let msg = tokio::time::timeout(std::time::Duration::from_secs(5), ws.next())
        .await
        .expect("should receive shutdown event within timeout");
    assert!(msg.is_some(), "should have received a message");

    let _ = tokio::time::timeout(std::time::Duration::from_secs(5), server_handle).await;
}

#[test]
fn service_registry_provides_all_services() {
    use dspatch_sdk::engine::service_registry::ServiceRegistry;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = dspatch_sdk::engine::startup::open_database(&db_path).unwrap();
    let db = std::sync::Arc::new(db);

    let data_dir = tmp.path().join("data");
    let registry = ServiceRegistry::new(db, data_dir);

    // Verify all service accessors return valid references.
    let _ = registry.workspaces();
    let _ = registry.agent_providers();
    let _ = registry.agent_templates();
    let _ = registry.workspace_templates();
    let _ = registry.api_keys();
    let _ = registry.preferences();
    let _ = registry.inquiries();
    let _ = registry.agent_data();
}

#[tokio::test]
async fn health_reflects_auth_state_after_anonymous_login() {
    use std::sync::Arc;
    use axum::body::Body;
    use http::Request;
    use tower::ServiceExt;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::client_api::health::HealthResponse;
    use dspatch_sdk::client_api::server::build_router;

    let runtime = Arc::new(EngineRuntime::new(EngineConfig::default()));

    // Before auth: authenticated should be false.
    let app = build_router(runtime.clone());
    let req = Request::builder().uri("/health").body(Body::empty()).unwrap();
    let resp = app.oneshot(req).await.unwrap();
    let body = axum::body::to_bytes(resp.into_body(), 4096).await.unwrap();
    let health: HealthResponse = serde_json::from_slice(&body).unwrap();
    assert!(!health.authenticated);

    // Authenticate anonymously.
    let app = build_router(runtime.clone());
    let req = Request::builder()
        .method("POST")
        .uri("/auth/anonymous")
        .body(Body::empty())
        .unwrap();
    let _ = app.oneshot(req).await.unwrap();

    // After auth: authenticated should be true.
    let app = build_router(runtime.clone());
    let req = Request::builder().uri("/health").body(Body::empty()).unwrap();
    let resp = app.oneshot(req).await.unwrap();
    let body = axum::body::to_bytes(resp.into_body(), 4096).await.unwrap();
    let health: HealthResponse = serde_json::from_slice(&body).unwrap();
    assert!(health.authenticated);
}
