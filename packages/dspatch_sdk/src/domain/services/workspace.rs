// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::{CreateWorkspaceRequest, Workspace};
use crate::util::result::Result;

/// CRUD and lifecycle operations for multi-agent workspaces.
///
/// A workspace maps to a single Docker container running the dspatch engine
/// with one or more agents.
#[async_trait]
pub trait WorkspaceService: Send + Sync {
    // -- Workspace CRUD --

    /// Returns the workspace with the given `id`.
    async fn get_workspace(&self, id: &str) -> Result<Workspace>;

    /// Creates a new workspace from `request`. Returns the created workspace
    /// with a generated UUID and timestamps.
    async fn create_workspace(&self, request: CreateWorkspaceRequest) -> Result<Workspace>;

    /// Deletes the workspace with `id` and all associated data.
    async fn delete_workspace(&self, id: &str) -> Result<()>;

    // -- Lifecycle --

    /// Launches the workspace container.
    async fn launch_workspace(&self, id: &str) -> Result<()>;

    /// Stops the workspace container.
    async fn stop_workspace(&self, id: &str) -> Result<()>;
}
