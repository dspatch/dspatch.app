// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local API key service — wraps ApiKeyDao directly.

use std::sync::Arc;

use async_trait::async_trait;
use futures::StreamExt;

use crate::db::dao::ApiKeyDao;
use crate::domain::models::ApiKey;
use crate::domain::services::{ApiKeyService, WatchStream};
use crate::util::result::Result;

/// Local API key service backed by [`ApiKeyDao`].
///
/// Manages API key lifecycle: encrypted storage, retrieval, and deletion.
/// Keys are stored with AES-256-GCM encryption at the DAO level.
pub struct LocalApiKeyService {
    dao: Arc<ApiKeyDao>,
}

impl LocalApiKeyService {
    pub fn new(dao: Arc<ApiKeyDao>) -> Self {
        Self { dao }
    }

    /// Watches all API keys, ordered by creation date (newest first).
    pub fn watch_api_keys(&self) -> WatchStream<Vec<ApiKey>> {
        let stream = self.dao.watch_api_keys();
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_api_keys error: {e}");
                    None
                }
            }
        }))
    }

    /// Returns the API key with the given `name`, or `None` if not found.
    pub async fn get_api_key_by_name(&self, name: &str) -> Result<Option<ApiKey>> {
        self.dao.get_api_key_by_name(name)
    }

    /// Creates a new API key with the given properties.
    ///
    /// The `encrypted_key` should already be encrypted by the caller.
    pub async fn create_api_key(
        &self,
        name: &str,
        provider_label: &str,
        encrypted_key: Vec<u8>,
        display_hint: Option<&str>,
    ) -> Result<()> {
        let id = uuid::Uuid::new_v4().to_string();
        self.dao
            .insert_api_key(&id, name, provider_label, &encrypted_key, display_hint)
    }

    /// Deletes the API key with the given `id`.
    pub async fn delete_api_key(&self, id: &str) -> Result<()> {
        self.dao.delete_api_key(id)
    }
}

#[async_trait]
impl ApiKeyService for LocalApiKeyService {
    fn watch_api_keys(&self) -> WatchStream<Vec<ApiKey>> {
        self.watch_api_keys()
    }

    async fn get_api_key_by_name(&self, name: &str) -> Result<Option<ApiKey>> {
        self.get_api_key_by_name(name).await
    }

    async fn create_api_key(
        &self,
        name: &str,
        provider_label: &str,
        encrypted_key: Vec<u8>,
        display_hint: Option<&str>,
    ) -> Result<()> {
        self.create_api_key(name, provider_label, encrypted_key, display_hint)
            .await
    }

    async fn delete_api_key(&self, id: &str) -> Result<()> {
        self.delete_api_key(id).await
    }
}
