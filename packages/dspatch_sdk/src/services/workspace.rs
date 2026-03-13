// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local workspace service — wraps WorkspaceDao with config parsing.

use std::path::Path;
use std::sync::Arc;

use futures::StreamExt;

use tokio::sync::Mutex as TokioMutex;

use crate::db::dao::WorkspaceDao;
use crate::domain::models::{CreateWorkspaceRequest, Workspace, WorkspaceRun};
use crate::domain::services::WatchStream;
use crate::server::workspace_bridge::WorkspaceBridge;
use crate::util::error::AppError;
use crate::util::new_id;
use crate::util::result::Result;
use crate::workspace_config::parser;
use crate::workspace_config::validation;

/// Local workspace service backed by [`WorkspaceDao`].
///
/// Handles workspace CRUD with full config parsing, validation, and disk write.
/// Lifecycle operations (launch/stop) are delegated to [`WorkspaceBridge`]
/// once wired up by the facade.
pub struct LocalWorkspaceService {
    dao: Arc<WorkspaceDao>,
    bridge: Arc<TokioMutex<Option<WorkspaceBridge>>>,
}

impl LocalWorkspaceService {
    pub fn new(dao: Arc<WorkspaceDao>, bridge: Arc<TokioMutex<Option<WorkspaceBridge>>>) -> Self {
        Self { dao, bridge }
    }

    // ── Workspace CRUD ──

    /// Watches all workspaces.
    pub fn watch_workspaces(&self) -> WatchStream<Vec<Workspace>> {
        let stream = self.dao.watch_workspaces();
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspaces error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches a single workspace by `id`.
    pub fn watch_workspace(&self, id: &str) -> WatchStream<Option<Workspace>> {
        let stream = self.dao.watch_workspace(id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspace error: {e}");
                    None
                }
            }
        }))
    }

    /// Returns the workspace with the given `id`.
    pub async fn get_workspace(&self, id: &str) -> Result<Workspace> {
        self.dao.get_workspace(id)
    }

    /// Creates a new workspace from `request`.
    ///
    /// 1. Parses config YAML into WorkspaceConfig.
    /// 2. Validates the config structure.
    /// 3. Ensures the project directory exists.
    /// 4. Writes `dspatch.workspace.yml` to the project directory.
    /// 5. Creates `.dspatch/templates/` directory.
    /// 6. Inserts the workspace row in the database.
    pub async fn create_workspace(
        &self,
        request: CreateWorkspaceRequest,
    ) -> Result<Workspace> {
        // 1. Parse configYaml
        let config = parser::parse_workspace_config(&request.config_yaml)
            .map_err(|e| AppError::Validation(format!("Invalid workspace config: {e}")))?;

        // 2. Validate config structure
        let errors = validation::validate_config(&config);
        if !errors.is_empty() {
            let msg = errors
                .iter()
                .map(|e| e.message.as_str())
                .collect::<Vec<_>>()
                .join("; ");
            return Err(AppError::Validation(format!(
                "Invalid workspace config: {msg}"
            )));
        }

        // 3. Ensure project directory exists
        let project_path = Path::new(&request.project_path);
        if !project_path.exists() {
            tokio::fs::create_dir_all(project_path)
                .await
                .map_err(|e| {
                    AppError::Storage(format!(
                        "Failed to create project directory: {e}"
                    ))
                })?;
        }

        // 4. Write dspatch.workspace.yml
        parser::write_workspace_config(project_path, &config).map_err(|e| {
            AppError::Storage(format!("Failed to write workspace config: {e}"))
        })?;

        // 5. Create .dspatch/templates/ directory
        let templates_dir = project_path.join(".dspatch").join("templates");
        if !templates_dir.exists() {
            tokio::fs::create_dir_all(&templates_dir)
                .await
                .map_err(|e| {
                    AppError::Storage(format!(
                        "Failed to create templates directory: {e}"
                    ))
                })?;
        }

        // 6. Insert workspace row
        let id = new_id();
        let now = chrono::Utc::now().naive_utc();
        let workspace = Workspace {
            id: id.clone(),
            name: config.name,
            project_path: request.project_path,
            created_at: now,
            updated_at: now,
        };
        self.dao.insert_workspace(&workspace)?;

        self.dao.get_workspace(&id)
    }

    /// Deletes the workspace with `id` and all associated data.
    pub async fn delete_workspace(&self, id: &str) -> Result<()> {
        self.dao.delete_workspace(id)
    }

    /// Watches runs for a workspace.
    pub fn watch_workspace_runs(&self, workspace_id: &str) -> WatchStream<Vec<WorkspaceRun>> {
        let stream = self.dao.watch_workspace_runs(workspace_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspace_runs error: {e}");
                    None
                }
            }
        }))
    }

    // ── Lifecycle ──

    /// Launches the workspace container via [`WorkspaceBridge`].
    pub async fn launch_workspace(&self, id: &str) -> Result<()> {
        let guard = self.bridge.lock().await;
        let bridge = guard.as_ref().ok_or_else(|| {
            AppError::Server("Workspace bridge not wired up yet".to_string())
        })?;
        bridge.launch_workspace(id).await
    }

    /// Stops the workspace container via [`WorkspaceBridge`].
    pub async fn stop_workspace(&self, id: &str) -> Result<()> {
        let guard = self.bridge.lock().await;
        let bridge = guard.as_ref().ok_or_else(|| {
            AppError::Server("Workspace bridge not wired up yet".to_string())
        })?;
        bridge.stop_workspace(id).await
    }

    // ── Run History Management ──

    /// Deletes a single workspace run and all its child data.
    pub fn delete_workspace_run(&self, run_id: &str) -> Result<()> {
        self.dao.delete_workspace_run(run_id)
    }

    /// Deletes all non-active (stopped/failed) runs for a workspace.
    pub fn delete_non_active_runs(&self, workspace_id: &str) -> Result<()> {
        self.dao.delete_non_active_runs(workspace_id)
    }
}
