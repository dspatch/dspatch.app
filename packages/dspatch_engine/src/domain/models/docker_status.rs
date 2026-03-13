// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Snapshot of the local Docker daemon's readiness for session containers.
///
/// [`is_installed`] reflects whether the Docker CLI binary is found on disk.
/// [`is_running`] reflects whether the daemon is reachable. [`has_sysbox`] and
/// [`has_runtime_image`] indicate prerequisite checks completed at startup.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DockerStatus {
    #[serde(default)]
    pub is_installed: bool,
    #[serde(default)]
    pub is_running: bool,
    #[serde(default)]
    pub has_sysbox: bool,
    #[serde(default)]
    pub has_nvidia_runtime: bool,
    #[serde(default)]
    pub has_runtime_image: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub runtime_image_size: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub docker_version: Option<String>,
}
