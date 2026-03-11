// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local sync service — no-op in local mode.

use futures::stream;

use crate::domain::services::{SyncState, WatchStream};
use crate::util::result::Result;

/// No-op sync service for local-only mode. Always reports [`SyncState::Idle`].
pub struct LocalSyncService;

impl LocalSyncService {
    pub fn new() -> Self {
        Self
    }

    /// No-op — nothing to initialize in local mode.
    pub async fn initialize(&self) -> Result<()> {
        Ok(())
    }

    /// Emits a single [`SyncState::Idle`] value, then completes.
    pub fn watch_sync_state(&self) -> WatchStream<SyncState> {
        Box::pin(stream::once(async { SyncState::Idle }))
    }
}
