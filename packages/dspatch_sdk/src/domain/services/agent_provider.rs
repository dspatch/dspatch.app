// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::enums::SourceType;
use crate::domain::models::{AgentProvider, CreateAgentProviderRequest, UpdateAgentProviderRequest};
use crate::util::result::Result;

use super::WatchStream;

/// CRUD operations for reusable agent provider definitions.
///
/// An agent provider defines how to build and run an agent: source code
/// location, entry point, and required environment variable key names.
#[async_trait]
pub trait AgentProviderService: Send + Sync {
    /// Watches all agent providers, ordered by most recently updated.
    fn watch_agent_providers(&self) -> WatchStream<Vec<AgentProvider>>;

    /// Watches a single agent provider by `id`.
    /// Emits `None` when the provider doesn't exist.
    fn watch_agent_provider(&self, id: &str) -> WatchStream<Option<AgentProvider>>;

    /// Returns all agent providers, ordered by most recently updated.
    async fn list_agent_providers(&self) -> Result<Vec<AgentProvider>>;

    /// Returns the agent provider with the given `id`.
    async fn get_agent_provider(&self, id: &str) -> Result<AgentProvider>;

    /// Returns the agent provider with the given `name`, or `None` if not found.
    async fn get_agent_provider_by_name(&self, name: &str) -> Result<Option<AgentProvider>>;

    /// Creates a new agent provider from `request`. Returns the created
    /// provider with a generated UUID and timestamps.
    async fn create_agent_provider(
        &self,
        request: CreateAgentProviderRequest,
    ) -> Result<AgentProvider>;

    /// Partially updates the agent provider with `id`. Only non-`None` fields
    /// in `request` are applied. Returns the updated provider.
    async fn update_agent_provider(
        &self,
        id: &str,
        request: UpdateAgentProviderRequest,
    ) -> Result<AgentProvider>;

    /// Deletes the agent provider with `id`.
    async fn delete_agent_provider(&self, id: &str) -> Result<()>;

    /// Validates that `path` is a valid source for the given `source_type`.
    /// For [`SourceType::Local`]: checks that the directory exists.
    /// For [`SourceType::Git`]: runs `git ls-remote` to verify the URL.
    async fn validate_source(&self, path: &str, source_type: SourceType) -> Result<bool>;
}
