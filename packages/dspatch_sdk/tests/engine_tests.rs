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
