// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker data models for daemon info, images, containers, and creation requests.
//!
//! Ported from `data/docker/docker_models.dart`.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Daemon info
// ---------------------------------------------------------------------------

/// Subset of Docker's `GET /info` response.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DockerInfo {
    #[serde(rename = "ServerVersion", default)]
    pub server_version: String,

    #[serde(rename = "Runtimes", default)]
    pub runtimes: HashMap<String, serde_json::Value>,
}

/// Subset of Docker's `GET /version` response.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DockerVersion {
    #[serde(rename = "Version", default)]
    pub version: String,

    /// CLI outputs `APIVersion`, REST API uses `ApiVersion`.
    #[serde(alias = "APIVersion", rename = "ApiVersion", default)]
    pub api_version: String,

    #[serde(rename = "Os", default)]
    pub os: String,

    #[serde(rename = "Arch", default)]
    pub arch: String,
}

// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------

/// A Docker image from `docker image inspect`.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DockerImage {
    #[serde(rename = "Id", default)]
    pub id: String,

    #[serde(rename = "RepoTags", default)]
    pub repo_tags: Vec<String>,

    #[serde(rename = "Size", default)]
    pub size: i64,

    /// Epoch seconds (or ISO string parsed to epoch in client).
    #[serde(rename = "Created", default)]
    pub created: i64,
}

// ---------------------------------------------------------------------------
// Containers
// ---------------------------------------------------------------------------

/// Full container detail from `docker inspect`.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ContainerInspect {
    #[serde(rename = "Id", default)]
    pub id: String,

    #[serde(rename = "State")]
    pub state: Option<ContainerState>,

    #[serde(rename = "Config")]
    pub config: Option<ContainerConfig>,

    #[serde(rename = "NetworkSettings")]
    pub network_settings: Option<NetworkSettings>,
}

/// Container runtime state (nested within [`ContainerInspect`]).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ContainerState {
    #[serde(rename = "Status", default)]
    pub status: String,

    #[serde(rename = "Running", default)]
    pub running: bool,

    #[serde(rename = "ExitCode", default)]
    pub exit_code: i32,

    #[serde(rename = "StartedAt", default)]
    pub started_at: String,

    #[serde(rename = "FinishedAt", default)]
    pub finished_at: String,
}

/// Container configuration (image, env, labels).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ContainerConfig {
    #[serde(rename = "Image", default)]
    pub image: String,

    #[serde(rename = "Env", default)]
    pub env: Vec<String>,

    #[serde(rename = "Labels", default)]
    pub labels: HashMap<String, String>,
}

/// Network settings (nested within [`ContainerInspect`]).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct NetworkSettings {
    #[serde(rename = "Ports", default)]
    pub ports: HashMap<String, serde_json::Value>,
}

// ---------------------------------------------------------------------------
// Container creation request
// ---------------------------------------------------------------------------

/// Parameters for `docker create`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateContainerRequest {
    #[serde(rename = "Image")]
    pub image: String,

    #[serde(rename = "Entrypoint", skip_serializing_if = "Option::is_none")]
    pub entrypoint: Option<Vec<String>>,

    #[serde(rename = "Env", default)]
    pub env: Vec<String>,

    #[serde(rename = "HostConfig", skip_serializing_if = "Option::is_none")]
    pub host_config: Option<HostConfig>,

    #[serde(rename = "Labels", default)]
    pub labels: HashMap<String, String>,

    #[serde(rename = "ExposedPorts", default)]
    pub exposed_ports: HashMap<String, serde_json::Value>,
}

/// Host configuration for container creation.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HostConfig {
    #[serde(rename = "Binds", default)]
    pub binds: Vec<String>,

    #[serde(rename = "Privileged", default)]
    pub privileged: bool,

    #[serde(rename = "Runtime", skip_serializing_if = "Option::is_none")]
    pub runtime: Option<String>,

    #[serde(rename = "PortBindings", default)]
    pub port_bindings: HashMap<String, Vec<PortBinding>>,

    #[serde(rename = "AutoRemove", default)]
    pub auto_remove: bool,

    #[serde(rename = "ExtraHosts", default)]
    pub extra_hosts: Vec<String>,

    /// Memory limit in bytes.
    #[serde(rename = "Memory", skip_serializing_if = "Option::is_none")]
    pub memory: Option<i64>,

    /// CPU quota in nano-CPUs. E.g. 2e9 = 2 cores.
    #[serde(rename = "NanoCpus", skip_serializing_if = "Option::is_none")]
    pub nano_cpus: Option<i64>,

    /// Docker network mode: "bridge", "host", "none", etc.
    #[serde(rename = "NetworkMode", skip_serializing_if = "Option::is_none")]
    pub network_mode: Option<String>,

    /// Device requests for GPU passthrough.
    #[serde(rename = "DeviceRequests", skip_serializing_if = "Option::is_none")]
    pub device_requests: Option<Vec<DeviceRequest>>,
}

/// Device request for GPU passthrough.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DeviceRequest {
    #[serde(rename = "Driver", default)]
    pub driver: String,

    #[serde(rename = "Count", default = "default_device_count")]
    pub count: i32,

    #[serde(rename = "Capabilities", default)]
    pub capabilities: Vec<Vec<String>>,
}

fn default_device_count() -> i32 {
    -1
}

/// A single port binding entry.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PortBinding {
    #[serde(rename = "HostIp", default)]
    pub host_ip: String,

    #[serde(rename = "HostPort", default)]
    pub host_port: String,
}

/// One-shot container resource stats from `docker stats --no-stream`.
#[derive(Debug, Clone, Default)]
pub struct ContainerStats {
    /// Memory usage string, e.g. "142.3MiB / 4GiB".
    pub mem_usage: String,
    /// CPU usage percentage string, e.g. "3.45%".
    pub cpu_perc: String,
    /// Network I/O string, e.g. "1.2MB / 340kB".
    pub net_io: String,
    /// Block (disk) I/O string, e.g. "12.3MB / 0B".
    pub block_io: String,
    /// Number of running processes.
    pub pids: String,
}

/// Parses a Docker memory limit string (e.g. "512m", "4g") to bytes.
pub fn parse_memory_limit(value: &str) -> Option<i64> {
    if value.is_empty() {
        return None;
    }
    let lower = value.to_lowercase();
    let (num_part, suffix) = lower.split_at(lower.len() - 1);
    let num: i64 = num_part.parse().ok()?;
    match suffix {
        "b" => Some(num),
        "k" => Some(num * 1024),
        "m" => Some(num * 1024 * 1024),
        "g" => Some(num * 1024 * 1024 * 1024),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_memory_limit_values() {
        assert_eq!(parse_memory_limit("512m"), Some(512 * 1024 * 1024));
        assert_eq!(parse_memory_limit("4g"), Some(4 * 1024 * 1024 * 1024));
        assert_eq!(parse_memory_limit("1024k"), Some(1024 * 1024));
        assert_eq!(parse_memory_limit(""), None);
        assert_eq!(parse_memory_limit("abc"), None);
    }

    #[test]
    fn docker_info_json_parse() {
        let json = r#"{"ServerVersion":"24.0.7","Runtimes":{"runc":{"path":"runc"},"sysbox-runc":{"path":"/usr/bin/sysbox-runc"}}}"#;
        let info: DockerInfo = serde_json::from_str(json).unwrap();
        assert_eq!(info.server_version, "24.0.7");
        assert!(info.runtimes.contains_key("sysbox-runc"));
    }

    #[test]
    fn docker_version_json_parse() {
        let json = r#"{"Version":"24.0.7","APIVersion":"1.43","Os":"linux","Arch":"amd64"}"#;
        let ver: DockerVersion = serde_json::from_str(json).unwrap();
        assert_eq!(ver.version, "24.0.7");
        assert_eq!(ver.api_version, "1.43");
        assert_eq!(ver.os, "linux");
        assert_eq!(ver.arch, "amd64");
    }

    #[test]
    fn docker_image_json_parse() {
        let json = r#"{"Id":"sha256:abc123","RepoTags":["dspatch/runtime:latest"],"Size":1234567890,"Created":1700000000}"#;
        let img: DockerImage = serde_json::from_str(json).unwrap();
        assert_eq!(img.id, "sha256:abc123");
        assert_eq!(img.repo_tags, vec!["dspatch/runtime:latest"]);
        assert_eq!(img.size, 1234567890);
        assert_eq!(img.created, 1700000000);
    }

    #[test]
    fn container_inspect_json_parse() {
        let json = r#"{
            "Id": "abc123",
            "State": {
                "Status": "running",
                "Running": true,
                "ExitCode": 0,
                "StartedAt": "2024-01-15T09:30:00Z",
                "FinishedAt": "0001-01-01T00:00:00Z"
            },
            "Config": {
                "Image": "dspatch/runtime:latest",
                "Env": ["FOO=bar"],
                "Labels": {"com.dspatch.managed": "true"}
            },
            "NetworkSettings": {
                "Ports": {}
            }
        }"#;
        let inspect: ContainerInspect = serde_json::from_str(json).unwrap();
        assert_eq!(inspect.id, "abc123");
        assert!(inspect.state.as_ref().unwrap().running);
        assert_eq!(
            inspect.config.as_ref().unwrap().image,
            "dspatch/runtime:latest"
        );
    }

    #[test]
    fn port_binding_serde_roundtrip() {
        let pb = PortBinding {
            host_ip: "0.0.0.0".to_string(),
            host_port: "8080".to_string(),
        };
        let json = serde_json::to_string(&pb).unwrap();
        let deserialized: PortBinding = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.host_ip, "0.0.0.0");
        assert_eq!(deserialized.host_port, "8080");
    }
}
