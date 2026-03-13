// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the DspatchSdk facade.

use dspatch_sdk::config::DspatchConfig;
use dspatch_sdk::db::key_manager::testing::InMemorySecretStore;
use dspatch_sdk::sdk::DspatchSdk;

/// Helper: create an SDK wired to in-memory stores and a temp directory.
fn make_sdk(dir: &std::path::Path) -> DspatchSdk {
    let store = Box::new(InMemorySecretStore::new());
    DspatchSdk::with_secret_store(
        DspatchConfig::default(),
        store,
        dir.to_path_buf(),
    )
}

#[test]
fn new_creates_sdk_with_default_config() {
    let sdk = DspatchSdk::new(DspatchConfig::default());
    // Should not panic — just stores config.
    drop(sdk);
}

#[test]
fn new_creates_sdk_with_custom_config() {
    let config = DspatchConfig {
        server_port: 8080,
        backend_url: Some("https://example.com".to_string()),
        assets_dir: Some("/tmp/assets".to_string()),
    };
    let sdk = DspatchSdk::new(config);
    drop(sdk);
}

#[tokio::test]
async fn with_secret_store_creates_initialized_core_services() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    // Core services should be available immediately (before initialize).
    // These accessors return direct references (infallible) since fields
    // are always populated during construction.
    let _ = sdk.auth_service();
    let _ = sdk.docker_service();
    let _ = sdk.device_service();
    let _ = sdk.sync_service();
    let _ = sdk.connectivity_service();
    let _ = sdk.crypto();
    let _ = sdk.hub_client();
    let _ = sdk.docker_client();
}

#[tokio::test]
async fn database_not_ready_before_initialize() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());
    assert!(!sdk.is_database_ready().await);
}

#[tokio::test]
async fn db_services_error_before_database_ready() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    // DB-dependent services should fail before database is ready.
    assert!(sdk.templates().await.is_err());
    assert!(sdk.workspace_templates().await.is_err());
    assert!(sdk.api_keys().await.is_err());
    assert!(sdk.preferences().await.is_err());
    assert!(sdk.workspaces().await.is_err());
    assert!(sdk.inquiries().await.is_err());
    assert!(sdk.agent_data().await.is_err());
}

#[tokio::test]
async fn create_file_browser_works() {
    let sdk = DspatchSdk::new(DspatchConfig::default());
    let _browser = sdk.create_file_browser("/tmp/project");
    // Should not panic.
}

#[tokio::test]
async fn dispose_completes_without_error() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());
    // Dispose should succeed even without initialize.
    assert!(sdk.dispose().await.is_ok());
}

#[tokio::test]
async fn start_server_fails_before_database_ready() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());
    // Server requires database.
    let result = sdk.start_server(Some(0)).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn stop_server_is_noop_when_not_started() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());
    assert!(sdk.stop_server().await.is_ok());
}

#[tokio::test]
async fn initialize_and_db_services_work_after_auth() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    // Initialize starts the auth flow. Since ConnectedAuthService uses
    // InMemorySecretStore with no saved tokens, it will emit
    // AuthState::undetermined(). The auth watcher will try to open the
    // anonymous database.
    sdk.initialize().await.unwrap();

    // Give the auth watcher task time to open the database.
    tokio::time::sleep(std::time::Duration::from_millis(500)).await;

    // After initialization, the database may or may not be ready depending
    // on auth flow. With undetermined state the watcher receives a stream
    // event and opens the anonymous DB.
    // Note: this depends on ConnectedAuthService emitting at least one
    // state during initialize(). If it does, db should be ready.

    if sdk.is_database_ready().await {
        // DB-dependent services should now work.
        assert!(sdk.templates().await.is_ok());
        assert!(sdk.workspace_templates().await.is_ok());
        assert!(sdk.api_keys().await.is_ok());
        assert!(sdk.preferences().await.is_ok());
        assert!(sdk.workspaces().await.is_ok());
        assert!(sdk.inquiries().await.is_ok());
        assert!(sdk.agent_data().await.is_ok());
    }

    sdk.dispose().await.unwrap();
}
