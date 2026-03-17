// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Configuration for initializing the d:spatch SDK.
#[derive(Debug, Clone)]
pub struct DspatchConfig {
    /// Preferred embedded server port (0 = random available port).
    pub server_port: u16,

    /// Optional backend API URL.
    pub backend_url: Option<String>,
}

impl DspatchConfig {
    /// Creates a `DspatchConfig` from an `EngineConfig`, mapping shared fields.
    pub fn from_engine_config(engine: &crate::engine::config::EngineConfig) -> Self {
        Self {
            server_port: engine.agent_server_port,
            backend_url: engine.backend_url.clone(),
        }
    }
}

impl Default for DspatchConfig {
    fn default() -> Self {
        Self {
            server_port: 0,
            backend_url: None,
        }
    }
}
