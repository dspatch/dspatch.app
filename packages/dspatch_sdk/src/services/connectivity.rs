// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local connectivity service — always reports offline.

use futures::stream;

use crate::domain::services::WatchStream;

/// Local-only connectivity service. Always reports the server as unreachable
/// since there is no remote backend in local mode.
pub struct LocalConnectivityService;

impl LocalConnectivityService {
    pub fn new() -> Self {
        Self
    }

    /// Emits a single `false` value, then completes.
    pub fn watch_state(&self) -> WatchStream<bool> {
        Box::pin(stream::once(async { false }))
    }

    /// Always returns `false` — no remote server in local mode.
    pub fn is_server_reachable(&self) -> bool {
        false
    }
}
