// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::ApiKey;
use crate::util::result::Result;

use super::WatchStream;

/// Manages API key lifecycle: encrypted storage, retrieval, and deletion.
///
/// Keys are stored with AES-256-GCM encryption. The service handles
/// domain model conversion; callers never see database rows.
#[async_trait]
pub trait ApiKeyService: Send + Sync {
    /// Watches all API keys, ordered by creation date (newest first).
    fn watch_api_keys(&self) -> WatchStream<Vec<ApiKey>>;

    /// Returns the API key with the given `name`, or `None` if not found.
    async fn get_api_key_by_name(&self, name: &str) -> Result<Option<ApiKey>>;

    /// Creates a new API key with the given properties.
    ///
    /// The `encrypted_key` should already be encrypted by the caller.
    async fn create_api_key(
        &self,
        name: &str,
        provider_label: &str,
        encrypted_key: Vec<u8>,
        display_hint: Option<&str>,
    ) -> Result<()>;

    /// Deletes the API key with the given `id`.
    async fn delete_api_key(&self, id: &str) -> Result<()>;
}
