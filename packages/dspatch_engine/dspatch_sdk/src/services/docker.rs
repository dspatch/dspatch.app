// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local Docker service — wraps DockerClient, maps errors to AppError::Docker.

use std::collections::HashMap;

use async_trait::async_trait;
use futures::StreamExt;

use crate::docker::{
    assemble_build_context, DockerClient, DSPATCH_CONTAINER_LABEL, RUNTIME_IMAGE_TAG,
};
use crate::domain::models::DockerStatus;
use std::pin::Pin;

use crate::domain::services::{ContainerSummary, DockerService};
use crate::util::error::AppError;
use crate::util::format::format_bytes;
use crate::util::result::Result;

/// Container state value for running containers.
const CONTAINER_STATE_RUNNING: &str = "running";

/// Local Docker service backed by [`DockerClient`].
///
/// Bridges the Docker CLI client to the domain `DockerService` interface,
/// handling error mapping and bulk operation orchestration.
pub struct LocalDockerService {
    client: DockerClient,
    assets_dir: String,
}

impl LocalDockerService {
    pub fn new(client: DockerClient, assets_dir: String) -> Self {
        Self { client, assets_dir }
    }

    // ── Status detection ──

    /// Detects Docker daemon status: reachable, Sysbox available, runtime image exists.
    pub async fn detect_status(&self) -> Result<DockerStatus> {
        // 1. Ping — is the daemon reachable?
        if let Err(e) = self.client.ping().await {
            tracing::warn!("Docker daemon not reachable: {e}");
            return Ok(DockerStatus {
                is_installed: true,
                is_running: false,
                has_sysbox: false,
                has_nvidia_runtime: false,
                has_runtime_image: false,
                runtime_image_size: None,
                docker_version: None,
            });
        }

        // 2. Version
        let docker_version = match self.client.version().await {
            Ok(ver) => Some(ver.version),
            Err(e) => {
                tracing::warn!("Failed to fetch Docker version: {e}");
                None
            }
        };

        // 3. Info — check available runtimes
        let (has_sysbox, has_nvidia_runtime) = match self.client.info().await {
            Ok(info) => {
                let sysbox = if cfg!(target_os = "linux") {
                    info.runtimes.contains_key("sysbox-runc")
                } else {
                    false
                };
                let nvidia = info.runtimes.contains_key("nvidia");
                (sysbox, nvidia)
            }
            Err(e) => {
                tracing::warn!("Failed to fetch Docker info: {e}");
                (false, false)
            }
        };

        // 4. Images — check if runtime image exists
        let (has_runtime_image, runtime_image_size) =
            match self.client.list_images(Some(RUNTIME_IMAGE_TAG)).await {
                Ok(images) => {
                    if let Some(img) = images.first() {
                        (true, Some(format_bytes(img.size as u64)))
                    } else {
                        (false, None)
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to list Docker images: {e}");
                    (false, None)
                }
            };

        Ok(DockerStatus {
            is_installed: true,
            is_running: true,
            docker_version,
            has_sysbox,
            has_nvidia_runtime,
            has_runtime_image,
            runtime_image_size,
        })
    }

    // ── Image management ──

    /// Builds the d:spatch runtime image. Returns a stream of build log lines.
    ///
    /// This creates a temporary build context, invokes `docker build`, and
    /// streams the output. The temp directory is cleaned up when the stream
    /// completes.
    ///
    /// The returned stream performs all work lazily — no `tokio::spawn` is used
    /// internally, so the caller must drive this stream from within a Tokio
    /// runtime context (e.g. via `forward_stream`).
    pub fn build_runtime_image(&self) -> Pin<Box<dyn futures::Stream<Item = String> + Send>> {
        let assets_dir = self.assets_dir.clone();

        let stream = async_stream::stream! {
            let context_dir = match assemble_build_context(&assets_dir).await {
                Ok(dir) => dir,
                Err(e) => {
                    tracing::error!("Failed to assemble build context: {e}");
                    return;
                }
            };

            // Create a fresh DockerClient for the build task.
            let client = DockerClient::for_platform();
            let build_stream =
                client.build_image_from_context(&context_dir, RUNTIME_IMAGE_TAG);
            futures::pin_mut!(build_stream);
            while let Some(result) = build_stream.next().await {
                match result {
                    Ok(line) => yield line,
                    Err(e) => {
                        tracing::error!("Build error: {e}");
                        break;
                    }
                }
            }

            // Clean up context dir.
            let _ = tokio::fs::remove_dir_all(&context_dir).await;
        };

        Box::pin(stream)
    }

    /// Deletes the d:spatch runtime image.
    pub async fn delete_runtime_image(&self) -> Result<()> {
        self.guard(self.client.remove_image(RUNTIME_IMAGE_TAG, true))
            .await
    }

    // ── Container management ──

    /// Lists all d:spatch-managed containers.
    pub async fn list_containers(&self) -> Result<Vec<ContainerSummary>> {
        let mut filters = HashMap::new();
        filters.insert(
            "label".to_string(),
            vec![format!("{DSPATCH_CONTAINER_LABEL}=true")],
        );
        self.guard(self.client.list_containers(true, Some(&filters)))
            .await
    }

    /// Stops a container by `id`.
    pub async fn stop_container(&self, id: &str) -> Result<()> {
        self.guard(self.client.stop_container(id, 10)).await
    }

    /// Removes a container by `id`.
    pub async fn remove_container(&self, id: &str) -> Result<()> {
        self.guard(self.client.remove_container(id, true)).await
    }

    /// Stops all running d:spatch containers. Returns the count stopped.
    pub async fn stop_all_containers(&self) -> Result<i32> {
        let containers = self.list_containers().await?;
        let running: Vec<_> = containers
            .iter()
            .filter(|c| c.state == CONTAINER_STATE_RUNNING)
            .collect();
        let count = running.len() as i32;
        for c in running {
            if let Err(e) = self.client.stop_container(&c.id, 10).await {
                tracing::warn!("Failed to stop container {}: {e}", &c.id[..12.min(c.id.len())]);
            }
        }
        Ok(count)
    }

    /// Removes all stopped d:spatch containers. Returns the count removed.
    pub async fn delete_stopped_containers(&self) -> Result<i32> {
        let containers = self.list_containers().await?;
        let stopped: Vec<_> = containers
            .iter()
            .filter(|c| c.state != CONTAINER_STATE_RUNNING)
            .collect();
        let count = stopped.len() as i32;
        for c in stopped {
            if let Err(e) = self.client.remove_container(&c.id, true).await {
                tracing::warn!("Failed to remove container {}: {e}", &c.id[..12.min(c.id.len())]);
            }
        }
        Ok(count)
    }

    /// Removes orphaned containers (stopped, no matching active session).
    /// Currently treats all stopped containers as orphaned.
    pub async fn clean_orphaned(&self) -> Result<i32> {
        self.delete_stopped_containers().await
    }

    // ── Error mapping ──

    /// Wraps a Docker CLI future, mapping `DockerCliException` to `AppError::Docker`.
    async fn guard<T>(
        &self,
        future: impl std::future::Future<Output = std::result::Result<T, crate::docker::DockerCliException>>,
    ) -> Result<T> {
        future
            .await
            .map_err(|e| AppError::Docker(e.to_string()))
    }
}

#[async_trait]
impl DockerService for LocalDockerService {
    async fn detect_status(&self) -> Result<DockerStatus> {
        self.detect_status().await
    }

    fn build_runtime_image(&self) -> Pin<Box<dyn futures::Stream<Item = String> + Send>> {
        self.build_runtime_image()
    }

    async fn delete_runtime_image(&self) -> Result<()> {
        self.delete_runtime_image().await
    }

    async fn list_containers(&self) -> Result<Vec<ContainerSummary>> {
        self.list_containers().await
    }

    async fn stop_container(&self, id: &str) -> Result<()> {
        self.stop_container(id).await
    }

    async fn remove_container(&self, id: &str) -> Result<()> {
        self.remove_container(id).await
    }

    async fn stop_all_containers(&self) -> Result<i32> {
        self.stop_all_containers().await
    }

    async fn delete_stopped_containers(&self) -> Result<i32> {
        self.delete_stopped_containers().await
    }

    async fn clean_orphaned(&self) -> Result<i32> {
        self.clean_orphaned().await
    }
}
