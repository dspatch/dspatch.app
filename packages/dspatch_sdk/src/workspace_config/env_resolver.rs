// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::{HashMap, HashSet};

use super::config::AgentConfig;
use super::template_resolver::{EmptyRequiredEnv, MissingRequiredEnv};

/// Reserved prefix for system environment variables.
const SYSTEM_ENV_PREFIX: &str = "DSPATCH_";

/// Computes the effective env map for a single agent.
///
/// Merge order: workspace global env -> agent override env.
/// Filter: only keys listed in `required_env` are included.
/// If `required_env` is empty, returns the full merged map.
///
/// Keys starting with `DSPATCH_` are always stripped.
pub fn resolve_agent_env(
    global_env: &HashMap<String, String>,
    agent_env: &HashMap<String, String>,
    required_env: &[String],
) -> HashMap<String, String> {
    let mut merged = HashMap::new();

    if required_env.is_empty() {
        merged.extend(global_env.clone());
        merged.extend(agent_env.clone());
    } else {
        for key in required_env {
            // Agent override takes priority over global.
            if let Some(val) = agent_env.get(key) {
                merged.insert(key.clone(), val.clone());
            } else if let Some(val) = global_env.get(key) {
                merged.insert(key.clone(), val.clone());
            }
        }
    }

    // Strip system-reserved prefix (defense in depth).
    merged.retain(|key, _| !key.to_uppercase().starts_with(SYSTEM_ENV_PREFIX));

    merged
}

/// Collects the union of all `required_env` keys across templates
/// referenced by agents in the hierarchy.
pub fn collect_all_required_keys(
    agents: &HashMap<String, AgentConfig>,
    template_required_env: &HashMap<String, Vec<String>>,
) -> HashSet<String> {
    let mut keys = HashSet::new();
    collect_keys_recursive(agents, template_required_env, &mut keys);
    keys
}

fn collect_keys_recursive(
    agents: &HashMap<String, AgentConfig>,
    template_required_env: &HashMap<String, Vec<String>>,
    keys: &mut HashSet<String>,
) {
    for agent in agents.values() {
        if let Some(required) = template_required_env.get(&agent.template) {
            keys.extend(required.iter().cloned());
        }
        if !agent.sub_agents.is_empty() {
            collect_keys_recursive(&agent.sub_agents, template_required_env, keys);
        }
    }
}

/// Result of [`validate_hierarchy`].
#[derive(Debug, Clone, PartialEq)]
pub struct EnvValidationResult {
    pub missing_required_env: Vec<MissingRequiredEnv>,
    pub empty_required_env: Vec<EmptyRequiredEnv>,
}

/// Validates env resolution for every agent in the hierarchy.
///
/// Checks that each template's required env keys are present and
/// non-empty in the merged global + agent override env.
pub fn validate_hierarchy(
    global_env: &HashMap<String, String>,
    agents: &HashMap<String, AgentConfig>,
    template_required_env: &HashMap<String, Vec<String>>,
    path_prefix: &str,
) -> EnvValidationResult {
    let mut missing_env = Vec::new();
    let mut empty_env = Vec::new();

    validate_recursive(
        global_env,
        agents,
        template_required_env,
        path_prefix,
        &mut missing_env,
        &mut empty_env,
    );

    EnvValidationResult {
        missing_required_env: missing_env,
        empty_required_env: empty_env,
    }
}

fn validate_recursive(
    global_env: &HashMap<String, String>,
    agents: &HashMap<String, AgentConfig>,
    template_required_env: &HashMap<String, Vec<String>>,
    path_prefix: &str,
    missing_env: &mut Vec<MissingRequiredEnv>,
    empty_env: &mut Vec<EmptyRequiredEnv>,
) {
    for (key, agent_config) in agents {
        let agent_path = format!("{}.{}", path_prefix, key);

        if let Some(required_keys) = template_required_env.get(&agent_config.template) {
            for env_key in required_keys {
                let effective_value = agent_config
                    .env
                    .get(env_key)
                    .or_else(|| global_env.get(env_key));

                match effective_value {
                    None => {
                        missing_env.push(MissingRequiredEnv {
                            agent_path: agent_path.clone(),
                            template_name: agent_config.template.clone(),
                            env_key: env_key.clone(),
                        });
                    }
                    Some(val) if val.trim().is_empty() => {
                        empty_env.push(EmptyRequiredEnv {
                            agent_path: agent_path.clone(),
                            template_name: agent_config.template.clone(),
                            env_key: env_key.clone(),
                        });
                    }
                    _ => {}
                }
            }
        }

        if !agent_config.sub_agents.is_empty() {
            validate_recursive(
                global_env,
                &agent_config.sub_agents,
                template_required_env,
                &format!("{}.sub_agents", agent_path),
                missing_env,
                empty_env,
            );
        }
    }
}

/// Resolves env vars for all agents in the hierarchy for launch.
///
/// Returns a flat map of `agent_key -> resolved env map`.
pub fn resolve_for_launch(
    global_env: &HashMap<String, String>,
    agents: &HashMap<String, AgentConfig>,
    template_required_env: &HashMap<String, Vec<String>>,
) -> HashMap<String, HashMap<String, String>> {
    let mut resolved = HashMap::new();
    resolve_for_launch_recursive(global_env, agents, template_required_env, &mut resolved);
    resolved
}

fn resolve_for_launch_recursive(
    global_env: &HashMap<String, String>,
    agents: &HashMap<String, AgentConfig>,
    template_required_env: &HashMap<String, Vec<String>>,
    resolved: &mut HashMap<String, HashMap<String, String>>,
) {
    for (agent_key, agent_config) in agents {
        let required_keys = template_required_env
            .get(&agent_config.template)
            .cloned()
            .unwrap_or_default();

        resolved.insert(
            agent_key.clone(),
            resolve_agent_env(global_env, &agent_config.env, &required_keys),
        );

        if !agent_config.sub_agents.is_empty() {
            resolve_for_launch_recursive(
                global_env,
                &agent_config.sub_agents,
                template_required_env,
                resolved,
            );
        }
    }
}
