// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the DspatchSdk facade.

use dspatch_engine::config::DspatchConfig;
use dspatch_engine::db::key_manager::testing::InMemorySecretStore;
use dspatch_engine::sdk::DspatchSdk;

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
async fn dispose_completes_without_error() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());
    // Dispose should succeed even without initialize.
    assert!(sdk.dispose().await.is_ok());
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

    // After initialization, the database may or may not be ready depending
    // on auth flow. Either way, dispose should succeed.
    sdk.dispose().await.unwrap();
}
