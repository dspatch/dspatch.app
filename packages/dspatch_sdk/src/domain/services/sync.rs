// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;
use serde::{Deserialize, Serialize};

use crate::util::result::Result;

use super::WatchStream;

/// Current state of the data synchronization process.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SyncState {
    Idle,
    Syncing,
    Error,
}

/// Data synchronization between local database and remote server.
///
/// In local mode, this is a no-op that always emits [`SyncState::Idle`].
/// In SaaS mode, this would handle bidirectional sync of sessions,
/// providers, and settings.
#[async_trait]
pub trait SyncService: Send + Sync {
    /// Performs initial sync setup (e.g. conflict resolution strategy).
    async fn initialize(&self) -> Result<()>;

    /// Watches the current sync state.
    fn watch_sync_state(&self) -> WatchStream<SyncState>;
}
