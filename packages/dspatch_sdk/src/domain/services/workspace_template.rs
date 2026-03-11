// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::WorkspaceTemplate;
use crate::util::result::Result;

use super::WatchStream;

/// CRUD operations for workspace templates downloaded from the hub.
///
/// A workspace template is a reusable blueprint that bundles a workspace
/// configuration with the agent template references needed to instantiate it.
#[async_trait]
pub trait WorkspaceTemplateService: Send + Sync {
    /// Watches all workspace templates, ordered by most recently updated.
    fn watch_workspace_templates(&self) -> WatchStream<Vec<WorkspaceTemplate>>;

    /// Returns the workspace template with the given hub `slug`, or `None`.
    async fn get_by_hub_slug(&self, slug: &str) -> Result<Option<WorkspaceTemplate>>;

    /// Creates a new workspace template and returns it with a generated UUID
    /// and timestamps.
    async fn create_workspace_template(
        &self,
        name: String,
        description: Option<String>,
        hub_slug: String,
        hub_author: String,
        hub_category: Option<String>,
        hub_tags: Vec<String>,
        hub_version: i32,
        config_yaml: String,
        agent_refs: Vec<String>,
    ) -> Result<WorkspaceTemplate>;

    /// Updates hub-related fields on an existing workspace template.
    async fn update_workspace_template(
        &self,
        id: &str,
        name: Option<String>,
        description: Option<String>,
        hub_version: Option<i32>,
        config_yaml: Option<String>,
        agent_refs: Option<Vec<String>>,
    ) -> Result<()>;

    /// Deletes the workspace template with `id`.
    async fn delete_workspace_template(&self, id: &str) -> Result<()>;
}
