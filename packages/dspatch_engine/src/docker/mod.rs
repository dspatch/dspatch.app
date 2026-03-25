// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker CLI wrapper and client for container management.
//!
//! Ported from `data/docker/` in the Dart SDK.

mod asset;
mod cli;
mod client;
pub mod models;

pub use asset::{assemble_build_context, runtime_image_tag, DSPATCH_CONTAINER_LABEL};
pub use cli::{DockerCli, DockerCliException};
pub use client::DockerClient;
pub use models::{
    parse_memory_limit, ContainerConfig, ContainerInspect, ContainerState, ContainerStats,
    CreateContainerRequest, DeviceRequest, DockerImage, DockerInfo, DockerVersion, HostConfig,
    PortBinding,
};
