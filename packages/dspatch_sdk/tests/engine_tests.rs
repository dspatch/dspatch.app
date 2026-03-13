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
