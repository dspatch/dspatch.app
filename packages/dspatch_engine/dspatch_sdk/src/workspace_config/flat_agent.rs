// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use super::config::{AgentConfig, WorkspaceConfig};

/// A flattened representation of an agent from the workspace hierarchy.
///
/// Produced by [`flatten_agent_hierarchy`] to convert the nested agent tree
/// into a flat list suitable for creating workspace agent rows in the database.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FlatAgent {
    pub agent_key: String,
    pub template_name: String,
    pub parent_key: Option<String>,
    #[serde(default)]
    pub peers: Vec<String>,
    #[serde(default)]
    pub auto_start: bool,
}

/// Flattens the nested agent hierarchy into a flat list of [`FlatAgent`]s.
///
/// Each agent in the hierarchy (including sub-agents) becomes a
/// [`FlatAgent`] with its key, template name, parent key, and peers.
pub fn flatten_agent_hierarchy(config: &WorkspaceConfig) -> Vec<FlatAgent> {
    let mut result = Vec::new();
    flatten_agents(&config.agents, &config.agent_order, None, &mut result);
    result
}

fn flatten_agents(
    agents: &HashMap<String, AgentConfig>,
    order: &[String],
    parent_key: Option<&str>,
    result: &mut Vec<FlatAgent>,
) {
    let is_root = parent_key.is_none();
    // Iterate in declaration order; fall back to HashMap order for keys
    // not in the order vec (shouldn't happen with well-formed configs).
    let ordered_keys: Vec<&String> = if order.is_empty() {
        agents.keys().collect()
    } else {
        let mut keys: Vec<&String> = order.iter().filter(|k| agents.contains_key(k.as_str())).collect();
        // Append any keys missing from the order vec.
        for k in agents.keys() {
            if !order.iter().any(|o| o == k) {
                keys.push(k);
            }
        }
        keys
    };
    for key in ordered_keys {
        let agent_config = &agents[key];
        result.push(FlatAgent {
            agent_key: key.clone(),
            template_name: agent_config.template.clone(),
            parent_key: parent_key.map(|s| s.to_string()),
            peers: agent_config.peers.clone(),
            auto_start: agent_config.auto_start.unwrap_or(is_root),
        });

        if !agent_config.sub_agents.is_empty() {
            flatten_agents(&agent_config.sub_agents, &agent_config.sub_agent_order, Some(key), result);
        }
    }
}

/// Pure utility for agent map operations (add, remove, rename).
///
/// Centralizes the logic for agent map manipulation.
pub fn add_agent(
    agents: &HashMap<String, AgentConfig>,
    prefix: &str,
) -> HashMap<String, AgentConfig> {
    let mut result = agents.clone();
    let mut key = format!("{}-{}", prefix, result.len() + 1);
    while result.contains_key(&key) {
        key = format!("{}-new", key);
    }
    result.insert(
        key,
        AgentConfig {
            template: String::new(),
            env: HashMap::new(),
            sub_agents: HashMap::new(),
            sub_agent_order: Vec::new(),
            peers: Vec::new(),
            auto_start: None,
        },
    );
    result
}

/// Removes an agent and cleans up peer references in siblings.
pub fn remove_agent(
    agents: &HashMap<String, AgentConfig>,
    key: &str,
) -> HashMap<String, AgentConfig> {
    let mut result = agents.clone();
    result.remove(key);
    result
        .into_iter()
        .map(|(k, mut v)| {
            v.peers.retain(|p| p != key);
            (k, v)
        })
        .collect()
}

/// Renames an agent key and updates all peer references.
///
/// Returns the original map unchanged if `old_key == new_key`,
/// `new_key` is empty, or `old_key` is not found.
pub fn rename_agent(
    agents: &HashMap<String, AgentConfig>,
    old_key: &str,
    new_key: &str,
) -> HashMap<String, AgentConfig> {
    if old_key == new_key || new_key.is_empty() {
        return agents.clone();
    }
    let mut result = agents.clone();
    let config = match result.remove(old_key) {
        Some(c) => c,
        None => return agents.clone(),
    };
    result.insert(new_key.to_string(), config);
    result
        .into_iter()
        .map(|(k, mut v)| {
            v.peers = v
                .peers
                .into_iter()
                .map(|p| {
                    if p == old_key {
                        new_key.to_string()
                    } else {
                        p
                    }
                })
                .collect();
            (k, v)
        })
        .collect()
}
