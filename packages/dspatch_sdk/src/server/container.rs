// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker container lifecycle operations.
//!
//! Ported from `server/container_service.dart`.

use std::collections::{HashMap, HashSet};
use std::sync::Arc;
use std::time::Duration;

use futures::StreamExt;
use tokio::sync::Mutex;

use crate::docker::{
    ContainerInspect, CreateContainerRequest, DeviceRequest, DockerClient, HostConfig, PortBinding,
};

/// Configuration for launching a container.
///
/// All env vars decrypted, mounts validated, platform settings determined.
#[derive(Debug, Clone)]
pub struct LaunchContainerConfig {
    pub image: String,
    pub container_name: String,
    pub entrypoint: Vec<String>,
    pub env: Vec<String>,
    pub binds: Vec<String>,
    pub labels: HashMap<String, String>,
    pub privileged: bool,
    pub runtime: Option<String>,
    pub extra_hosts: Vec<String>,
    pub memory: Option<i64>,
    pub nano_cpus: Option<i64>,
    pub network_mode: String,
    pub port_bindings: HashMap<String, Vec<PortBinding>>,
    pub exposed_ports: HashMap<String, serde_json::Value>,
    pub device_requests: Option<Vec<DeviceRequest>>,
}

impl Default for LaunchContainerConfig {
    fn default() -> Self {
        Self {
            image: String::new(),
            container_name: String::new(),
            entrypoint: vec!["/entrypoint.sh".to_string()],
            env: Vec::new(),
            binds: Vec::new(),
            labels: HashMap::new(),
            privileged: false,
            runtime: None,
            extra_hosts: Vec::new(),
            memory: None,
            nano_cpus: None,
            network_mode: "bridge".to_string(),
            port_bindings: HashMap::new(),
            exposed_ports: HashMap::new(),
            device_requests: None,
        }
    }
}

// ── Callback types ──────────────────────────────────────────────────

pub type ContainerStartedFn =
    Arc<dyn Fn(&str, &str) + Send + Sync>;

pub type ContainerExitedFn =
    Arc<dyn Fn(&str, &str, i32) + Send + Sync>;

pub type ContainerLogLineFn =
    Arc<dyn Fn(&str, &str, &str) + Send + Sync>;

pub type HealthCheckFailedFn =
    Arc<dyn Fn(&str, &str, &str) + Send + Sync>;

/// Pure Docker container lifecycle operations.
///
/// Handles creating, starting, stopping, killing, removing, and inspecting
/// containers. Does NOT manage workspace/agent status.
pub struct ContainerService {
    docker_client: Arc<DockerClient>,

    pub on_container_started: Mutex<Option<ContainerStartedFn>>,
    pub on_container_exited: Mutex<Option<ContainerExitedFn>>,
    pub on_container_log_line: Mutex<Option<ContainerLogLineFn>>,
    pub on_health_check_failed: Mutex<Option<HealthCheckFailedFn>>,

    /// Active log stream tasks: workspace_id -> JoinHandle
    log_handles: Mutex<HashMap<String, tokio::task::JoinHandle<()>>>,
    /// Active health check tasks: workspace_id -> JoinHandle
    health_handles: Mutex<HashMap<String, tokio::task::JoinHandle<()>>>,
}

impl ContainerService {
    pub fn new(docker_client: Arc<DockerClient>) -> Self {
        Self {
            docker_client,
            on_container_started: Mutex::new(None),
            on_container_exited: Mutex::new(None),
            on_container_log_line: Mutex::new(None),
            on_health_check_failed: Mutex::new(None),
            log_handles: Mutex::new(HashMap::new()),
            health_handles: Mutex::new(HashMap::new()),
        }
    }

    // ── Container lifecycle ──

    /// Creates and starts a container. Returns the container ID.
    pub async fn launch_container(
        &self,
        workspace_id: &str,
        config: &LaunchContainerConfig,
    ) -> Result<String, String> {
        let request = CreateContainerRequest {
            image: config.image.clone(),
            entrypoint: Some(config.entrypoint.clone()),
            env: config.env.clone(),
            exposed_ports: config.exposed_ports.clone(),
            host_config: Some(HostConfig {
                binds: config.binds.clone(),
                privileged: config.privileged,
                runtime: config.runtime.clone(),
                auto_remove: false,
                extra_hosts: config.extra_hosts.clone(),
                memory: config.memory,
                nano_cpus: config.nano_cpus,
                network_mode: Some(config.network_mode.clone()),
                port_bindings: config.port_bindings.clone(),
                device_requests: config.device_requests.clone(),
            }),
            labels: config.labels.clone(),
        };

        let container_id = self
            .docker_client
            .create_container(&request, Some(&config.container_name))
            .await
            .map_err(|e| format!("Failed to create container: {e}"))?;

        tracing::info!(
            container_id = &container_id[..8.min(container_id.len())],
            workspace_id,
            "Container created"
        );

        self.docker_client
            .start_container(&container_id)
            .await
            .map_err(|e| format!("Failed to start container: {e}"))?;

        tracing::info!(
            container_id = &container_id[..8.min(container_id.len())],
            "Container started"
        );

        let cb = self.on_container_started.lock().await;
        if let Some(ref cb) = *cb {
            cb(workspace_id, &container_id);
        }

        Ok(container_id)
    }

    /// Gracefully stops a running container.
    pub async fn stop_container(
        &self,
        workspace_id: &str,
        container_id: &str,
        wait_seconds: u32,
    ) -> Result<(), String> {
        self.stop_monitoring(workspace_id).await;

        self.docker_client
            .stop_container(container_id, wait_seconds)
            .await
            .map_err(|e| {
                let short_id = &container_id[..8.min(container_id.len())];
                tracing::warn!(short_id, error = %e, "Container stop failed");
                format!("Container stop failed: {e}")
            })?;

        tracing::info!(
            container_id = &container_id[..8.min(container_id.len())],
            "Container stopped"
        );
        Ok(())
    }

    /// Forcefully kills a container.
    pub async fn kill_container(
        &self,
        workspace_id: &str,
        container_id: &str,
    ) -> Result<(), String> {
        self.stop_monitoring(workspace_id).await;

        self.docker_client
            .kill_container(container_id)
            .await
            .map_err(|e| {
                let short_id = &container_id[..8.min(container_id.len())];
                tracing::warn!(short_id, error = %e, "Container kill failed");
                format!("Container kill failed: {e}")
            })?;

        tracing::info!(
            container_id = &container_id[..8.min(container_id.len())],
            "Container killed"
        );
        Ok(())
    }

    /// Removes a container (optionally force).
    pub async fn remove_container(
        &self,
        container_id: &str,
        force: bool,
    ) -> Result<(), String> {
        self.docker_client
            .remove_container(container_id, force)
            .await
            .map_err(|e| {
                let short_id = &container_id[..8.min(container_id.len())];
                tracing::warn!(short_id, error = %e, "Container removal failed");
                format!("Container removal failed: {e}")
            })?;

        tracing::info!(
            container_id = &container_id[..8.min(container_id.len())],
            "Container removed"
        );
        Ok(())
    }

    /// Returns the inspection result for a container.
    pub async fn inspect_container(
        &self,
        container_id: &str,
    ) -> Result<ContainerInspect, String> {
        self.docker_client
            .inspect_container(container_id)
            .await
            .map_err(|e| format!("Inspect failed: {e}"))
    }

    /// Returns whether a container is currently running.
    pub async fn is_container_running(
        &self,
        container_id: &str,
    ) -> bool {
        match self.docker_client.inspect_container(container_id).await {
            Ok(inspect) => inspect
                .state
                .map(|s| s.running)
                .unwrap_or(false),
            Err(_) => false,
        }
    }

    // ── Orphan cleanup ──

    /// Finds containers with `com.dspatch.managed=true` not in
    /// activeWorkspaceIds and removes them. Returns count cleaned.
    pub async fn cleanup_orphans(
        &self,
        active_workspace_ids: &HashSet<String>,
    ) -> usize {
        let mut filters = HashMap::new();
        filters.insert(
            "label".to_string(),
            vec!["com.dspatch.managed=true".to_string()],
        );

        let containers = match self
            .docker_client
            .list_containers(true, Some(&filters))
            .await
        {
            Ok(c) => c,
            Err(_) => return 0,
        };

        let mut cleaned = 0;
        for container in containers {
            if !container.labels.get("com.dspatch.workspace")
                .map_or(false, |id| active_workspace_ids.contains(id))
            {
                match self
                    .docker_client
                    .remove_container(&container.id, true)
                    .await
                {
                    Ok(_) => {
                        cleaned += 1;
                        tracing::info!(
                            container_id = &container.id[..8.min(container.id.len())],
                            "Removed orphan container"
                        );
                    }
                    Err(e) => {
                        tracing::warn!(
                            container_id = &container.id[..8.min(container.id.len())],
                            error = %e,
                            "Failed to remove orphan container"
                        );
                    }
                }
            }
        }

        if cleaned > 0 {
            tracing::info!(cleaned, "Cleaned up orphan container(s)");
        }

        cleaned
    }

    // ── Monitoring ──

    /// Starts streaming `docker logs --follow` for a container.
    pub async fn start_log_stream(
        &self,
        workspace_id: &str,
        container_id: &str,
    ) {
        // Cancel any existing log stream for this workspace.
        if let Some(handle) = self.log_handles.lock().await.remove(workspace_id) {
            handle.abort();
        }

        let ws_id = workspace_id.to_string();
        let c_id = container_id.to_string();
        let on_log = self.on_container_log_line.lock().await.clone();
        let docker = Arc::clone(&self.docker_client);

        let handle = tokio::spawn(async move {
            let stream = docker.container_logs(&c_id, true);
            tokio::pin!(stream);
            while let Some(result) = stream.next().await {
                match result {
                    Ok(line) => {
                        if let Some(ref cb) = on_log {
                            cb(&ws_id, &c_id, &line);
                        }
                    }
                    Err(e) => {
                        tracing::warn!(
                            container_id = &c_id[..8.min(c_id.len())],
                            error = %e,
                            "Container log stream error"
                        );
                        break;
                    }
                }
            }
        });

        self.log_handles
            .lock()
            .await
            .insert(workspace_id.to_string(), handle);
    }

    /// Starts periodic health checks via `docker inspect`.
    pub async fn start_health_check(
        &self,
        workspace_id: &str,
        container_id: &str,
    ) {
        if let Some(handle) = self
            .health_handles
            .lock()
            .await
            .remove(workspace_id)
        {
            handle.abort();
        }

        let ws_id = workspace_id.to_string();
        let c_id = container_id.to_string();
        let on_exited = self.on_container_exited.lock().await.clone();
        let on_failed = self.on_health_check_failed.lock().await.clone();
        let docker = Arc::clone(&self.docker_client);

        let handle = tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(10));
            loop {
                interval.tick().await;
                match docker.inspect_container(&c_id).await {
                    Ok(inspect) => {
                        if let Some(ref state) = inspect.state {
                            if !state.running {
                                tracing::warn!(
                                    exit_code = state.exit_code,
                                    workspace_id = ws_id.as_str(),
                                    "Container exited"
                                );
                                if let Some(ref cb) = on_exited {
                                    cb(&ws_id, &c_id, state.exit_code);
                                }
                                break;
                            }
                        }
                    }
                    Err(e) => {
                        tracing::warn!(
                            container_id = &c_id[..8.min(c_id.len())],
                            error = %e,
                            "Container health check failed"
                        );
                        if let Some(ref cb) = on_failed {
                            cb(&ws_id, &c_id, &e.to_string());
                        }
                    }
                }
            }
        });

        self.health_handles
            .lock()
            .await
            .insert(workspace_id.to_string(), handle);
    }

    /// Cancels log streaming and health checks for a workspace.
    pub async fn stop_monitoring(&self, workspace_id: &str) {
        if let Some(handle) = self.log_handles.lock().await.remove(workspace_id) {
            handle.abort();
        }
        if let Some(handle) = self
            .health_handles
            .lock()
            .await
            .remove(workspace_id)
        {
            handle.abort();
        }
    }

    /// Disposes all monitoring resources.
    pub async fn dispose(&self) {
        let mut logs = self.log_handles.lock().await;
        for (_, handle) in logs.drain() {
            handle.abort();
        }
        let mut health = self.health_handles.lock().await;
        for (_, handle) in health.drain() {
            handle.abort();
        }
    }
}
