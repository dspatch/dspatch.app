// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for local service implementations.

use std::sync::Arc;

use dspatch_sdk::db::dao::{ApiKeyDao, PreferenceDao};
use dspatch_sdk::db::Database;
use dspatch_sdk::services::{
    LocalApiKeyService, LocalAuthService, LocalConnectivityService, LocalDeviceService,
    LocalDockerService, LocalPreferenceService, LocalSyncService,
};

/// Helper: creates an in-memory database with all migrations applied.
fn test_db() -> Arc<Database> {
    let db = Database::open_in_memory().expect("Failed to create test database");
    Arc::new(db)
}

// ─── LocalPreferenceService ───────────────────────────────────────────────

#[tokio::test]
async fn preference_set_get_delete() {
    let db = test_db();
    let dao = Arc::new(PreferenceDao::new(db));
    let svc = LocalPreferenceService::new(dao);

    // Initially empty.
    let val = svc.get_preference("theme").await.unwrap();
    assert_eq!(val, None);

    // Set a preference.
    svc.set_preference("theme", "dark").await.unwrap();
    let val = svc.get_preference("theme").await.unwrap();
    assert_eq!(val, Some("dark".to_string()));

    // Update it.
    svc.set_preference("theme", "light").await.unwrap();
    let val = svc.get_preference("theme").await.unwrap();
    assert_eq!(val, Some("light".to_string()));

    // Delete it.
    svc.delete_preference("theme").await.unwrap();
    let val = svc.get_preference("theme").await.unwrap();
    assert_eq!(val, None);
}

// ─── LocalApiKeyService ──────────────────────────────────────────────────

#[tokio::test]
async fn api_key_create_and_delete() {
    let db = test_db();
    let dao = Arc::new(ApiKeyDao::new(db));
    let svc = LocalApiKeyService::new(dao);

    // Create a key.
    svc.create_api_key("my-key", "openai", vec![1, 2, 3], Some("sk-...abc"))
        .await
        .unwrap();

    // Find by name.
    let key = svc.get_api_key_by_name("my-key").await.unwrap();
    assert!(key.is_some());
    let key = key.unwrap();
    assert_eq!(key.name, "my-key");
    assert_eq!(key.provider_label, "openai");
    assert_eq!(key.encrypted_key, vec![1, 2, 3]);
    assert_eq!(key.display_hint, Some("sk-...abc".to_string()));

    // Delete it.
    svc.delete_api_key(&key.id).await.unwrap();
    let key = svc.get_api_key_by_name("my-key").await.unwrap();
    assert!(key.is_none());
}

// ─── LocalAuthService ────────────────────────────────────────────────────

#[tokio::test]
async fn auth_initializes_as_anonymous() {
    let svc = LocalAuthService::new();

    // Initialize enters anonymous mode.
    svc.initialize().await.unwrap();
    let state = svc.current_auth_state().await;
    assert_eq!(state.mode, dspatch_sdk::domain::enums::AuthMode::Anonymous);
    assert!(svc.is_authenticated());
    assert!(!svc.is_connected_mode());
    assert_eq!(svc.token_scope(), None);
}

#[tokio::test]
async fn auth_login_returns_error() {
    let svc = LocalAuthService::new();
    svc.initialize().await.unwrap();

    // Login should fail in local mode.
    let result = svc.login("user", "pass").await;
    assert!(result.is_err());
}

// ─── LocalConnectivityService ────────────────────────────────────────────

#[test]
fn connectivity_always_unreachable() {
    let svc = LocalConnectivityService::new();
    assert!(!svc.is_server_reachable());
}

// ─── LocalSyncService ───────────────────────────────────────────────────

#[tokio::test]
async fn sync_initialize_succeeds() {
    let svc = LocalSyncService::new();
    svc.initialize().await.unwrap();
}

// ─── LocalDeviceService ──────────────────────────────────────────────────

#[test]
fn device_returns_local_device() {
    let svc = LocalDeviceService::new();
    let device = svc.current_device();
    assert_eq!(device.id, "local");
    assert!(device.is_online);
    assert!(!svc.is_multi_device_enabled());
}

// ─── LocalWorkspaceService ───────────────────────────────────────────────

#[tokio::test]
async fn workspace_create_and_get() {
    use dspatch_sdk::db::dao::WorkspaceDao;
    use dspatch_sdk::domain::models::CreateWorkspaceRequest;
    use dspatch_sdk::services::LocalWorkspaceService;

    let db = test_db();
    let dao = Arc::new(WorkspaceDao::new(db));
    let svc = LocalWorkspaceService::new(dao);

    // Create a temp directory for the workspace project path.
    let temp_dir = tempfile::tempdir().unwrap();
    let project_path = temp_dir.path().to_string_lossy().to_string();

    let config_yaml = r#"
name: test-workspace
agents:
  coder:
    template: my-template
    entry_point: main.py
"#;

    let workspace = svc
        .create_workspace(CreateWorkspaceRequest {
            project_path: project_path.clone(),
            config_yaml: config_yaml.to_string(),
        })
        .await
        .unwrap();

    assert_eq!(workspace.name, "test-workspace");
    assert_eq!(workspace.project_path, project_path);

    // Get the workspace by id.
    let fetched = svc.get_workspace(&workspace.id).await.unwrap();
    assert_eq!(fetched.id, workspace.id);
    assert_eq!(fetched.name, "test-workspace");

    // Verify the config file was written.
    let config_path = temp_dir.path().join("dspatch.workspace.yml");
    assert!(config_path.exists());

    // Verify the templates dir was created.
    let templates_dir = temp_dir.path().join(".dspatch").join("templates");
    assert!(templates_dir.exists());
}

// ─── LocalDockerService ──────────────────────────────────────────────────

#[test]
fn docker_service_construction() {
    use dspatch_sdk::docker::{DockerCli, DockerClient};
    let cli = DockerCli::new();
    let client = DockerClient::new(cli);
    let _svc = LocalDockerService::new(client, "/tmp/assets".to_string());
    // Just verify construction works without panicking.
}
