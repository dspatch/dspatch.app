// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Result models
// ---------------------------------------------------------------------------

/// Result of template resolution across a workspace config.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct TemplateResolutionResult {
    pub unresolved_templates: Vec<UnresolvedTemplate>,
    pub missing_api_keys: Vec<MissingApiKey>,
    pub missing_required_env: Vec<MissingRequiredEnv>,
    pub empty_required_env: Vec<EmptyRequiredEnv>,
    pub missing_required_mounts: Vec<MissingRequiredMount>,
}

impl TemplateResolutionResult {
    /// True when every template, API key, required env, and mount resolved.
    pub fn is_fully_resolved(&self) -> bool {
        self.unresolved_templates.is_empty()
            && self.missing_api_keys.is_empty()
            && self.missing_required_env.is_empty()
            && self.missing_required_mounts.is_empty()
    }
}

impl Default for TemplateResolutionResult {
    fn default() -> Self {
        Self {
            unresolved_templates: Vec::new(),
            missing_api_keys: Vec::new(),
            missing_required_env: Vec::new(),
            empty_required_env: Vec::new(),
            missing_required_mounts: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UnresolvedTemplate {
    /// Dot-path to the agent in the hierarchy.
    pub agent_path: String,
    /// The template name that could not be found.
    pub template_name: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MissingApiKey {
    /// Dot-path to the agent whose env references this key.
    pub agent_path: String,
    /// The API key name extracted from `{{apikey:Name}}`.
    pub key_name: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MissingRequiredEnv {
    /// Dot-path to the agent missing the env key.
    pub agent_path: String,
    /// The template name that declares this required env key.
    pub template_name: String,
    /// The env key name that is missing.
    pub env_key: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EmptyRequiredEnv {
    /// Dot-path to the agent with the empty env value.
    pub agent_path: String,
    /// The template name that declares this required env key.
    pub template_name: String,
    /// The env key name that has an empty value.
    pub env_key: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MissingRequiredMount {
    /// Dot-path to the agent whose template requires this mount.
    pub agent_path: String,
    /// The template name that declares this required mount.
    pub template_name: String,
    /// The container path that is not covered by workspace mounts.
    pub container_path: String,
}

// ---------------------------------------------------------------------------
// Regex for {{apikey:Name}} placeholders
// ---------------------------------------------------------------------------

/// Regex for `{{apikey:Name}}` placeholders in env values.
pub static API_KEY_PLACEHOLDER: once_cell::sync::Lazy<regex_lite::Regex> =
    once_cell::sync::Lazy::new(|| regex_lite::Regex::new(r"\{\{apikey:([^}]+)\}\}").unwrap());

// ---------------------------------------------------------------------------
// Resolver function
// ---------------------------------------------------------------------------

use std::collections::{HashMap, HashSet};

use super::config::{AgentConfig, WorkspaceConfig};
use super::env_resolver;
use crate::services::{LocalAgentProviderService, LocalApiKeyService};

/// Resolves all templates, API keys, required env, and mounts across
/// a workspace configuration hierarchy.
///
/// Walks the agent tree recursively, looking up each template by name,
/// checking required mounts against workspace-level mounts, validating
/// env variables, and verifying `{{apikey:Name}}` placeholders.
pub async fn resolve_workspace_templates(
    config: &WorkspaceConfig,
    provider_service: &LocalAgentProviderService,
    api_key_service: &LocalApiKeyService,
) -> TemplateResolutionResult {
    let mut result = TemplateResolutionResult::default();

    // Cache: template_name -> required_env keys (populated on first lookup).
    let mut template_required_env: HashMap<String, Vec<String>> = HashMap::new();
    // Cache: template_name -> required_mounts (populated on first lookup).
    let mut template_required_mounts: HashMap<String, Vec<String>> = HashMap::new();

    // Collect the set of container_paths provided by workspace mounts.
    let workspace_mount_paths: HashSet<String> = config
        .mounts
        .iter()
        .map(|m| m.container_path.clone())
        .collect();

    // Walk the agent hierarchy.
    resolve_agents_recursive(
        &config.agents,
        "agents",
        provider_service,
        &workspace_mount_paths,
        &mut template_required_env,
        &mut template_required_mounts,
        &mut result,
    )
    .await;

    // Validate required env across the hierarchy using the cached map.
    let env_result = env_resolver::validate_hierarchy(
        &config.env,
        &config.agents,
        &template_required_env,
        "agents",
    );
    result.missing_required_env = env_result.missing_required_env;
    result.empty_required_env = env_result.empty_required_env;

    // Scan all env values for {{apikey:Name}} placeholders.
    let mut api_key_names: HashSet<String> = HashSet::new();
    collect_apikey_refs_from_env(&config.env, &mut api_key_names);
    collect_apikey_refs_recursive(&config.agents, &mut api_key_names);

    for key_name in &api_key_names {
        match api_key_service.get_api_key_by_name(key_name).await {
            Ok(Some(_)) => { /* key exists */ }
            Ok(None) => {
                // Find which agent(s) reference this key for better error reporting.
                let referencing_agents =
                    find_agents_referencing_key(&config.env, &config.agents, "agents", key_name);
                for agent_path in referencing_agents {
                    result.missing_api_keys.push(MissingApiKey {
                        agent_path,
                        key_name: key_name.clone(),
                    });
                }
            }
            Err(e) => {
                tracing::warn!("Failed to look up API key '{}': {}", key_name, e);
            }
        }
    }

    result
}

/// Recursively resolves agents: looks up templates, checks required mounts.
fn resolve_agents_recursive<'a>(
    agents: &'a HashMap<String, AgentConfig>,
    path_prefix: &'a str,
    provider_service: &'a LocalAgentProviderService,
    workspace_mount_paths: &'a HashSet<String>,
    template_required_env: &'a mut HashMap<String, Vec<String>>,
    template_required_mounts: &'a mut HashMap<String, Vec<String>>,
    result: &'a mut TemplateResolutionResult,
) -> std::pin::Pin<Box<dyn std::future::Future<Output = ()> + Send + 'a>> {
    Box::pin(async move {
        for (key, agent_config) in agents {
            let agent_path = format!("{}.{}", path_prefix, key);

            // Skip if we've already looked up this template name.
            if !template_required_env.contains_key(&agent_config.template) {
                match provider_service
                    .get_agent_provider_by_name(&agent_config.template)
                    .await
                {
                    Ok(Some(template)) => {
                        // Cache required_env.
                        template_required_env.insert(
                            agent_config.template.clone(),
                            template.required_env.clone(),
                        );
                        // Cache required_mounts.
                        template_required_mounts.insert(
                            agent_config.template.clone(),
                            template.required_mounts.clone(),
                        );

                        // Check required_mounts against workspace mounts.
                        for required_mount in &template.required_mounts {
                            if !workspace_mount_paths.contains(required_mount) {
                                result.missing_required_mounts.push(MissingRequiredMount {
                                    agent_path: agent_path.clone(),
                                    template_name: agent_config.template.clone(),
                                    container_path: required_mount.clone(),
                                });
                            }
                        }
                    }
                    Ok(None) => {
                        result.unresolved_templates.push(UnresolvedTemplate {
                            agent_path: agent_path.clone(),
                            template_name: agent_config.template.clone(),
                        });
                        // Insert empty vec so we don't look up again.
                        template_required_env
                            .insert(agent_config.template.clone(), Vec::new());
                        template_required_mounts
                            .insert(agent_config.template.clone(), Vec::new());
                    }
                    Err(e) => {
                        tracing::warn!(
                            "Failed to look up template '{}' for agent '{}': {}",
                            agent_config.template,
                            agent_path,
                            e
                        );
                        // Treat lookup failure as unresolved.
                        result.unresolved_templates.push(UnresolvedTemplate {
                            agent_path: agent_path.clone(),
                            template_name: agent_config.template.clone(),
                        });
                        template_required_env
                            .insert(agent_config.template.clone(), Vec::new());
                        template_required_mounts
                            .insert(agent_config.template.clone(), Vec::new());
                    }
                }
            } else {
                // Template already looked up — use cached mounts for this agent path.
                // (Different agents using the same template still need mount checks reported
                // per agent path.)
                if let Some(cached_mounts) = template_required_mounts.get(&agent_config.template) {
                    for required_mount in cached_mounts {
                        if !workspace_mount_paths.contains(required_mount) {
                            result.missing_required_mounts.push(MissingRequiredMount {
                                agent_path: agent_path.clone(),
                                template_name: agent_config.template.clone(),
                                container_path: required_mount.clone(),
                            });
                        }
                    }
                }
            }

            // Recurse into sub_agents.
            if !agent_config.sub_agents.is_empty() {
                resolve_agents_recursive(
                    &agent_config.sub_agents,
                    &format!("{}.sub_agents", agent_path),
                    provider_service,
                    workspace_mount_paths,
                    template_required_env,
                    template_required_mounts,
                    result,
                )
                .await;
            }
        }
    })
}

/// Collects all `{{apikey:Name}}` references from an env map.
fn collect_apikey_refs_from_env(env: &HashMap<String, String>, names: &mut HashSet<String>) {
    for value in env.values() {
        for cap in API_KEY_PLACEHOLDER.captures_iter(value) {
            if let Some(name) = cap.get(1) {
                names.insert(name.as_str().to_string());
            }
        }
    }
}

/// Recursively collects all `{{apikey:Name}}` references from agent env maps.
fn collect_apikey_refs_recursive(
    agents: &HashMap<String, AgentConfig>,
    names: &mut HashSet<String>,
) {
    for agent in agents.values() {
        collect_apikey_refs_from_env(&agent.env, names);
        if !agent.sub_agents.is_empty() {
            collect_apikey_refs_recursive(&agent.sub_agents, names);
        }
    }
}

/// Finds agent paths that reference a given API key name in their env values.
fn find_agents_referencing_key(
    global_env: &HashMap<String, String>,
    agents: &HashMap<String, AgentConfig>,
    path_prefix: &str,
    key_name: &str,
) -> Vec<String> {
    let mut paths = Vec::new();

    // Check if the key is referenced in global env (attribute to all root agents).
    let in_global = global_env.values().any(|v| {
        API_KEY_PLACEHOLDER
            .captures_iter(v)
            .any(|cap| cap.get(1).map_or(false, |m| m.as_str() == key_name))
    });

    find_agents_referencing_key_recursive(
        agents, path_prefix, key_name, in_global, &mut paths,
    );
    paths
}

fn find_agents_referencing_key_recursive(
    agents: &HashMap<String, AgentConfig>,
    path_prefix: &str,
    key_name: &str,
    in_global: bool,
    paths: &mut Vec<String>,
) {
    for (key, agent) in agents {
        let agent_path = format!("{}.{}", path_prefix, key);

        let in_agent_env = agent.env.values().any(|v| {
            API_KEY_PLACEHOLDER
                .captures_iter(v)
                .any(|cap| cap.get(1).map_or(false, |m| m.as_str() == key_name))
        });

        if in_agent_env || in_global {
            paths.push(agent_path.clone());
        }

        if !agent.sub_agents.is_empty() {
            find_agents_referencing_key_recursive(
                &agent.sub_agents,
                &format!("{}.sub_agents", agent_path),
                key_name,
                in_global,
                paths,
            );
        }
    }
}
