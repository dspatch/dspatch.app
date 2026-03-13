// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local agent provider service — wraps AgentProviderDao with source validation.

use std::path::Path;
use std::sync::Arc;

use async_trait::async_trait;

use crate::db::dao::AgentProviderDao;
use crate::domain::enums::SourceType;
use crate::domain::models::{AgentProvider, CreateAgentProviderRequest, UpdateAgentProviderRequest};
use crate::domain::services::AgentProviderService;
use crate::util::error::AppError;
use crate::util::new_id;
use crate::util::result::Result;

/// Local agent provider service backed by [`AgentProviderDao`].
///
/// Handles CRUD operations and source validation for agent providers.
pub struct LocalAgentProviderService {
    dao: Arc<AgentProviderDao>,
}

impl LocalAgentProviderService {
    pub fn new(dao: Arc<AgentProviderDao>) -> Self {
        Self { dao }
    }

    /// Returns all agent providers, ordered by most recently updated.
    pub async fn list_agent_providers(&self) -> Result<Vec<AgentProvider>> {
        self.dao.get_all_agent_providers()
    }

    /// Returns the agent provider with the given `id`.
    pub async fn get_agent_provider(&self, id: &str) -> Result<AgentProvider> {
        self.dao.get_agent_provider(id)
    }

    /// Returns the agent provider with the given `name`, or `None`.
    pub async fn get_agent_provider_by_name(
        &self,
        name: &str,
    ) -> Result<Option<AgentProvider>> {
        self.dao.get_agent_provider_by_name(name)
    }

    /// Creates a new agent provider from the request.
    pub async fn create_agent_provider(
        &self,
        request: CreateAgentProviderRequest,
    ) -> Result<AgentProvider> {
        let now = chrono::Utc::now().naive_utc();
        let provider = AgentProvider {
            id: new_id(),
            name: request.name,
            source_type: request.source_type,
            source_path: request.source_path,
            git_url: request.git_url,
            git_branch: request.git_branch,
            entry_point: request.entry_point,
            description: request.description,
            readme: request.readme,
            required_env: request.required_env,
            required_mounts: request.required_mounts,
            fields: request.fields,
            hub_slug: request.hub_slug,
            hub_author: request.hub_author,
            hub_category: request.hub_category,
            hub_tags: request.hub_tags,
            hub_version: request.hub_version,
            hub_repo_url: request.hub_repo_url,
            hub_commit_hash: request.hub_commit_hash,
            created_at: now,
            updated_at: now,
        };
        self.dao.insert_agent_provider(&provider)?;
        Ok(provider)
    }

    /// Partially updates the agent provider with `id`.
    pub async fn update_agent_provider(
        &self,
        id: &str,
        request: UpdateAgentProviderRequest,
    ) -> Result<AgentProvider> {
        self.dao.update_agent_provider(id, &request)?;
        self.dao.get_agent_provider(id)
    }

    /// Deletes the agent provider with `id`.
    pub async fn delete_agent_provider(&self, id: &str) -> Result<()> {
        self.dao.delete_agent_provider(id)
    }

    /// Validates that `path` is a valid source for the given `source_type`.
    ///
    /// For [`SourceType::Local`]: checks that the directory exists.
    /// For [`SourceType::Git`]: runs `git ls-remote` to verify the URL.
    pub async fn validate_source(
        &self,
        path: &str,
        source_type: SourceType,
    ) -> Result<bool> {
        match source_type {
            SourceType::Local => Ok(Path::new(path).exists()),
            SourceType::Git => {
                let mut cmd = tokio::process::Command::new("git");
                cmd.args(["ls-remote", path]);
                #[cfg(windows)]
                cmd.creation_flags(0x0800_0000); // CREATE_NO_WINDOW
                let output = cmd.output().await
                    .map_err(|e| {
                        AppError::Validation(format!("Failed to run git ls-remote: {e}"))
                    })?;
                Ok(output.status.success())
            }
            SourceType::Hub => {
                // Hub sources are validated by the hub service, not locally.
                Ok(true)
            }
        }
    }
}

#[async_trait]
impl AgentProviderService for LocalAgentProviderService {
    async fn list_agent_providers(&self) -> Result<Vec<AgentProvider>> {
        self.list_agent_providers().await
    }

    async fn get_agent_provider(&self, id: &str) -> Result<AgentProvider> {
        self.get_agent_provider(id).await
    }

    async fn get_agent_provider_by_name(&self, name: &str) -> Result<Option<AgentProvider>> {
        self.get_agent_provider_by_name(name).await
    }

    async fn create_agent_provider(
        &self,
        request: CreateAgentProviderRequest,
    ) -> Result<AgentProvider> {
        self.create_agent_provider(request).await
    }

    async fn update_agent_provider(
        &self,
        id: &str,
        request: UpdateAgentProviderRequest,
    ) -> Result<AgentProvider> {
        self.update_agent_provider(id, request).await
    }

    async fn delete_agent_provider(&self, id: &str) -> Result<()> {
        self.delete_agent_provider(id).await
    }

    async fn validate_source(&self, path: &str, source_type: SourceType) -> Result<bool> {
        self.validate_source(path, source_type).await
    }
}
