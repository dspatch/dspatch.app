// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Engine configuration with hardcoded defaults.
//!
//! All fields have sensible defaults. No external config sources for now.

use std::path::PathBuf;

/// Configuration for the dspatch engine daemon.
#[derive(Debug, Clone, serde::Deserialize)]
#[serde(default)]
pub struct EngineConfig {
    /// Port for the client API server (Flutter app connects here).
    pub client_api_port: u16,

    /// Directory for SQLite database files.
    pub db_dir: PathBuf,

    /// Logging level (trace, debug, info, warn, error).
    pub log_level: String,

    /// Port for the agent-facing server (Docker containers connect here).
    /// 0 = OS-assigned (auto).
    pub agent_server_port: u16,

    /// Debounce period (ms) for batching table invalidation events.
    pub invalidation_debounce_ms: u64,
}

impl Default for EngineConfig {
    fn default() -> Self {
        Self {
            client_api_port: 9847,
            db_dir: dirs::home_dir()
                .unwrap_or_else(|| PathBuf::from("."))
                .join(".dspatch")
                .join("data"),
            log_level: "info".into(),
            agent_server_port: 0,
            invalidation_debounce_ms: 50,
        }
    }
}
