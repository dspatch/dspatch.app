// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

/// Top-level workspace configuration parsed from `dspatch.workspace.yml`.
///
/// Contains the workspace name, agent hierarchy, workspace directory,
/// additional bind mounts, and Docker container settings.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WorkspaceConfig {
    pub name: String,

    /// Global environment variables shared across all agents.
    /// Per-agent overrides in [`AgentConfig::env`] take priority.
    #[serde(default)]
    pub env: HashMap<String, String>,

    #[serde(default)]
    pub agents: HashMap<String, AgentConfig>,

    /// Agent keys in YAML declaration order (populated during parsing).
    #[serde(skip)]
    pub agent_order: Vec<String>,

    /// Host directory mounted as `/workspace` inside the container.
    /// If omitted, the project directory is used.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub workspace_dir: Option<String>,

    /// Additional bind mounts from the host into the container.
    #[serde(default)]
    pub mounts: Vec<MountConfig>,

    /// Advanced Docker container settings.
    #[serde(default)]
    pub docker: DockerConfig,
}

/// Configuration for a single agent within a workspace.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AgentConfig {
    pub template: String,

    #[serde(default)]
    pub env: HashMap<String, String>,

    #[serde(default)]
    pub sub_agents: HashMap<String, AgentConfig>,

    /// Sub-agent keys in YAML declaration order (populated during parsing).
    #[serde(skip)]
    pub sub_agent_order: Vec<String>,

    #[serde(default)]
    pub peers: Vec<String>,

    /// Whether the engine should auto-start an instance for this agent.
    /// Defaults to `true` for root-level agents and `false` for sub-agents
    /// when omitted.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub auto_start: Option<bool>,
}

/// Configuration for an additional bind mount from host into the container.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MountConfig {
    /// Host filesystem path to mount from.
    pub host_path: String,

    /// Absolute path inside the container to mount to.
    pub container_path: String,

    /// Whether the mount is read-only. Defaults to `true`.
    #[serde(default = "default_true")]
    pub read_only: bool,
}

fn default_true() -> bool {
    true
}

/// Advanced Docker container settings.
///
/// All fields are optional — omitting them uses Docker defaults.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DockerConfig {
    /// Memory limit, e.g. `"4g"`, `"512m"`.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub memory_limit: Option<String>,

    /// CPU core limit, e.g. `2.0` for 2 cores.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cpu_limit: Option<f64>,

    /// Docker network mode: `"host"` (default), `"bridge"`, or `"none"`.
    #[serde(default = "default_network_mode")]
    pub network_mode: String,

    /// Port mappings, e.g. `["8080:80", "3000:3000"]`.
    #[serde(default)]
    pub ports: Vec<String>,

    /// Enable NVIDIA GPU passthrough.
    #[serde(default)]
    pub gpu: bool,

    /// Whether to persist /root across container restarts using a named volume.
    #[serde(default = "default_true")]
    pub home_persistence: bool,

    /// Advisory size hint for the home volume, e.g. "20g", "512m".
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub home_size: Option<String>,
}

fn default_network_mode() -> String {
    "host".to_string()
}

impl Default for DockerConfig {
    fn default() -> Self {
        Self {
            memory_limit: None,
            cpu_limit: None,
            network_mode: default_network_mode(),
            ports: Vec::new(),
            gpu: false,
            home_persistence: true,
            home_size: None,
        }
    }
}
