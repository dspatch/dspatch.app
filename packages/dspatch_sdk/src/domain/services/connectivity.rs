// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Monitors connectivity to the d:spatch backend server.
///
/// In local mode, this always reports offline / unreachable since there
/// is no remote server.
pub trait ConnectivityService: Send + Sync {
    /// Whether the backend server is currently reachable.
    fn is_server_reachable(&self) -> bool;
}
