// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local API key service — wraps ApiKeyDao directly.

use std::sync::Arc;

use async_trait::async_trait;

use crate::db::dao::ApiKeyDao;
use crate::domain::models::ApiKey;
use crate::domain::services::ApiKeyService;
use crate::util::new_id;
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

    /// Returns all API keys, ordered by `created_at` descending.
    pub fn list_api_keys(&self) -> Result<Vec<ApiKey>> {
        self.dao.get_all_api_keys()
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
        let id = new_id();
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
