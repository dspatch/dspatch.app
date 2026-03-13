// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Checks local hub-sourced templates against the remote community hub.
//!
//! Ported from `data/hub/hub_version_checker.dart`.

use std::sync::Arc;

use crate::domain::enums::SourceType;
use crate::domain::services::{AgentProviderService, WorkspaceTemplateService};

use super::client::HubApiClient;

/// Checks local hub-sourced templates against the remote community hub and
/// applies updates when requested.
pub struct HubVersionChecker {
    hub_client: Arc<HubApiClient>,
    provider_service: Arc<dyn AgentProviderService>,
    workspace_template_service: Arc<dyn WorkspaceTemplateService>,
}

impl HubVersionChecker {
    pub fn new(
        hub_client: Arc<HubApiClient>,
        provider_service: Arc<dyn AgentProviderService>,
        workspace_template_service: Arc<dyn WorkspaceTemplateService>,
    ) -> Self {
        Self {
            hub_client,
            provider_service,
            workspace_template_service,
        }
    }

    /// Checks all local hub-sourced agent providers against the remote hub.
    ///
    /// Returns a list of hub slugs that have a newer version available.
    pub async fn check_for_agent_updates(&self) -> Vec<String> {
        // 1. Get current list of agent providers.
        let providers = match self.provider_service.list_agent_providers().await {
            Ok(p) => p,
            Err(e) => {
                tracing::error!(tag = "hub", "Failed to list agent providers: {e}");
                return Vec::new();
            }
        };

        // 2. Filter for hub-sourced providers with a slug.
        let hub_providers: Vec<_> = providers
            .iter()
            .filter(|t| t.source_type == SourceType::Hub && t.hub_slug.is_some())
            .collect();

        if hub_providers.is_empty() {
            return Vec::new();
        }

        // 3. Collect slugs and batch-check versions.
        let slugs: Vec<String> = hub_providers
            .iter()
            .map(|t| t.hub_slug.clone().unwrap())
            .collect();

        match self.hub_client.agent_versions(&slugs).await {
            Ok(version_infos) => {
                // 4. Build a map of slug -> latestVersion.
                let remote_versions: std::collections::HashMap<_, _> = version_infos
                    .iter()
                    .map(|info| (info.slug.as_str(), info.latest_version))
                    .collect();

                // 5. Compare and collect slugs where local < remote.
                let mut outdated = Vec::new();
                for provider in &hub_providers {
                    let slug = provider.hub_slug.as_ref().unwrap();
                    if let Some(&remote) = remote_versions.get(slug.as_str()) {
                        let local_version = provider.hub_version.unwrap_or(0);
                        if local_version < remote {
                            outdated.push(slug.clone());
                        }
                    }
                }

                tracing::info!(
                    tag = "hub",
                    "{}/{} agent providers outdated",
                    outdated.len(),
                    hub_providers.len()
                );
                outdated
            }
            Err(e) => {
                tracing::error!(tag = "hub", "Failed to check agent versions: {e}");
                Vec::new()
            }
        }
    }

    /// Checks all local hub workspace templates against the remote hub.
    ///
    /// Returns a list of hub slugs that have a newer version available.
    pub async fn check_for_workspace_updates(&self) -> Vec<String> {
        let templates = match self.workspace_template_service.list_workspace_templates().await {
            Ok(t) => t,
            Err(e) => {
                tracing::error!(tag = "hub", "Failed to list workspace templates: {e}");
                return Vec::new();
            }
        };

        if templates.is_empty() {
            return Vec::new();
        }

        let slugs: Vec<String> = templates.iter().map(|t| t.hub_slug.clone()).collect();

        match self.hub_client.workspace_versions(&slugs).await {
            Ok(version_infos) => {
                let remote_versions: std::collections::HashMap<_, _> = version_infos
                    .iter()
                    .map(|info| (info.slug.as_str(), info.latest_version))
                    .collect();

                let mut outdated = Vec::new();
                for template in &templates {
                    if let Some(&remote) = remote_versions.get(template.hub_slug.as_str()) {
                        if template.hub_version < remote {
                            outdated.push(template.hub_slug.clone());
                        }
                    }
                }

                tracing::info!(
                    tag = "hub",
                    "{}/{} workspace templates outdated",
                    outdated.len(),
                    templates.len()
                );
                outdated
            }
            Err(e) => {
                tracing::error!(tag = "hub", "Failed to check workspace versions: {e}");
                Vec::new()
            }
        }
    }
}
