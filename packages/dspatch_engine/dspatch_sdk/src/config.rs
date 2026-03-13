// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Configuration for initializing the d:spatch SDK.
#[derive(Debug, Clone)]
pub struct DspatchConfig {
    /// Preferred embedded server port (0 = random available port).
    pub server_port: u16,

    /// Optional backend API URL.
    pub backend_url: Option<String>,

    /// Directory containing docker/runtime/ assets (Dockerfile, entrypoint.sh).
    /// Optional override — defaults to "assets" in Flutter apps.
    pub assets_dir: Option<String>,
}

impl Default for DspatchConfig {
    fn default() -> Self {
        Self {
            server_port: 0,
            backend_url: None,
            assets_dir: None,
        }
    }
}
