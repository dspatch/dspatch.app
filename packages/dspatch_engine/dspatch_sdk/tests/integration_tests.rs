// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the full SDK lifecycle, CLI smoke tests, and
//! cross-module interactions.
//!
//! These tests exercise the *integration* between modules (services -> DAOs
//! -> database, CLI -> workspace config, crypto -> API key storage) rather
//! than unit-level behavior, which is already covered in the dedicated test
//! files.

use std::collections::HashMap;
use std::sync::Arc;

use dspatch_sdk::config::DspatchConfig;
use dspatch_sdk::crypto::AesGcmCrypto;
use dspatch_sdk::db::dao::{AgentTemplateDao, ApiKeyDao, PreferenceDao, WorkspaceDao};
use dspatch_sdk::db::key_manager::testing::InMemorySecretStore;
use dspatch_sdk::db::Database;
use dspatch_sdk::domain::enums::SourceType;
use dspatch_sdk::domain::models::CreateAgentTemplateRequest;
use dspatch_sdk::sdk::DspatchSdk;
use dspatch_sdk::services::{
    LocalAgentTemplateService, LocalApiKeyService, LocalPreferenceService,
    LocalWorkspaceService,
};

// ── Helpers ──────────────────────────────────────────────────────────────

/// Creates an in-memory database with all migrations applied.
fn test_db() -> Arc<Database> {
    Arc::new(Database::open_in_memory().expect("Failed to open in-memory database"))
}

/// Creates an SDK instance without going through the full auth flow.
fn make_sdk(dir: &std::path::Path) -> DspatchSdk {
    let store = Box::new(InMemorySecretStore::new());
    DspatchSdk::with_secret_store(DspatchConfig::default(), store, dir.to_path_buf())
}

/// Creates a `CreateAgentTemplateRequest` with the given name.
fn template_request(name: &str) -> CreateAgentTemplateRequest {
    CreateAgentTemplateRequest {
        name: name.to_string(),
        source_type: SourceType::Local,
        source_path: Some("/tmp/agent".to_string()),
        git_url: None,
        git_branch: None,
        entry_point: "main.py".to_string(),
        description: Some(format!("{name} description")),
        readme: None,
        required_env: vec!["API_KEY".to_string()],
        required_mounts: vec![],
        fields: HashMap::new(),
        hub_slug: None,
        hub_author: None,
        hub_category: None,
        hub_tags: vec![],
        hub_version: None,
        hub_repo_url: None,
        hub_commit_hash: None,
    }
}

// =========================================================================
// 1. SDK Lifecycle: construction, core services, database guard, dispose
// =========================================================================

#[tokio::test]
async fn sdk_lifecycle_construct_and_dispose() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    // Core services available immediately (no database needed).
    let _ = sdk.auth_service();
    let _ = sdk.crypto();
    let _ = sdk.device_service();
    let _ = sdk.sync_service();
    let _ = sdk.connectivity_service();
    let _ = sdk.docker_service();
    let _ = sdk.hub_client();
    let _ = sdk.docker_client();

    // Database should NOT be ready before initialize.
    assert!(!sdk.is_database_ready().await);

    // DB-dependent services should return errors.
    assert!(sdk.templates().await.is_err());
    assert!(sdk.api_keys().await.is_err());
    assert!(sdk.preferences().await.is_err());
    assert!(sdk.workspaces().await.is_err());
    assert!(sdk.inquiries().await.is_err());
    assert!(sdk.agent_data().await.is_err());

    // Dispose should succeed even without initialize.
    assert!(sdk.dispose().await.is_ok());
}

#[tokio::test]
async fn sdk_initialize_and_dispose() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    sdk.initialize().await.unwrap();

    // Wait briefly for the auth watcher to potentially open the database.
    tokio::time::sleep(std::time::Duration::from_millis(500)).await;

    // Dispose should always succeed.
    sdk.dispose().await.unwrap();
    assert!(!sdk.is_database_ready().await);
}

#[tokio::test]
async fn sdk_database_state_broadcast_on_dispose() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = Arc::new(make_sdk(dir.path()));

    // Subscribe to database state changes.
    let mut rx = sdk.subscribe_database_state();

    sdk.initialize().await.unwrap();

    // Dispose sends a Closed notification.
    sdk.dispose().await.unwrap();

    // We should receive the Closed event (it may be preceded by Ready).
    let state = tokio::time::timeout(std::time::Duration::from_secs(2), rx.recv()).await;
    assert!(state.is_ok(), "Should receive database state notification on dispose");
}

// =========================================================================
// 2. Agent Template: create -> get -> get_by_name -> delete (via service stack)
// =========================================================================

#[tokio::test]
async fn template_service_full_crud() {
    let db = test_db();
    let dao = Arc::new(AgentTemplateDao::new(db));
    let svc = LocalAgentTemplateService::new(dao);

    // Create.
    let template = svc
        .create_agent_template(template_request("integration-template"))
        .await
        .unwrap();
    assert_eq!(template.name, "integration-template");
    assert_eq!(template.source_type, SourceType::Local);
    assert_eq!(template.entry_point, "main.py");
    assert_eq!(template.required_env, vec!["API_KEY"]);

    // Get by ID.
    let fetched = svc.get_agent_template(&template.id).await.unwrap();
    assert_eq!(fetched.id, template.id);
    assert_eq!(fetched.name, "integration-template");

    // Get by name.
    let by_name = svc
        .get_agent_template_by_name("integration-template")
        .await
        .unwrap();
    assert!(by_name.is_some());
    assert_eq!(by_name.unwrap().id, template.id);

    // Delete.
    svc.delete_agent_template(&template.id).await.unwrap();
    let gone = svc
        .get_agent_template_by_name("integration-template")
        .await
        .unwrap();
    assert!(gone.is_none());
}

#[tokio::test]
async fn template_service_multiple_create_and_selective_delete() {
    let db = test_db();
    let dao = Arc::new(AgentTemplateDao::new(db));
    let svc = LocalAgentTemplateService::new(dao);

    // Create three templates.
    let names = ["alpha", "beta", "gamma"];
    let mut ids = Vec::new();
    for name in &names {
        let t = svc.create_agent_template(template_request(name)).await.unwrap();
        ids.push(t.id);
    }

    // All three should be retrievable.
    for (i, id) in ids.iter().enumerate() {
        let t = svc.get_agent_template(id).await.unwrap();
        assert_eq!(t.name, names[i]);
    }

    // Delete the middle one.
    svc.delete_agent_template(&ids[1]).await.unwrap();
    assert!(svc.get_agent_template_by_name("beta").await.unwrap().is_none());

    // Others should still exist.
    assert!(svc.get_agent_template_by_name("alpha").await.unwrap().is_some());
    assert!(svc.get_agent_template_by_name("gamma").await.unwrap().is_some());
}

// =========================================================================
// 3. API Key: create -> get_by_name -> delete (via service stack)
// =========================================================================

#[tokio::test]
async fn api_key_service_create_get_delete() {
    let db = test_db();
    let dao = Arc::new(ApiKeyDao::new(db));
    let svc = LocalApiKeyService::new(dao);

    svc.create_api_key("test-key", "openai", vec![10, 20, 30], Some("sk-...xyz"))
        .await
        .unwrap();

    let key = svc.get_api_key_by_name("test-key").await.unwrap().unwrap();
    assert_eq!(key.name, "test-key");
    assert_eq!(key.provider_label, "openai");
    assert_eq!(key.encrypted_key, vec![10, 20, 30]);
    assert_eq!(key.display_hint, Some("sk-...xyz".to_string()));

    svc.delete_api_key(&key.id).await.unwrap();
    assert!(svc.get_api_key_by_name("test-key").await.unwrap().is_none());
}

// =========================================================================
// 4. Preference: set -> get -> update -> get -> delete -> get
// =========================================================================

#[tokio::test]
async fn preference_service_full_lifecycle() {
    let db = test_db();
    let dao = Arc::new(PreferenceDao::new(db));
    let svc = LocalPreferenceService::new(dao);

    // Initially absent.
    assert_eq!(svc.get_preference("color_scheme").await.unwrap(), None);

    // Set.
    svc.set_preference("color_scheme", "dark").await.unwrap();
    assert_eq!(
        svc.get_preference("color_scheme").await.unwrap(),
        Some("dark".to_string())
    );

    // Overwrite.
    svc.set_preference("color_scheme", "light").await.unwrap();
    assert_eq!(
        svc.get_preference("color_scheme").await.unwrap(),
        Some("light".to_string())
    );

    // Delete.
    svc.delete_preference("color_scheme").await.unwrap();
    assert_eq!(svc.get_preference("color_scheme").await.unwrap(), None);
}

// =========================================================================
// 5. CLI Init / Validate Smoke Tests
// =========================================================================

#[tokio::test]
async fn cli_init_creates_config_file() {
    let dir = tempfile::tempdir().unwrap();
    let dir_str = dir.path().to_string_lossy().to_string();

    dspatch_sdk::cli::commands::init::run(Some(&dir_str))
        .await
        .unwrap();

    let config_path = dir.path().join("dspatch.workspace.yml");
    assert!(config_path.exists(), "dspatch.workspace.yml should exist");

    let content = std::fs::read_to_string(&config_path).unwrap();
    assert!(content.contains("name: my-workspace"));
    assert!(content.contains("agents:"));
}

#[tokio::test]
async fn cli_init_fails_if_file_exists() {
    let dir = tempfile::tempdir().unwrap();
    let dir_str = dir.path().to_string_lossy().to_string();

    std::fs::write(dir.path().join("dspatch.workspace.yml"), "existing").unwrap();

    let result = dspatch_sdk::cli::commands::init::run(Some(&dir_str)).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn cli_validate_on_init_output() {
    let dir = tempfile::tempdir().unwrap();
    let dir_str = dir.path().to_string_lossy().to_string();

    dspatch_sdk::cli::commands::init::run(Some(&dir_str))
        .await
        .unwrap();

    let result = dspatch_sdk::cli::commands::validate::run(Some(&dir_str)).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn cli_validate_fails_on_missing_file() {
    let dir = tempfile::tempdir().unwrap();
    let dir_str = dir.path().to_string_lossy().to_string();

    let result = dspatch_sdk::cli::commands::validate::run(Some(&dir_str)).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn cli_validate_fails_on_invalid_config() {
    let dir = tempfile::tempdir().unwrap();
    let dir_str = dir.path().to_string_lossy().to_string();

    let bad_yaml = "name: \"\"\nagents: {}\n";
    std::fs::write(dir.path().join("dspatch.workspace.yml"), bad_yaml).unwrap();

    let result = dspatch_sdk::cli::commands::validate::run(Some(&dir_str)).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn cli_init_then_validate_end_to_end() {
    let dir = tempfile::tempdir().unwrap();
    let dir_str = dir.path().to_string_lossy().to_string();

    // Init.
    dspatch_sdk::cli::commands::init::run(Some(&dir_str))
        .await
        .unwrap();

    // Validate.
    dspatch_sdk::cli::commands::validate::run(Some(&dir_str))
        .await
        .unwrap();

    // Parse with the workspace config parser directly.
    let config =
        dspatch_sdk::workspace_config::parser::parse_workspace_config_file(dir.path()).unwrap();
    assert_eq!(config.name, "my-workspace");
    assert!(config.agents.contains_key("main"));
    assert_eq!(config.agents["main"].template, "my-agent-template");

    // Second init should fail (file already exists).
    let result = dspatch_sdk::cli::commands::init::run(Some(&dir_str)).await;
    assert!(result.is_err());
}

// =========================================================================
// 6. Workspace Config Round-trip (parse + validate + encode)
// =========================================================================

#[test]
fn workspace_config_parse_validate_encode_roundtrip() {
    use dspatch_sdk::workspace_config::parser::{encode_yaml, parse_workspace_config};
    use dspatch_sdk::workspace_config::validation::validate_config;

    let yaml = r#"
name: integration-test
env:
  SHARED_VAR: shared-value
agents:
  worker:
    template: worker-template
    entry_point: main.py
    env:
      WORKER_VAR: worker-value
    peers:
      - reviewer
  reviewer:
    template: reviewer-template
    entry_point: review.py
mounts:
  - host_path: /data/models
    container_path: /models
    read_only: true
docker:
  memory_limit: 2g
  cpu_limit: 1.5
  network_mode: bridge
"#;

    let config = parse_workspace_config(yaml).unwrap();
    assert_eq!(config.name, "integration-test");
    assert_eq!(config.agents.len(), 2);
    assert_eq!(config.agents["worker"].template, "worker-template");
    assert_eq!(config.agents["reviewer"].template, "reviewer-template");
    assert_eq!(config.agents["worker"].peers, vec!["reviewer"]);
    assert_eq!(config.mounts.len(), 1);
    assert!(config.mounts[0].read_only);

    let errors = validate_config(&config);
    assert!(errors.is_empty(), "Expected no validation errors, got: {errors:?}");

    let encoded = encode_yaml(&config).unwrap();
    let reparsed = parse_workspace_config(&encoded).unwrap();
    assert_eq!(config, reparsed);
}

// =========================================================================
// 7. Wire Protocol Package Round-trip (complex multi-variant)
// =========================================================================

#[test]
fn wire_protocol_multi_variant_round_trip() {
    use dspatch_sdk::domain::enums::{AgentState, LogLevel};
    use dspatch_sdk::server::packages::*;

    // Build a diverse set of packages and round-trip each one.
    let packages: Vec<Package> = vec![
        // Output package
        Package::Message(MessagePackage {
            instance_id: "inst-1".into(),
            turn_id: Some("turn-1".into()),
            ts: Some(1700000000000),
            id: Some("msg-1".into()),
            role: MessageRole::Assistant,
            content: "Hello world".into(),
            model: Some("claude-3".into()),
            input_tokens: Some(100),
            output_tokens: Some(50),
            is_delta: false,
            sender_name: Some("coder".into()),
        }),
        // Event package
        Package::UserInput(UserInputPackage {
            instance_id: "inst-1".into(),
            content: "please help".into(),
        }),
        // Signal with nested instances
        Package::StateReport(StateReportPackage {
            instance_id: "main".into(),
            state: AgentState::WaitingForAgent,
            instances: Some({
                let mut m = HashMap::new();
                m.insert("worker".into(), AgentState::Generating);
                m.insert("reviewer".into(), AgentState::Idle);
                m.insert("tester".into(), AgentState::WaitingForInquiry);
                m
            }),
        }),
        // Connection package
        Package::Register(RegisterPackage {
            name: "my-agent".into(),
            role: Some("worker".into()),
            capabilities: Some(vec!["code".into(), "search".into()]),
        }),
        // Log with warn level
        Package::Log(LogPackage {
            instance_id: "inst-1".into(),
            turn_id: None,
            ts: None,
            level: LogLevel::Warn,
            message: "something went wrong".into(),
        }),
    ];

    for pkg in &packages {
        let json = pkg.to_json().expect("serialize should succeed");
        let restored = Package::from_json(&json).expect("deserialize should succeed");
        assert_eq!(
            pkg.type_str(),
            restored.type_str(),
            "type_str mismatch for {}",
            pkg.type_str()
        );
        assert_eq!(
            pkg.instance_id(),
            restored.instance_id(),
            "instance_id mismatch for {}",
            pkg.type_str()
        );
    }
}

// =========================================================================
// 8. Crypto Round-trip (string encrypt/decrypt)
// =========================================================================

#[tokio::test]
async fn crypto_encrypt_decrypt_roundtrip() {
    let store = Arc::new(InMemorySecretStore::new());
    let crypto = AesGcmCrypto::new(store);

    let plaintext = "secret-api-key-12345";
    let blob = crypto.encrypt_string(plaintext, "test_key_id").await.unwrap();
    let decrypted = crypto.decrypt_string(&blob, "test_key_id").await.unwrap();
    assert_eq!(decrypted, plaintext);

    // Wrong key_id should fail.
    let result = crypto.decrypt_string(&blob, "wrong_key_id").await;
    assert!(result.is_err());
}

// =========================================================================
// 9. Signal Protocol: session establishment + encrypt
// =========================================================================

#[test]
fn signal_session_establish_and_encrypt() {
    use dspatch_sdk::signal::protocol::{PreKeyBundle, SignalManager};

    let db_a = Arc::new(Database::open_in_memory().unwrap());
    let db_b = Arc::new(Database::open_in_memory().unwrap());

    let mut alice = SignalManager::new(
        Arc::clone(&db_a),
        1,
        ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng),
    );
    let mut bob = SignalManager::new(
        Arc::clone(&db_b),
        2,
        ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng),
    );

    alice.initialize().unwrap();
    bob.initialize().unwrap();

    // Build Bob's prekey bundle.
    let bob_spk = bob
        .signed_prekey_store
        .get_signed_prekey(1)
        .unwrap()
        .unwrap();
    let bob_pk = bob.prekey_store.get_prekey(1).unwrap().unwrap();

    let bundle = PreKeyBundle {
        registration_id: 2,
        device_id: 1,
        identity_key: bob.identity_store.get_identity_public_key_bytes(),
        signed_prekey_id: 1,
        signed_prekey_public: bob_spk.record[32..64].to_vec(),
        signed_prekey_signature: bob_spk.record[64..128].to_vec(),
        prekey_id: Some(1),
        prekey_public: Some(bob_pk.record[32..64].to_vec()),
    };

    alice.process_prekey_bundle("bob", 1, &bundle).unwrap();
    assert!(alice.session_store.contains_session("bob", 1).unwrap());

    let plaintext = b"Hello Bob, this is an integration test!";
    let ciphertext = alice.encrypt("bob", 1, plaintext).unwrap();
    assert!(!ciphertext.is_empty());
    assert_ne!(&ciphertext[..], &plaintext[..]);
}

// =========================================================================
// 10. Sync Engine: outbox -> apply cross-engine round-trip
// =========================================================================

#[test]
fn sync_engine_cross_engine_outbox_apply() {
    use dspatch_sdk::sync::message::SyncOp;
    use dspatch_sdk::sync::peer_connection::PeerConnectionManager;
    use dspatch_sdk::sync::sync_engine::SyncEngine;

    let db_a = Arc::new(Database::open_in_memory().unwrap());
    let db_b = Arc::new(Database::open_in_memory().unwrap());

    let signing_key_a = ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng);
    let signing_key_b = ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng);

    let signal_a = Arc::new(tokio::sync::Mutex::new(
        dspatch_sdk::signal::SignalManager::new(Arc::clone(&db_a), 1, signing_key_a),
    ));
    let signal_b = Arc::new(tokio::sync::Mutex::new(
        dspatch_sdk::signal::SignalManager::new(Arc::clone(&db_b), 2, signing_key_b),
    ));

    let peer_a = Arc::new(PeerConnectionManager::new(signal_a));
    let peer_b = Arc::new(PeerConnectionManager::new(signal_b));

    let engine_a = SyncEngine::new(db_a, peer_a, "device-a");
    let engine_b = SyncEngine::new(db_b, peer_b, "device-b");

    // Record a change on engine A.
    let change = engine_a
        .record_change(
            "workspaces",
            "ws-integration-1",
            SyncOp::Insert,
            serde_json::json!({"name": "Integration WS"}),
        )
        .unwrap();
    assert_eq!(change.device_id, "device-a");
    assert_eq!(change.lamport_ts, 1);

    // Get outbox from A and apply on B.
    let outbox = engine_a.get_all_outbox().unwrap();
    assert_eq!(outbox.len(), 1);

    let applied = engine_b.apply_remote_changes(outbox).unwrap();
    assert_eq!(applied, 1);

    // B should have the data.
    let b_outbox = engine_b.get_all_outbox().unwrap();
    assert_eq!(b_outbox.len(), 1);
    assert_eq!(b_outbox[0].row_id, "ws-integration-1");
    assert_eq!(b_outbox[0].data["name"], "Integration WS");
    assert!(engine_b.current_lamport() >= 1);
}

// =========================================================================
// 11. Crypto -> API Key Service integration (encrypt, store, retrieve, decrypt)
// =========================================================================

#[tokio::test]
async fn crypto_api_key_encrypt_store_retrieve_decrypt() {
    let db = test_db();
    let store = Arc::new(InMemorySecretStore::new());
    let crypto = AesGcmCrypto::new(store);
    let dao = Arc::new(ApiKeyDao::new(db));
    let svc = LocalApiKeyService::new(dao);

    // Encrypt a raw API key.
    let raw_key = "sk-live-test-key-abc123";
    let encrypted = crypto
        .encrypt(raw_key.as_bytes(), "api_key_encryption")
        .await
        .unwrap();

    // Store via the API key service.
    svc.create_api_key("my-openai-key", "openai", encrypted.clone(), Some("sk-...123"))
        .await
        .unwrap();

    // Retrieve and decrypt.
    let stored = svc
        .get_api_key_by_name("my-openai-key")
        .await
        .unwrap()
        .unwrap();

    let decrypted = crypto
        .decrypt(&stored.encrypted_key, "api_key_encryption")
        .await
        .unwrap();

    assert_eq!(
        String::from_utf8(decrypted).unwrap(),
        raw_key,
        "Decrypted key should match the original plaintext"
    );
    assert_eq!(stored.display_hint, Some("sk-...123".to_string()));

    // Clean up.
    svc.delete_api_key(&stored.id).await.unwrap();
    assert!(svc.get_api_key_by_name("my-openai-key").await.unwrap().is_none());
}

// =========================================================================
// 12. Workspace service: create workspace -> retrieve -> verify disk files
// =========================================================================

#[tokio::test]
async fn workspace_create_and_verify() {
    use dspatch_sdk::domain::models::CreateWorkspaceRequest;

    let db = test_db();
    let dao = Arc::new(WorkspaceDao::new(db));
    let svc = LocalWorkspaceService::new(dao);

    let project_dir = tempfile::tempdir().unwrap();
    let project_path = project_dir.path().to_string_lossy().to_string();

    let config_yaml = r#"
name: integration-workspace
agents:
  main:
    template: test-template
    entry_point: main.py
"#;

    let workspace = svc
        .create_workspace(CreateWorkspaceRequest {
            project_path: project_path.clone(),
            config_yaml: config_yaml.to_string(),
        })
        .await
        .unwrap();

    assert_eq!(workspace.name, "integration-workspace");
    assert_eq!(workspace.project_path, project_path);

    // Retrieve by ID.
    let fetched = svc.get_workspace(&workspace.id).await.unwrap();
    assert_eq!(fetched.id, workspace.id);
    assert_eq!(fetched.name, "integration-workspace");

    // Verify disk artifacts.
    let config_on_disk = project_dir.path().join("dspatch.workspace.yml");
    assert!(config_on_disk.exists(), "Config file should be written to disk");

    let templates_dir = project_dir.path().join(".dspatch").join("templates");
    assert!(templates_dir.exists(), "Templates directory should be created");
}

// =========================================================================
// 13. Server guard: start_server fails without database
// =========================================================================

#[tokio::test]
async fn server_start_fails_without_database() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    // Server requires database to be ready.
    let result = sdk.start_server(Some(0)).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn server_stop_is_noop_when_not_started() {
    let dir = tempfile::tempdir().unwrap();
    let sdk = make_sdk(dir.path());

    assert!(sdk.stop_server().await.is_ok());
}

// =========================================================================
// 14. File browser creation
// =========================================================================

#[test]
fn file_browser_creation() {
    let sdk = DspatchSdk::new(DspatchConfig::default());
    let _browser = sdk.create_file_browser("/tmp/project");
    // Should not panic.
}

// =========================================================================
// 15. End-to-end: template + workspace config flatten
// =========================================================================

#[test]
fn workspace_config_flatten_agent_hierarchy() {
    use dspatch_sdk::workspace_config::flat_agent::flatten_agent_hierarchy;
    use dspatch_sdk::workspace_config::parser::parse_workspace_config;

    let yaml = r#"
name: hierarchical
agents:
  orchestrator:
    template: orchestrator-template
    peers:
      - coder
    sub_agents:
      planner:
        template: planner-template
      analyst:
        template: analyst-template
  coder:
    template: coder-template
"#;

    let config = parse_workspace_config(yaml).unwrap();
    let flat = flatten_agent_hierarchy(&config);

    // Should produce 4 flat agents: orchestrator, coder, planner, analyst.
    assert_eq!(flat.len(), 4);

    let orchestrator = flat.iter().find(|a| a.agent_key == "orchestrator").unwrap();
    assert!(orchestrator.parent_key.is_none());
    assert!(orchestrator.auto_start);

    let planner = flat.iter().find(|a| a.agent_key == "planner").unwrap();
    assert_eq!(planner.parent_key.as_deref(), Some("orchestrator"));
    assert!(!planner.auto_start);

    let analyst = flat.iter().find(|a| a.agent_key == "analyst").unwrap();
    assert_eq!(analyst.parent_key.as_deref(), Some("orchestrator"));
    assert!(!analyst.auto_start);

    let coder = flat.iter().find(|a| a.agent_key == "coder").unwrap();
    assert!(coder.parent_key.is_none());
    assert!(coder.auto_start);
}
