use dspatch_router::config::RouterConfig;
use std::sync::Mutex;

// Env vars are process-global. Tests must not run concurrently.
static ENV_LOCK: Mutex<()> = Mutex::new(());

#[test]
fn parse_config_from_env() {
    let _guard = ENV_LOCK.lock().unwrap();

    std::env::remove_var("DSPATCH_WAL_PATH");
    std::env::remove_var("DSPATCH_GRPC_SOCKET");
    std::env::set_var("DSPATCH_API_URL", "ws://host.docker.internal:9847");
    std::env::set_var("DSPATCH_API_KEY", "test-key-123");
    std::env::set_var("DSPATCH_RUN_ID", "run-abc");
    std::env::set_var("DSPATCH_WORKSPACE_ID", "ws-xyz");
    std::env::set_var("DSPATCH_AGENTS_META", r#"{"lead":{"is_root":true,"peers":["coder"],"fields":{}},"coder":{"is_root":false,"peers":["lead"],"fields":{}}}"#);

    let config = RouterConfig::from_env().unwrap();
    assert_eq!(config.api_url, "ws://host.docker.internal:9847");
    assert_eq!(config.api_key, "test-key-123");
    assert_eq!(config.run_id, "run-abc");
    assert_eq!(config.workspace_id, "ws-xyz");
    assert_eq!(config.wal_path, "/data/dspatch.wal");
    assert_eq!(config.grpc_socket, "/tmp/dspatch.sock");
    assert_eq!(config.agents_meta.len(), 2);
    assert!(config.agents_meta["lead"].is_root);
    assert_eq!(config.agents_meta["lead"].peers, vec!["coder"]);
}

#[test]
fn parse_config_custom_paths() {
    let _guard = ENV_LOCK.lock().unwrap();

    std::env::set_var("DSPATCH_API_URL", "ws://localhost:1234");
    std::env::set_var("DSPATCH_API_KEY", "k");
    std::env::set_var("DSPATCH_RUN_ID", "r");
    std::env::set_var("DSPATCH_WORKSPACE_ID", "w");
    std::env::set_var("DSPATCH_AGENTS_META", "{}");
    std::env::set_var("DSPATCH_WAL_PATH", "/custom/wal");
    std::env::set_var("DSPATCH_GRPC_SOCKET", "/custom/sock");

    let config = RouterConfig::from_env().unwrap();
    assert_eq!(config.wal_path, "/custom/wal");
    assert_eq!(config.grpc_socket, "/custom/sock");
}
