// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use async_trait::async_trait;
use serde::{Deserialize, Serialize};

use std::pin::Pin;

use futures::Stream;

use crate::domain::models::DockerStatus;
use crate::util::result::Result;

/// A boxed, pinned, Send stream for build log output.
type LogStream<T> = Pin<Box<dyn Stream<Item = T> + Send>>;

/// Lightweight container listing from Docker's `GET /containers/json`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContainerSummary {
    #[serde(default)]
    pub id: String,
    #[serde(default)]
    pub names: Vec<String>,
    #[serde(default)]
    pub image: String,
    #[serde(default)]
    pub state: String,
    #[serde(default)]
    pub status: String,
    #[serde(default)]
    pub labels: HashMap<String, String>,
    #[serde(default)]
    pub created: i64,
}

/// Abstract interface for Docker Engine operations.
///
/// Scoped to what the Engine screen and session management need.
/// SaaS mode can override this to skip local Docker entirely.
#[async_trait]
pub trait DockerService: Send + Sync {
    /// Detects Docker daemon status: reachable, Sysbox available, runtime image exists.
    async fn detect_status(&self) -> Result<DockerStatus>;

    /// Builds the d:spatch runtime image. Returns a stream of build log lines.
    fn build_runtime_image(&self) -> LogStream<String>;

    /// Deletes the d:spatch runtime image.
    async fn delete_runtime_image(&self) -> Result<()>;

    /// Lists all d:spatch-managed containers.
    async fn list_containers(&self) -> Result<Vec<ContainerSummary>>;

    /// Stops a container by `id`.
    async fn stop_container(&self, id: &str) -> Result<()>;

    /// Removes a container by `id`.
    async fn remove_container(&self, id: &str) -> Result<()>;

    /// Stops all running d:spatch containers. Returns the count stopped.
    async fn stop_all_containers(&self) -> Result<i32>;

    /// Removes all stopped d:spatch containers. Returns the count removed.
    async fn delete_stopped_containers(&self) -> Result<i32>;

    /// Removes orphaned containers (stopped, no matching active session).
    /// Returns the count removed.
    async fn clean_orphaned(&self) -> Result<i32>;
}
