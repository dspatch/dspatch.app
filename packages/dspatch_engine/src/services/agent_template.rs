// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local agent template service — manages lightweight config presets.

use std::path::PathBuf;
use std::sync::Arc;

use async_trait::async_trait;

use crate::db::dao::AgentTemplateDao;
use crate::domain::models::AgentTemplate;
use crate::domain::services::AgentTemplateService;
use crate::util::error::AppError;
use crate::util::new_id;
use crate::util::result::Result;

/// Local agent template service backed by [`AgentTemplateDao`].
///
/// Templates are stored as `dspatch.agent.yml` files in `<data_dir>/templates/<uuid>/`.
pub struct LocalAgentTemplateService {
    dao: Arc<AgentTemplateDao>,
    /// Base directory for template files (e.g. `<appdata>/dspatch/templates/`).
    templates_dir: PathBuf,
}

impl LocalAgentTemplateService {
    pub fn new(dao: Arc<AgentTemplateDao>, data_dir: PathBuf) -> Self {
        let templates_dir = data_dir.join("templates");
        Self { dao, templates_dir }
    }

    /// Returns all agent templates, ordered by `updated_at` descending.
    pub fn list_agent_templates(&self) -> Result<Vec<AgentTemplate>> {
        self.dao.get_all_agent_templates()
    }

    /// Returns the agent template with the given `id`.
    pub async fn get_agent_template(&self, id: &str) -> Result<AgentTemplate> {
        self.dao.get_agent_template(id)
    }

    /// Returns the agent template with the given `name`, or `None`.
    pub async fn get_agent_template_by_name(
        &self,
        name: &str,
    ) -> Result<Option<AgentTemplate>> {
        self.dao.get_agent_template_by_name(name)
    }

    /// Creates a new template from a provider.
    ///
    /// 1. Creates `<templates_dir>/<uuid>/dspatch.agent.yml` with `source: <source_uri>`
    /// 2. Inserts a DB record pointing to that file
    pub async fn create_agent_template(
        &self,
        name: &str,
        source_uri: &str,
    ) -> Result<AgentTemplate> {
        // Validate source_uri format — hub agents or local providers.
        if !source_uri.starts_with("dspatch://agent/") && !source_uri.starts_with("local://") {
            return Err(AppError::Validation(
                "source_uri must start with dspatch://agent/<author>/<slug> or local://<id>".into(),
            ));
        }

        // Check for duplicate name
        if self.dao.get_agent_template_by_name(name)?.is_some() {
            return Err(AppError::Validation(format!(
                "A template named '{name}' already exists"
            )));
        }

        let id = new_id();
        let template_dir = self.templates_dir.join(&id);
        std::fs::create_dir_all(&template_dir).map_err(|e| {
            AppError::Storage(format!("Failed to create template directory: {e}"))
        })?;

        let file_path = template_dir.join("dspatch.agent.yml");
        let yaml_content = format!(
            "# Agent template configuration\n\
             # Edit this file to customize the template.\n\
             source: {source_uri}\n\
             name: {name}\n"
        );
        std::fs::write(&file_path, &yaml_content).map_err(|e| {
            AppError::Storage(format!("Failed to write template config: {e}"))
        })?;

        let now = chrono::Utc::now().naive_utc();
        let template = AgentTemplate {
            id,
            name: name.to_string(),
            source_uri: source_uri.to_string(),
            file_path: file_path.to_string_lossy().to_string(),
            created_at: now,
            updated_at: now,
        };
        self.dao.insert_agent_template(&template)?;
        Ok(template)
    }

    /// Updates the name and source URI of an existing template.
    pub async fn update_agent_template(&self, id: &str, name: &str, source_uri: &str) -> Result<()> {
        self.dao.update_agent_template(id, name, source_uri)
    }

    /// Deletes the template, its config file, and the containing directory.
    pub async fn delete_agent_template(&self, id: &str) -> Result<()> {
        // Get the template to find the file path
        let template = self.dao.get_agent_template(id)?;

        // Delete the directory containing the config file
        let file_path = std::path::Path::new(&template.file_path);
        if let Some(parent) = file_path.parent() {
            if parent.exists() {
                std::fs::remove_dir_all(parent).map_err(|e| {
                    AppError::Storage(format!("Failed to delete template directory: {e}"))
                })?;
            }
        }

        self.dao.delete_agent_template(id)
    }
}

#[async_trait]
impl AgentTemplateService for LocalAgentTemplateService {
    async fn get_agent_template(&self, id: &str) -> Result<AgentTemplate> {
        self.get_agent_template(id).await
    }

    async fn get_agent_template_by_name(&self, name: &str) -> Result<Option<AgentTemplate>> {
        self.get_agent_template_by_name(name).await
    }

    async fn create_agent_template(
        &self,
        name: &str,
        source_uri: &str,
    ) -> Result<AgentTemplate> {
        self.create_agent_template(name, source_uri).await
    }

    async fn delete_agent_template(&self, id: &str) -> Result<()> {
        self.delete_agent_template(id).await
    }

    async fn update_agent_template(&self, id: &str, name: &str, source_uri: &str) -> Result<()> {
        self.update_agent_template(id, name, source_uri).await
    }
}
