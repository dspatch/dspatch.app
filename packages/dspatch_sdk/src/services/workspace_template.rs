// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local workspace template service — wraps WorkspaceTemplateDao.

use std::sync::Arc;

use async_trait::async_trait;
use futures::StreamExt;

use crate::db::dao::WorkspaceTemplateDao;
use crate::domain::models::WorkspaceTemplate;
use crate::domain::services::{WatchStream, WorkspaceTemplateService};
use crate::util::result::Result;

/// Local workspace template service backed by [`WorkspaceTemplateDao`].
///
/// CRUD operations for workspace templates downloaded from the hub.
pub struct LocalWorkspaceTemplateService {
    dao: Arc<WorkspaceTemplateDao>,
}

impl LocalWorkspaceTemplateService {
    pub fn new(dao: Arc<WorkspaceTemplateDao>) -> Self {
        Self { dao }
    }

    /// Watches all workspace templates, ordered by most recently updated.
    pub fn watch_workspace_templates(&self) -> WatchStream<Vec<WorkspaceTemplate>> {
        let stream = self.dao.watch_workspace_templates();
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspace_templates error: {e}");
                    None
                }
            }
        }))
    }

    /// Returns the workspace template with the given hub `slug`, or `None`.
    pub async fn get_by_hub_slug(&self, slug: &str) -> Result<Option<WorkspaceTemplate>> {
        self.dao.get_by_hub_slug(slug)
    }

    /// Creates a new workspace template.
    pub async fn create_workspace_template(
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
    ) -> Result<WorkspaceTemplate> {
        let now = chrono::Utc::now().naive_utc();
        let template = WorkspaceTemplate {
            id: uuid::Uuid::new_v4().to_string(),
            name,
            description,
            hub_slug,
            hub_author,
            hub_category,
            hub_tags,
            hub_version: hub_version as i64,
            config_yaml,
            agent_refs,
            created_at: now,
            updated_at: now,
        };
        self.dao.insert_workspace_template(&template)?;
        Ok(template)
    }

    /// Updates hub-related fields on an existing workspace template.
    pub async fn update_workspace_template(
        &self,
        id: &str,
        name: Option<String>,
        description: Option<String>,
        hub_version: Option<i32>,
        config_yaml: Option<String>,
        agent_refs: Option<Vec<String>>,
    ) -> Result<()> {
        self.dao.update_workspace_template(
            id,
            name.as_deref(),
            description.as_deref(),
            None, // hub_category
            None, // hub_tags
            hub_version.map(|v| v as i64),
            config_yaml.as_deref(),
            agent_refs.as_deref(),
        )
    }

    /// Deletes the workspace template with `id`.
    pub async fn delete_workspace_template(&self, id: &str) -> Result<()> {
        self.dao.delete_workspace_template(id)
    }
}

#[async_trait]
impl WorkspaceTemplateService for LocalWorkspaceTemplateService {
    fn watch_workspace_templates(&self) -> WatchStream<Vec<WorkspaceTemplate>> {
        self.watch_workspace_templates()
    }

    async fn get_by_hub_slug(&self, slug: &str) -> Result<Option<WorkspaceTemplate>> {
        self.get_by_hub_slug(slug).await
    }

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
    ) -> Result<WorkspaceTemplate> {
        self.create_workspace_template(
            name,
            description,
            hub_slug,
            hub_author,
            hub_category,
            hub_tags,
            hub_version,
            config_yaml,
            agent_refs,
        )
        .await
    }

    async fn update_workspace_template(
        &self,
        id: &str,
        name: Option<String>,
        description: Option<String>,
        hub_version: Option<i32>,
        config_yaml: Option<String>,
        agent_refs: Option<Vec<String>>,
    ) -> Result<()> {
        self.update_workspace_template(id, name, description, hub_version, config_yaml, agent_refs)
            .await
    }

    async fn delete_workspace_template(&self, id: &str) -> Result<()> {
        self.delete_workspace_template(id).await
    }
}
