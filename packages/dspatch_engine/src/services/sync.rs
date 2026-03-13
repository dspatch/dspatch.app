// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local sync service — no-op in local mode.

use crate::util::result::Result;

/// No-op sync service for local-only mode. Always reports idle.
pub struct LocalSyncService;

impl LocalSyncService {
    pub fn new() -> Self {
        Self
    }

    /// No-op — nothing to initialize in local mode.
    pub async fn initialize(&self) -> Result<()> {
        Ok(())
    }
}
