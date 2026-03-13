// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local connectivity service — always reports offline.

/// Local-only connectivity service. Always reports the server as unreachable
/// since there is no remote backend in local mode.
pub struct LocalConnectivityService;

impl LocalConnectivityService {
    pub fn new() -> Self {
        Self
    }

    /// Always returns `false` — no remote server in local mode.
    pub fn is_server_reachable(&self) -> bool {
        false
    }
}
