// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::path::Path;

use anyhow::{Context, Result};

use super::config::{AgentConfig, WorkspaceConfig};

/// Parses a [`WorkspaceConfig`] from a YAML string.
///
/// Preserves the YAML declaration order of agent keys via `agent_order`
/// and `sub_agent_order` fields.
pub fn parse_workspace_config(yaml: &str) -> Result<WorkspaceConfig> {
    // First pass: extract key ordering from the raw YAML mapping.
    let value: serde_yml::Value =
        serde_yml::from_str(yaml).context("Invalid workspace config YAML")?;
    // Second pass: deserialize into the typed struct.
    let mut config: WorkspaceConfig =
        serde_yml::from_value(value.clone()).context("Invalid workspace config schema")?;

    // Populate ordering fields from the YAML mapping key order.
    if let Some(agents_mapping) = value.get("agents").and_then(|v| v.as_mapping()) {
        config.agent_order = agents_mapping
            .keys()
            .filter_map(|k| k.as_str().map(|s| s.to_string()))
            .collect();
    }
    populate_sub_agent_order(&value, &mut config.agents);

    Ok(config)
}

/// Recursively populates `sub_agent_order` on each `AgentConfig` from the
/// YAML value tree.
fn populate_sub_agent_order(
    parent_value: &serde_yml::Value,
    agents: &mut std::collections::HashMap<String, AgentConfig>,
) {
    let agents_map = match parent_value.get("agents").and_then(|v| v.as_mapping()) {
        Some(m) => m,
        None => return,
    };
    for (key_val, agent_val) in agents_map {
        let key = match key_val.as_str() {
            Some(s) => s,
            None => continue,
        };
        if let Some(agent_config) = agents.get_mut(key) {
            if let Some(sub_mapping) = agent_val.get("sub_agents").and_then(|v| v.as_mapping()) {
                agent_config.sub_agent_order = sub_mapping
                    .keys()
                    .filter_map(|k| k.as_str().map(|s| s.to_string()))
                    .collect();
            }
            // Recurse into sub-agents (they have their own sub_agents).
            populate_sub_agent_order_recursive(agent_val, &mut agent_config.sub_agents);
        }
    }
}

/// Recursive helper that walks nested sub_agents in the YAML tree.
fn populate_sub_agent_order_recursive(
    agent_value: &serde_yml::Value,
    sub_agents: &mut std::collections::HashMap<String, AgentConfig>,
) {
    let sub_map = match agent_value.get("sub_agents").and_then(|v| v.as_mapping()) {
        Some(m) => m,
        None => return,
    };
    for (key_val, sub_val) in sub_map {
        let key = match key_val.as_str() {
            Some(s) => s,
            None => continue,
        };
        if let Some(sub_config) = sub_agents.get_mut(key) {
            if let Some(nested_mapping) = sub_val.get("sub_agents").and_then(|v| v.as_mapping()) {
                sub_config.sub_agent_order = nested_mapping
                    .keys()
                    .filter_map(|k| k.as_str().map(|s| s.to_string()))
                    .collect();
            }
            populate_sub_agent_order_recursive(sub_val, &mut sub_config.sub_agents);
        }
    }
}

/// Reads and parses the `dspatch.workspace.yml` file from `project_path`.
///
/// Returns an error if the file doesn't exist or the YAML is invalid.
pub fn parse_workspace_config_file(project_path: &Path) -> Result<WorkspaceConfig> {
    let file_path = project_path.join("dspatch.workspace.yml");
    let content = std::fs::read_to_string(&file_path)
        .with_context(|| format!("Failed to read {}", file_path.display()))?;
    parse_workspace_config(&content)
}

/// Writes a [`WorkspaceConfig`] as `dspatch.workspace.yml` to `project_path`.
///
/// Uses an atomic write: serializes to a `.tmp` file then renames it over the
/// target, so a partial write never corrupts an existing config.
pub async fn write_workspace_config(project_path: &Path, config: &WorkspaceConfig) -> Result<()> {
    let file_path = project_path.join("dspatch.workspace.yml");
    let tmp_path = project_path.join("dspatch.workspace.yml.tmp");
    let yaml = encode_yaml(config)?;
    tokio::fs::write(&tmp_path, yaml)
        .await
        .with_context(|| format!("Failed to write {}", tmp_path.display()))?;
    tokio::fs::rename(&tmp_path, &file_path)
        .await
        .with_context(|| format!("Failed to rename {} to {}", tmp_path.display(), file_path.display()))?;
    Ok(())
}

/// Encodes a [`WorkspaceConfig`] as a YAML string.
pub fn encode_yaml(config: &WorkspaceConfig) -> Result<String> {
    serde_yml::to_string(config).context("Failed to encode workspace config as YAML")
}
