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

    // Send a command. The runtime has no services (created via `new()`), so
    // we expect NOT_READY. Params must include `method` for Command deserialization.
    let cmd = r#"{"id":"cmd_42","type":"command","method":"launch_workspace","params":{"method":"launch_workspace","id":"w1"}}"#;
    ws.send(tungstenite::Message::Text(cmd.into())).await.unwrap();

    let msg = tokio::time::timeout(std::time::Duration::from_secs(5), ws.next())
        .await.unwrap().unwrap().unwrap();

    let text = msg.into_text().unwrap();
    let frame: serde_json::Value = serde_json::from_str(&text).unwrap();
    assert_eq!(frame["type"], "error");
    assert_eq!(frame["id"], "cmd_42");
    assert_eq!(frame["code"], "NOT_READY");
    assert!(frame["message"].as_str().unwrap().contains("not yet initialized"));

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

#[test]
fn error_mapping_covers_all_app_error_variants() {
    use dspatch_sdk::client_api::error_mapping::error_to_code;
    use dspatch_sdk::util::error::AppError;

    assert_eq!(error_to_code(&AppError::Validation("x".into())), "VALIDATION_ERROR");
    assert_eq!(error_to_code(&AppError::NotFound("x".into())), "NOT_FOUND");
    assert_eq!(error_to_code(&AppError::Storage("x".into())), "STORAGE_ERROR");
    assert_eq!(error_to_code(&AppError::Docker("x".into())), "DOCKER_ERROR");
    assert_eq!(error_to_code(&AppError::Server("x".into())), "SERVER_ERROR");
    assert_eq!(error_to_code(&AppError::Crypto("x".into())), "CRYPTO_ERROR");
    assert_eq!(error_to_code(&AppError::SecureStorageFailure("x".into())), "SECURE_STORAGE_FAILURE");
    assert_eq!(error_to_code(&AppError::Platform("x".into())), "PLATFORM_ERROR");
    assert_eq!(error_to_code(&AppError::Auth("x".into())), "AUTH_ERROR");
    assert_eq!(
        error_to_code(&AppError::Api {
            message: "x".into(),
            status_code: Some(500),
            body: None,
        }),
        "API_ERROR"
    );
    assert_eq!(error_to_code(&AppError::Internal("x".into())), "INTERNAL_ERROR");
}

#[tokio::test]
async fn dispatch_get_workspace_not_found() {
    use std::sync::Arc;
    use dspatch_sdk::client_api::commands::Command;
    use dspatch_sdk::client_api::dispatch::dispatch_command;
    use dspatch_sdk::engine::service_registry::ServiceRegistry;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = Arc::new(dspatch_sdk::engine::startup::open_database(&db_path).unwrap());
    let registry = Arc::new(ServiceRegistry::new(db, tmp.path().to_path_buf()));

    let cmd = Command::GetWorkspace { id: "nonexistent".into() };
    let result = dispatch_command(&cmd, &registry).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    assert!(matches!(err, dspatch_sdk::util::error::AppError::NotFound(_)));
}

#[tokio::test]
async fn dispatch_delete_workspace() {
    use std::sync::Arc;
    use dspatch_sdk::client_api::commands::Command;
    use dspatch_sdk::client_api::dispatch::dispatch_command;
    use dspatch_sdk::engine::service_registry::ServiceRegistry;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = Arc::new(dspatch_sdk::engine::startup::open_database(&db_path).unwrap());
    let registry = Arc::new(ServiceRegistry::new(db, tmp.path().to_path_buf()));

    // Delete non-existent workspace — just verify it doesn't panic.
    let cmd = Command::DeleteWorkspace { id: "nonexistent".into() };
    let result = dispatch_command(&cmd, &registry).await;
    let _ = result;
}

#[tokio::test]
async fn dispatch_preference_round_trip() {
    use std::sync::Arc;
    use dspatch_sdk::client_api::commands::Command;
    use dspatch_sdk::client_api::dispatch::dispatch_command;
    use dspatch_sdk::engine::service_registry::ServiceRegistry;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = Arc::new(dspatch_sdk::engine::startup::open_database(&db_path).unwrap());
    let registry = Arc::new(ServiceRegistry::new(db, tmp.path().to_path_buf()));

    // Set a preference.
    let cmd = Command::SetPreference {
        key: "theme".into(),
        value: "dark".into(),
    };
    let result = dispatch_command(&cmd, &registry).await;
    assert!(result.is_ok());

    // Get it back.
    let cmd = Command::GetPreference { key: "theme".into() };
    let result = dispatch_command(&cmd, &registry).await;
    assert!(result.is_ok());
    let data = result.unwrap();
    assert_eq!(data.as_str().unwrap(), "dark");
}

#[tokio::test]
async fn dispatch_agent_provider_round_trip() {
    use std::sync::Arc;
    use dspatch_sdk::client_api::commands::Command;
    use dspatch_sdk::client_api::dispatch::dispatch_command;
    use dspatch_sdk::engine::service_registry::ServiceRegistry;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = Arc::new(dspatch_sdk::engine::startup::open_database(&db_path).unwrap());
    let registry = Arc::new(ServiceRegistry::new(db, tmp.path().to_path_buf()));

    // Create an agent provider via JSON Value
    let cmd = Command::CreateAgentProvider {
        request: serde_json::json!({
            "name": "test-provider",
            "sourceType": "local",
            "entryPoint": "main.py",
            "requiredEnv": []
        }),
    };
    let result = dispatch_command(&cmd, &registry).await;
    assert!(result.is_ok(), "create should succeed: {:?}", result.err());

    let data = result.unwrap();
    let provider_id = data["id"].as_str().unwrap().to_string();

    // Get it back.
    let cmd = Command::GetAgentProvider { id: provider_id.clone() };
    let result = dispatch_command(&cmd, &registry).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap()["name"], "test-provider");

    // Delete it.
    let cmd = Command::DeleteAgentProvider { id: provider_id };
    let result = dispatch_command(&cmd, &registry).await;
    assert!(result.is_ok());
}

#[test]
fn command_deserialize_get_workspace() {
    use dspatch_sdk::client_api::commands::Command;

    let json = r#"{"method": "get_workspace", "id": "ws_123"}"#;
    let cmd: Command = serde_json::from_str(json).unwrap();
    match cmd {
        Command::GetWorkspace { id } => assert_eq!(id, "ws_123"),
        _ => panic!("expected GetWorkspace"),
    }
}

#[test]
fn command_deserialize_create_workspace() {
    use dspatch_sdk::client_api::commands::Command;

    let json = r#"{"method": "create_workspace", "name": "test", "project_path": "/home/user/project"}"#;
    let cmd: Command = serde_json::from_str(json).unwrap();
    match cmd {
        Command::CreateWorkspace { name, project_path, .. } => {
            assert_eq!(name, "test");
            assert_eq!(project_path, "/home/user/project");
        }
        _ => panic!("expected CreateWorkspace"),
    }
}

#[test]
fn command_deserialize_unknown_method_fails() {
    use dspatch_sdk::client_api::commands::Command;

    let json = r#"{"method": "nonexistent_command"}"#;
    let result: Result<Command, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn command_deserialize_launch_workspace() {
    use dspatch_sdk::client_api::commands::Command;

    let json = r#"{"method": "launch_workspace", "id": "ws_abc"}"#;
    let cmd: Command = serde_json::from_str(json).unwrap();
    match cmd {
        Command::LaunchWorkspace { id } => assert_eq!(id, "ws_abc"),
        _ => panic!("expected LaunchWorkspace"),
    }
}

#[test]
fn command_deserialize_delete_workspace() {
    use dspatch_sdk::client_api::commands::Command;

    let json = r#"{"method": "delete_workspace", "id": "ws_del"}"#;
    let cmd: Command = serde_json::from_str(json).unwrap();
    match cmd {
        Command::DeleteWorkspace { id } => assert_eq!(id, "ws_del"),
        _ => panic!("expected DeleteWorkspace"),
    }
}

#[test]
fn command_deserialize_stop_workspace() {
    use dspatch_sdk::client_api::commands::Command;

    let json = r#"{"method": "stop_workspace", "id": "ws_stop"}"#;
    let cmd: Command = serde_json::from_str(json).unwrap();
    match cmd {
        Command::StopWorkspace { id } => assert_eq!(id, "ws_stop"),
        _ => panic!("expected StopWorkspace"),
    }
}

#[test]
fn error_to_server_frame_preserves_message_and_id() {
    use dspatch_sdk::client_api::error_mapping::error_to_frame;
    use dspatch_sdk::client_api::protocol::ServerFrame;
    use dspatch_sdk::util::error::AppError;

    let frame = error_to_frame("cmd_42", &AppError::NotFound("workspace xyz".into()));
    match frame {
        ServerFrame::Error { id, code, message } => {
            assert_eq!(id, Some("cmd_42".into()));
            assert_eq!(code, "NOT_FOUND");
            assert!(message.contains("workspace xyz"));
        }
        _ => panic!("expected ServerFrame::Error"),
    }
}

#[tokio::test]
async fn ws_command_dispatches_to_service() {
    use std::sync::Arc;
    use dspatch_sdk::engine::config::EngineConfig;
    use dspatch_sdk::engine::startup::EngineRuntime;
    use dspatch_sdk::engine::service_registry::ServiceRegistry;
    use dspatch_sdk::client_api::session::AuthMode;
    use futures::{SinkExt, StreamExt};

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = Arc::new(dspatch_sdk::engine::startup::open_database(&db_path).unwrap());
    let registry = Arc::new(ServiceRegistry::new(db, tmp.path().to_path_buf()));

    let mut config = EngineConfig::default();
    config.client_api_port = 0;
    let runtime = Arc::new(EngineRuntime::with_services(config, registry));

    let token = runtime.session_store().create_session(AuthMode::Anonymous, None);

    let runtime_clone = runtime.clone();
    let (port_tx, port_rx) = tokio::sync::oneshot::channel();
    let _server_handle = tokio::spawn(async move {
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
    let (mut ws, _) = tokio_tungstenite::connect_async(&url).await.unwrap();

    // Read welcome event.
    let _welcome = ws.next().await.unwrap().unwrap();

    // Send a set_preference command (simple, doesn't need complex setup).
    let cmd = serde_json::json!({
        "id": "cmd_1",
        "type": "command",
        "method": "set_preference",
        "params": {
            "method": "set_preference",
            "key": "test_key",
            "value": "test_value"
        }
    });
    ws.send(tokio_tungstenite::tungstenite::Message::Text(cmd.to_string().into()))
        .await
        .unwrap();

    // Read the response.
    let msg = tokio::time::timeout(
        std::time::Duration::from_secs(5),
        ws.next(),
    )
    .await
    .unwrap()
    .unwrap()
    .unwrap();

    let text = msg.into_text().unwrap();
    let frame: serde_json::Value = serde_json::from_str(&text).unwrap();
    assert_eq!(frame["type"], "result");
    assert_eq!(frame["id"], "cmd_1");

    runtime.trigger_shutdown();
}

#[tokio::test]
async fn dispatch_unimplemented_command_returns_error() {
    use std::sync::Arc;
    use dspatch_sdk::client_api::commands::Command;
    use dspatch_sdk::client_api::dispatch::dispatch_command;
    use dspatch_sdk::engine::service_registry::ServiceRegistry;

    let tmp = tempfile::tempdir().unwrap();
    let db_path = tmp.path().join("test.db");
    let db = Arc::new(dspatch_sdk::engine::startup::open_database(&db_path).unwrap());
    let registry = Arc::new(ServiceRegistry::new(db, tmp.path().to_path_buf()));

    // Docker command is not yet wired.
    let cmd = Command::DetectDockerStatus;
    let result = dispatch_command(&cmd, &registry).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), dspatch_sdk::util::error::AppError::Internal(_)));
}

#[tokio::test]
async fn invalidation_broadcaster_batches_table_changes() {
    use std::sync::Arc;
    use dspatch_sdk::db::reactive::TableChangeTracker;
    use dspatch_sdk::client_api::invalidation::InvalidationBroadcaster;

    let tracker = Arc::new(TableChangeTracker::new());
    tracker.subscribe(&["agent_messages"]);
    tracker.subscribe(&["workspace_runs"]);
    tracker.subscribe(&["preferences"]);

    let broadcaster = InvalidationBroadcaster::new(tracker.clone(), 50);
    let handle = broadcaster.start();
    let mut rx = handle.subscribe();

    tracker.notify("agent_messages");
    tracker.notify("workspace_runs");

    let batch = tokio::time::timeout(
        std::time::Duration::from_millis(200),
        rx.recv(),
    )
    .await
    .expect("should receive within timeout")
    .expect("channel should not be closed");

    assert!(batch.contains(&"agent_messages".to_string()));
    assert!(batch.contains(&"workspace_runs".to_string()));
    assert!(!batch.contains(&"preferences".to_string()));

    handle.shutdown();
}

#[tokio::test]
async fn invalidation_broadcaster_deduplicates_within_window() {
    use std::sync::Arc;
    use dspatch_sdk::db::reactive::TableChangeTracker;
    use dspatch_sdk::client_api::invalidation::InvalidationBroadcaster;

    let tracker = Arc::new(TableChangeTracker::new());
    tracker.subscribe(&["agent_messages"]);

    let broadcaster = InvalidationBroadcaster::new(tracker.clone(), 50);
    let handle = broadcaster.start();
    let mut rx = handle.subscribe();

    for _ in 0..5 {
        tracker.notify("agent_messages");
    }

    let batch = tokio::time::timeout(
        std::time::Duration::from_millis(200),
        rx.recv(),
    )
    .await
    .expect("should receive within timeout")
    .expect("channel should not be closed");

    assert_eq!(batch.len(), 1);
    assert_eq!(batch[0], "agent_messages");

    handle.shutdown();
}

#[tokio::test]
async fn invalidation_broadcaster_sends_separate_batches_across_windows() {
    use std::sync::Arc;
    use dspatch_sdk::db::reactive::TableChangeTracker;
    use dspatch_sdk::client_api::invalidation::InvalidationBroadcaster;

    let tracker = Arc::new(TableChangeTracker::new());
    tracker.subscribe(&["agent_messages"]);
    tracker.subscribe(&["preferences"]);

    let broadcaster = InvalidationBroadcaster::new(tracker.clone(), 30);
    let handle = broadcaster.start();
    let mut rx = handle.subscribe();

    tracker.notify("agent_messages");
    let batch1 = tokio::time::timeout(
        std::time::Duration::from_millis(200),
        rx.recv(),
    )
    .await
    .expect("batch1 timeout")
    .expect("batch1 channel");
    assert!(batch1.contains(&"agent_messages".to_string()));

    tokio::time::sleep(std::time::Duration::from_millis(50)).await;

    tracker.notify("preferences");
    let batch2 = tokio::time::timeout(
        std::time::Duration::from_millis(200),
        rx.recv(),
    )
    .await
    .expect("batch2 timeout")
    .expect("batch2 channel");
    assert!(batch2.contains(&"preferences".to_string()));
    assert!(!batch2.contains(&"agent_messages".to_string()));

    handle.shutdown();
}
