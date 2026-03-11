// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::AgentTemplate;
use crate::util::result::Result;

use super::WatchStream;

/// CRUD operations for lightweight agent template presets.
///
/// Templates reference a provider via `source_uri` and store overrides
/// in a `dspatch.agent.yml` file at `file_path`.
#[async_trait]
pub trait AgentTemplateService: Send + Sync {
    /// Watches all agent templates, ordered by most recently updated.
    fn watch_agent_templates(&self) -> WatchStream<Vec<AgentTemplate>>;

    /// Watches a single agent template by `id`.
    fn watch_agent_template(&self, id: &str) -> WatchStream<Option<AgentTemplate>>;

    /// Returns the agent template with the given `id`.
    async fn get_agent_template(&self, id: &str) -> Result<AgentTemplate>;

    /// Returns the agent template with the given `name`, or `None`.
    async fn get_agent_template_by_name(&self, name: &str) -> Result<Option<AgentTemplate>>;

    /// Creates a new template from a provider. Generates a `dspatch.agent.yml`
    /// in the appdata templates directory.
    async fn create_agent_template(
        &self,
        name: &str,
        source_uri: &str,
    ) -> Result<AgentTemplate>;

    /// Deletes the template and its config file.
    async fn delete_agent_template(&self, id: &str) -> Result<()>;

    /// Updates the name and source URI of an existing template.
    async fn update_agent_template(&self, id: &str, name: &str, source_uri: &str) -> Result<()>;
}
