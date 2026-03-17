// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// A bind-mount mapping a host directory into a provider's container.
///
/// [`host_path`] is the absolute path on the host machine; [`container_path`] is
/// the target inside the container. Set [`is_read_only`] to prevent writes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct VolumeMount {
    pub host_path: String,
    pub container_path: String,
    #[serde(default)]
    pub is_read_only: bool,
}
