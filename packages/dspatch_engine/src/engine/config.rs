// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Engine configuration with hardcoded defaults.
//!
//! All fields have sensible defaults. No external config sources for now.
//! The default `db_dir` matches Flutter's `getApplicationSupportDirectory()`
//! so the standalone daemon and the Flutter-embedded engine share the same
//! database.

use std::path::PathBuf;

/// Returns the default database directory, matching Flutter's
/// `getApplicationSupportDirectory()` so the standalone daemon and the
/// Flutter-embedded engine share the same database.
///
/// - Windows: `%APPDATA%\com.dspatch\dspatch_app\data`
/// - macOS:   `~/Library/Application Support/com.dspatch.dspatch-app/data`
/// - Linux:   `~/.local/share/com.dspatch/dspatch_app/data`
fn default_db_dir() -> PathBuf {
    let base = dirs::data_dir().unwrap_or_else(|| PathBuf::from("."));

    #[cfg(target_os = "macos")]
    let app_dir = base.join("com.dspatch.dspatch-app");

    #[cfg(not(target_os = "macos"))]
    let app_dir = base.join("com.dspatch").join("dspatch_app");

    app_dir.join("data")
}

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

    /// Whether the engine is running in test mode (--test-db).
    /// Exposes DB path via /engine-info endpoint.
    #[serde(default)]
    pub test_mode: bool,

    /// Optional backend API URL. Defaults to `http://localhost:3000` in debug
    /// builds and `https://backend.dspatch.dev` in release builds.
    #[serde(default)]
    pub backend_url: Option<String>,
}

impl Default for EngineConfig {
    fn default() -> Self {
        Self {
            client_api_port: 9847,
            db_dir: default_db_dir(),
            log_level: "info".into(),
            agent_server_port: 0,
            invalidation_debounce_ms: 50,
            test_mode: false,
            backend_url: if cfg!(debug_assertions) {
                Some("http://127.0.0.1:3000".into())
            } else {
                Some("https://backend.dspatch.dev".into())
            },
        }
    }
}
