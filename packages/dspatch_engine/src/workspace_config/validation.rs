// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::{HashMap, HashSet};

use super::config::{AgentConfig, DockerConfig, MountConfig, WorkspaceConfig};

/// Maximum nesting depth for recursive agent parsing.
///
/// Prevents stack overflow or exponential work from pathological configs
/// with deeply nested sub-agent trees.
const MAX_DEPTH: usize = 10;

/// A validation error found in a [`WorkspaceConfig`].
///
/// Each error identifies the field path (e.g. `"agents.coder.template"`)
/// and a human-readable message describing the issue.
#[derive(Debug, Clone, PartialEq)]
pub struct ConfigValidationError {
    pub field: String,
    pub message: String,
}

impl std::fmt::Display for ConfigValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: {}", self.field, self.message)
    }
}

/// Reserved prefix for system environment variables.
const SYSTEM_ENV_PREFIX: &str = "DSPATCH_";

/// Reserved container paths that user mounts must not conflict with.
const RESERVED_PATHS: &[&str] = &["/workspace", "/entrypoint.sh", "/src"];

const VALID_NETWORK_MODES: &[&str] = &["bridge", "host", "none"];

/// Validates a [`WorkspaceConfig`] and returns a list of errors.
///
/// An empty list means the config is valid.
pub fn validate_config(config: &WorkspaceConfig) -> Vec<ConfigValidationError> {
    let mut errors = Vec::new();

    if config.name.trim().is_empty() {
        errors.push(ConfigValidationError {
            field: "name".to_string(),
            message: "Workspace name is required".to_string(),
        });
    }

    if config.agents.is_empty() {
        errors.push(ConfigValidationError {
            field: "agents".to_string(),
            message: "At least one agent is required".to_string(),
        });
    }

    // Collect all agent keys for peer validation.
    let mut all_keys = HashSet::new();
    collect_agent_keys(&config.agents, "", &mut all_keys, &mut errors, 0);

    // Validate peer references.
    validate_peer_references(&config.agents, "", &all_keys, &mut errors);

    // Validate env keys don't use reserved system prefix.
    validate_env_prefix(&config.env, "env", &mut errors);
    validate_agent_env_prefix(&config.agents, "agents", &mut errors);

    // Validate additional mounts.
    validate_mounts(&config.mounts, &mut errors);

    // Validate Docker settings.
    validate_docker_config(&config.docker, &mut errors);

    errors
}

fn collect_agent_keys(
    agents: &HashMap<String, AgentConfig>,
    prefix: &str,
    all_keys: &mut HashSet<String>,
    errors: &mut Vec<ConfigValidationError>,
    depth: usize,
) {
    if depth >= MAX_DEPTH {
        errors.push(ConfigValidationError {
            field: prefix.to_string(),
            message: format!(
                "Agent nesting depth exceeds maximum of {} levels",
                MAX_DEPTH
            ),
        });
        return;
    }

    for (agent_key, agent_config) in agents {
        // Use the fully-qualified path as the unique key so that agents at
        // different levels of the hierarchy can share the same local name
        // without triggering false duplicate errors, while still detecting
        // genuine duplicates within the same parent.
        let qualified_key = if prefix.is_empty() {
            agent_key.clone()
        } else {
            format!("{}.{}", prefix, agent_key)
        };

        if !all_keys.insert(qualified_key.clone()) {
            errors.push(ConfigValidationError {
                field: qualified_key.clone(),
                message: format!("Duplicate agent key \"{}\"", qualified_key),
            });
        }

        if agent_config.template.trim().is_empty() {
            errors.push(ConfigValidationError {
                field: format!("{}.template", qualified_key),
                message: format!("Template name is required for agent \"{}\"", agent_key),
            });
        }

        if !agent_config.sub_agents.is_empty() {
            collect_agent_keys(
                &agent_config.sub_agents,
                &qualified_key,
                all_keys,
                errors,
                depth + 1,
            );
        }
    }
}

fn validate_peer_references(
    agents: &HashMap<String, AgentConfig>,
    prefix: &str,
    all_keys: &HashSet<String>,
    errors: &mut Vec<ConfigValidationError>,
) {
    for (agent_key, agent_config) in agents {
        let key = if prefix.is_empty() {
            agent_key.clone()
        } else {
            format!("{}.{}", prefix, agent_key)
        };

        for peer in &agent_config.peers {
            // Peers may be referenced by their fully-qualified path (e.g.
            // "parent.child") or by bare name (e.g. "child"). Accept either.
            let peer_found = all_keys.contains(peer.as_str())
                || all_keys.iter().any(|k| {
                    k == peer
                        || k.ends_with(&format!(".{}", peer))
                });
            if !peer_found {
                errors.push(ConfigValidationError {
                    field: format!("{}.peers", key),
                    message: format!(
                        "Peer \"{}\" referenced by agent \"{}\" does not exist",
                        peer, agent_key
                    ),
                });
            }
        }

        if !agent_config.sub_agents.is_empty() {
            validate_peer_references(&agent_config.sub_agents, &key, all_keys, errors);
        }
    }
}

fn validate_env_prefix(
    env: &HashMap<String, String>,
    field: &str,
    errors: &mut Vec<ConfigValidationError>,
) {
    for key in env.keys() {
        if key.to_uppercase().starts_with(SYSTEM_ENV_PREFIX) {
            errors.push(ConfigValidationError {
                field: format!("{}.{}", field, key),
                message: format!(
                    "Environment variable \"{}\" uses reserved prefix \"{}\" \
                     — system variables cannot be overridden",
                    key, SYSTEM_ENV_PREFIX
                ),
            });
        }
    }
}

fn validate_agent_env_prefix(
    agents: &HashMap<String, AgentConfig>,
    prefix: &str,
    errors: &mut Vec<ConfigValidationError>,
) {
    for (agent_key, agent_config) in agents {
        let agent_path = format!("{}.{}", prefix, agent_key);
        validate_env_prefix(&agent_config.env, &format!("{}.env", agent_path), errors);
        if !agent_config.sub_agents.is_empty() {
            validate_agent_env_prefix(
                &agent_config.sub_agents,
                &format!("{}.sub_agents", agent_path),
                errors,
            );
        }
    }
}

fn validate_mounts(mounts: &[MountConfig], errors: &mut Vec<ConfigValidationError>) {
    for (i, mount) in mounts.iter().enumerate() {
        let field = format!("mounts[{}]", i);

        if mount.host_path.trim().is_empty() {
            errors.push(ConfigValidationError {
                field: format!("{}.host_path", field),
                message: "Host path is required".to_string(),
            });
        }

        if mount.container_path.trim().is_empty() {
            errors.push(ConfigValidationError {
                field: format!("{}.container_path", field),
                message: "Container path is required".to_string(),
            });
        } else if !mount.container_path.starts_with('/') {
            errors.push(ConfigValidationError {
                field: format!("{}.container_path", field),
                message: "Container path must be absolute (start with /)".to_string(),
            });
        } else {
            let cp = &mount.container_path;
            for reserved in RESERVED_PATHS {
                if cp == reserved || cp.starts_with(&format!("{}/", reserved)) {
                    errors.push(ConfigValidationError {
                        field: format!("{}.container_path", field),
                        message: format!(
                            "Container path \"{}\" conflicts with reserved path \"{}\"",
                            cp, reserved
                        ),
                    });
                }
            }
            if cp == "/agents" || cp.starts_with("/agents/") {
                errors.push(ConfigValidationError {
                    field: format!("{}.container_path", field),
                    message: format!(
                        "Container path \"{}\" conflicts with reserved path \"/agents\"",
                        cp
                    ),
                });
            }
        }
    }
}

fn validate_docker_config(docker: &DockerConfig, errors: &mut Vec<ConfigValidationError>) {
    if let Some(ref mem) = docker.memory_limit {
        let memory_re = regex_lite::Regex::new(r"(?i)^\d+[bkmg]$").unwrap();
        if !memory_re.is_match(mem) {
            errors.push(ConfigValidationError {
                field: "docker.memory_limit".to_string(),
                message: "Invalid memory limit format (use e.g. \"512m\", \"4g\")".to_string(),
            });
        }
    }

    if let Some(cpu) = docker.cpu_limit {
        if cpu <= 0.0 {
            errors.push(ConfigValidationError {
                field: "docker.cpu_limit".to_string(),
                message: "CPU limit must be greater than 0".to_string(),
            });
        }
    }

    if !docker.network_mode.is_empty() && !VALID_NETWORK_MODES.contains(&docker.network_mode.as_str()) {
        errors.push(ConfigValidationError {
            field: "docker.network_mode".to_string(),
            message: format!(
                "Invalid network mode \"{}\" (must be one of: {})",
                docker.network_mode,
                VALID_NETWORK_MODES.join(", ")
            ),
        });
    }

    let port_re = regex_lite::Regex::new(r"^\d+:\d+$").unwrap();
    for (i, port) in docker.ports.iter().enumerate() {
        if !port_re.is_match(port) {
            errors.push(ConfigValidationError {
                field: format!("docker.ports[{}]", i),
                message: format!(
                    "Invalid port mapping \"{}\" (use format \"hostPort:containerPort\")",
                    port
                ),
            });
        }
    }
}
