// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Workspace lifecycle orchestration: launch, stop, recovery.
//!
//! Mirrors the Dart `WorkspaceBridge`:
//! - Per-workspace startup monitoring (2 min timeout)
//! - Per-workspace lifecycle monitoring (docker logs + health polling)
//! - Recovery on app restart (re-register API keys, inspect containers)
//!
//! Ported from `server/workspace_bridge.dart`.

use std::collections::{HashMap, HashSet};
use std::path::Path;
use std::sync::{Arc, OnceLock};
use std::time::Duration;

use chrono::Utc;
use futures::StreamExt;
use regex_lite::Regex;
use tokio::sync::Mutex;
use tokio::task::JoinHandle;

use crate::crypto::aes_gcm::AesGcmCrypto;
use crate::db::dao::{PreferenceDao, WorkspaceDao};
use crate::docker::{
    CreateContainerRequest, DeviceRequest, DockerClient, HostConfig, PortBinding,
    DSPATCH_CONTAINER_LABEL, RUNTIME_IMAGE_TAG,
};
use crate::domain::enums::{AgentState, LogLevel, LogSource, SourceType};
use crate::domain::models::{AgentLog, WorkspaceRun};
use crate::domain::services::{AgentProviderService, ApiKeyService, DockerService};
use crate::server::packages::*;
use crate::services::LocalAgentDataService;
use crate::util::error::AppError;
use crate::util::new_id;
use crate::util::result::Result;
use crate::workspace_config::config::{AgentConfig, WorkspaceConfig};
use crate::workspace_config::env_resolver;
use crate::workspace_config::flat_agent::flatten_agent_hierarchy;
use crate::workspace_config::parser;

use super::agent_server::EmbeddedAgentServer;

// ── Constants ──────────────────────────────────────────────────────────

/// Crypto context for API key encryption/decryption.
const API_KEY_CRYPTO_CONTEXT: &str = "api_key";

/// Preference key for saved server port.
const PREF_SERVER_PORT: &str = "server_port";

/// Maximum attempts to start the embedded server.
const SERVER_START_MAX_ATTEMPTS: u32 = 3;

/// Delay between server start retries.
const SERVER_RETRY_DELAY: Duration = Duration::from_millis(500);

/// Startup monitor timeout (2 minutes).
const STARTUP_TIMEOUT: Duration = Duration::from_secs(120);

/// Container health check polling interval (30 seconds).
const HEALTH_CHECK_INTERVAL: Duration = Duration::from_secs(30);

// ── TemplateMountInfo ──────────────────────────────────────────────────

/// Holds resolved source / mount info for a single agent template.
struct TemplateMountInfo {
    source_type: SourceType,
    host_path: Option<String>,
    git_url: Option<String>,
    git_branch: Option<String>,
    required_mounts: Vec<String>,
}

// ── WorkspaceBridge ────────────────────────────────────────────────────

/// Orchestrates workspace lifecycle: launch, stop, recovery.
pub struct WorkspaceBridge {
    server: Arc<tokio::sync::Mutex<EmbeddedAgentServer>>,
    workspace_dao: Arc<WorkspaceDao>,
    agent_provider_service: Arc<dyn AgentProviderService>,
    api_key_service: Arc<dyn ApiKeyService>,
    crypto: Arc<AesGcmCrypto>,
    docker_client: Arc<DockerClient>,
    docker_service: Arc<dyn DockerService>,
    preference_dao: Arc<PreferenceDao>,
    agent_data: Arc<LocalAgentDataService>,

    startup_monitors: Mutex<HashMap<String, JoinHandle<()>>>,
    lifecycle_monitors: Mutex<HashMap<String, LifecycleMonitorHandles>>,
}

/// Handles for the lifecycle monitor tasks.
struct LifecycleMonitorHandles {
    log_handle: JoinHandle<()>,
    health_handle: JoinHandle<()>,
    run_status_handle: JoinHandle<()>,
}

impl WorkspaceBridge {
    pub fn new(
        server: Arc<tokio::sync::Mutex<EmbeddedAgentServer>>,
        workspace_dao: Arc<WorkspaceDao>,
        agent_provider_service: Arc<dyn AgentProviderService>,
        api_key_service: Arc<dyn ApiKeyService>,
        crypto: Arc<AesGcmCrypto>,
        docker_client: Arc<DockerClient>,
        docker_service: Arc<dyn DockerService>,
        preference_dao: Arc<PreferenceDao>,
        agent_data: Arc<LocalAgentDataService>,
    ) -> Self {
        Self {
            server,
            workspace_dao,
            agent_provider_service,
            api_key_service,
            crypto,
            docker_client,
            docker_service,
            preference_dao,
            agent_data,
            startup_monitors: Mutex::new(HashMap::new()),
            lifecycle_monitors: Mutex::new(HashMap::new()),
        }
    }

    // ── Launch ──────────────────────────────────────────────────────────

    /// Launch a workspace: read config -> validate -> build container -> start -> monitor.
    pub async fn launch_workspace(&self, workspace_id: &str) -> Result<()> {
        // 1. Load workspace from DB and check no active run exists.
        let workspace = self.workspace_dao.get_workspace(workspace_id)?;
        let existing_run = self.workspace_dao.get_active_run(workspace_id)?;

        if existing_run.is_some() {
            return Err(AppError::Validation(
                "Cannot launch workspace -- a run is already active".into(),
            ));
        }

        // 2. Read and parse dspatch.workspace.yml from project path.
        let project_path = Path::new(&workspace.project_path);
        let config = parser::parse_workspace_config_file(project_path)
            .map_err(|e| AppError::Validation(format!("Invalid workspace config: {e}")))?;

        // 3. Validate Docker readiness.
        let docker_status = self
            .docker_service
            .detect_status()
            .await?;

        if !docker_status.is_running {
            return Err(AppError::Docker(
                "Docker is not running. Start Docker Desktop and try again.".into(),
            ));
        }
        if !docker_status.has_runtime_image {
            return Err(AppError::Validation(
                "Runtime image not built. Build it from the Engine tab.".into(),
            ));
        }
        if config.docker.gpu && !docker_status.has_nvidia_runtime {
            return Err(AppError::Validation(
                "GPU passthrough requires the NVIDIA Container Toolkit. \
                 Install it on the host and restart Docker."
                    .into(),
            ));
        }

        // 4. Resolve templates.
        let mut template_mounts: HashMap<String, TemplateMountInfo> = HashMap::new();
        let mut template_required_env: HashMap<String, Vec<String>> = HashMap::new();
        let mut template_fields: HashMap<String, HashMap<String, String>> = HashMap::new();
        self.resolve_templates(
            &config.agents,
            &mut template_mounts,
            &mut template_required_env,
            &mut template_fields,
        )
        .await?;

        // 4b. Validate required mounts.
        Self::validate_required_mounts(&config, &template_mounts)?;

        // 5. Resolve env vars.
        let merged_env_by_agent = env_resolver::resolve_for_launch(
            &config.env,
            &config.agents,
            &template_required_env,
        );
        let mut resolved_env_by_agent: HashMap<String, HashMap<String, String>> = HashMap::new();
        for (agent_key, env_map) in &merged_env_by_agent {
            let resolved = self
                .decrypt_api_key_placeholders(env_map, agent_key)
                .await?;
            resolved_env_by_agent.insert(agent_key.clone(), resolved);
        }

        // 6. Ensure embedded server is running.
        {
            let server = self.server.lock().await;
            if !server.is_running() {
                drop(server);
                self.start_server_with_retry().await?;
            }
        }

        // 7. Register agent hierarchy.
        let flat_agents = flatten_agent_hierarchy(&config);
        {
            let server = self.server.lock().await;
            if let Some(ref router) = server.host_router() {
                router.event_service.register_workspace(workspace_id, &flat_agents).await;
            }
        }

        // 8. Create WorkspaceRun row.
        let run_id = new_id();
        let run_number = self.workspace_dao.next_run_number(workspace_id)?;
        let now = Utc::now().naive_utc();
        let run = WorkspaceRun {
            id: run_id.clone(),
            workspace_id: workspace_id.to_string(),
            run_number,
            status: "starting".to_string(),
            container_id: None,
            server_port: None,
            api_key: None,
            started_at: now,
            stopped_at: None,
        };
        self.workspace_dao.insert_workspace_run(&run)?;

        // 8b. Register run with EventService.
        {
            let server = self.server.lock().await;
            if let Some(ref router) = server.host_router() {
                router.event_service.register_workspace_run(workspace_id, &run_id);
            }
        }

        // 8c. Generate per-run API key and register.
        let api_key = new_id();
        {
            let server = self.server.lock().await;
            server.register_run(&run_id, &api_key).await;
        }

        let mut launch_logs: Vec<String> = Vec::new();
        launch_logs.push("[launch] ════════════════════════════════════════".into());
        launch_logs.push("[launch] Workspace Launch Started".into());
        launch_logs.push("[launch] ════════════════════════════════════════".into());
        launch_logs.push(format!("[launch] Workspace ID: {workspace_id}"));
        launch_logs.push(format!("[launch] Name: {}", config.name));
        launch_logs.push(format!("[launch] Agents: {}", config.agents.len()));
        launch_logs.push(format!("[launch] Project: {}", workspace.project_path));

        let server_port = {
            let server = self.server.lock().await;
            server.port().unwrap_or(0)
        };
        launch_logs.push(format!("[launch] Server port: {server_port}"));

        // Build container in a block to handle errors and cleanup.
        let result = self
            .build_and_start_container(
                workspace_id,
                &run_id,
                &api_key,
                &config,
                &workspace.project_path,
                &resolved_env_by_agent,
                &template_mounts,
                &template_fields,
                &docker_status,
                server_port,
                &mut launch_logs,
            )
            .await;

        match result {
            Ok(container_id) => {
                // 14. Flush launch logs.
                launch_logs.push(
                    "[launch] ════════════════════════════════════════".into(),
                );
                for msg in &launch_logs {
                    let log = AgentLog {
                        id: new_id(),
                        run_id: run_id.clone(),
                        agent_key: "_system".to_string(),
                        instance_id: "_system".to_string(),
                        turn_id: None,
                        level: LogLevel::Info,
                        message: msg.clone(),
                        source: LogSource::Engine,
                        timestamp: Utc::now().naive_utc(),
                    };
                    let _ = self.workspace_dao.insert_agent_log(&log);
                }

                // 15. Start monitors.
                self.start_monitoring(workspace_id, &container_id, &run_id)
                    .await;

                tracing::info!(
                    workspace_id,
                    container_id = &container_id[..12.min(container_id.len())],
                    "Workspace launched"
                );
                Ok(())
            }
            Err(e) => {
                tracing::error!(%e, "Workspace launch failed");
                {
                    let server = self.server.lock().await;
                    if let Some(ref router) = server.host_router() {
                        router.event_service.deregister_workspace_run(workspace_id);
                    }
                    server.deregister_run(&run_id).await;
                }

                // Attempt to mark run failed.
                let _ = self.workspace_dao.update_run_status(
                    &run_id,
                    "failed",
                    Some(&Utc::now().naive_utc()),
                );
                Err(e)
            }
        }
    }

    /// Internal: builds and starts the container, returning the container ID.
    #[allow(clippy::too_many_arguments)]
    async fn build_and_start_container(
        &self,
        workspace_id: &str,
        run_id: &str,
        api_key: &str,
        config: &WorkspaceConfig,
        project_path: &str,
        resolved_env_by_agent: &HashMap<String, HashMap<String, String>>,
        template_mounts: &HashMap<String, TemplateMountInfo>,
        template_fields: &HashMap<String, HashMap<String, String>>,
        docker_status: &crate::domain::models::DockerStatus,
        server_port: u16,
        launch_logs: &mut Vec<String>,
    ) -> Result<String> {
        // Container env vars.
        let mut container_env = vec![
            format!("DSPATCH_API_URL=http://host.docker.internal:{server_port}"),
            format!("DSPATCH_API_KEY={api_key}"),
            format!("DSPATCH_WORKSPACE_ID={workspace_id}"),
            format!("DSPATCH_RUN_ID={run_id}"),
            "DSPATCH_WORKSPACE_DIR=/workspace".to_string(),
        ];

        if config.docker.gpu {
            container_env.push("DSPATCH_GPU_ENABLED=true".to_string());
        }

        // Resolved agent env vars.
        for (agent_key, env_map) in resolved_env_by_agent {
            if !env_map.is_empty() {
                let json = serde_json::to_string(env_map)
                    .unwrap_or_default();
                container_env.push(format!("DSPATCH_RESOLVED_ENV_{agent_key}={json}"));
            }
        }

        // Agent system metadata.
        let agents_meta = build_agents_meta(&config.agents, template_fields, true);
        let meta_json = serde_json::to_string(&agents_meta).unwrap_or_default();
        container_env.push(format!("DSPATCH_AGENTS_META={meta_json}"));

        // Build bind mounts.
        let workspace_dir = config
            .workspace_dir
            .as_ref()
            .filter(|s| !s.is_empty())
            .map(|s| s.as_str())
            .unwrap_or(project_path);

        let mut binds = vec![format!("{}:/workspace:rw", docker_path(workspace_dir))];

        // Home directory volume.
        {
            let home_volume_name = format!("dspatch-home-{workspace_id}");
            if self
                .docker_client
                .volume_exists(&home_volume_name)
                .await
                .unwrap_or(false)
            {
                let _ = self.docker_client.remove_volume(&home_volume_name).await;
                launch_logs.push(format!(
                    "[launch] Removed old home volume: {home_volume_name}"
                ));
            }
            let _ = self.docker_client.create_volume(&home_volume_name).await;
            binds.push(format!("{home_volume_name}:/root"));
            launch_logs.push(format!(
                "[launch] Home volume: {home_volume_name} -> /root"
            ));
            if let Some(ref home_size) = config.docker.home_size {
                launch_logs.push(format!(
                    "[launch] Home size hint: {home_size} (advisory)"
                ));
            }
        }

        // Mount template sources.
        let mut template_sources_map: HashMap<String, serde_json::Value> = HashMap::new();
        let mut used_dir_names: HashSet<String> = HashSet::new();

        for (template_name, info) in template_mounts {
            let mut dir_name = if info.source_type == SourceType::Local {
                info.host_path
                    .as_deref()
                    .unwrap_or("")
                    .replace('\\', "/")
                    .rsplit('/')
                    .next()
                    .unwrap_or("")
                    .to_string()
            } else {
                dir_name_from_git_url(info.git_url.as_deref().unwrap_or(""))
            };

            // Disambiguate.
            if used_dir_names.contains(&dir_name) {
                let mut suffix = 2;
                loop {
                    let candidate = format!("{dir_name}_{suffix}");
                    if !used_dir_names.contains(&candidate) {
                        dir_name = candidate;
                        break;
                    }
                    suffix += 1;
                }
            }
            used_dir_names.insert(dir_name.clone());

            match info.source_type {
                SourceType::Local => {
                    let host = info.host_path.as_deref().unwrap_or("");
                    binds.push(format!(
                        "{}:/src/{dir_name}:ro",
                        docker_path(host)
                    ));
                    template_sources_map.insert(
                        template_name.clone(),
                        serde_json::json!({
                            "dir": dir_name,
                            "type": "local",
                            "src": format!("/src/{dir_name}"),
                        }),
                    );
                    launch_logs.push(format!(
                        "[launch] Template source (local): {template_name} -> {host}"
                    ));
                }
                SourceType::Git | SourceType::Hub => {
                    let git_url = info.git_url.as_deref().unwrap_or("");
                    let (clone_url, url_ref) = parse_git_url(git_url);
                    let branch = info
                        .git_branch
                        .as_ref()
                        .filter(|s| !s.is_empty())
                        .map(|s| s.as_str())
                        .or(url_ref);

                    let mut source = serde_json::json!({
                        "dir": dir_name,
                        "type": "git",
                        "url": clone_url,
                    });
                    if let Some(b) = branch {
                        source["branch"] = serde_json::Value::String(b.to_string());
                    }
                    template_sources_map.insert(template_name.clone(), source);

                    let type_label = if info.source_type == SourceType::Hub {
                        "hub->git"
                    } else {
                        "git"
                    };
                    launch_logs.push(format!(
                        "[launch] Template source ({type_label}): {template_name} -> {clone_url} (ref={branch:?})"
                    ));
                }
            }
        }
        container_env.push(format!(
            "DSPATCH_TEMPLATE_SOURCES={}",
            serde_json::to_string(&template_sources_map).unwrap_or_default()
        ));

        // Additional user-defined mounts.
        for mount in &config.mounts {
            let host_path = Path::new(&mount.host_path);
            if !host_path.exists() {
                return Err(AppError::Validation(format!(
                    "Mount host path does not exist: {}",
                    mount.host_path
                )));
            }
            let mode = if mount.read_only { "ro" } else { "rw" };
            binds.push(format!(
                "{}:{}:{mode}",
                docker_path(&mount.host_path),
                mount.container_path
            ));
            launch_logs.push(format!(
                "[launch] Custom mount: {} <- {} ({mode})",
                mount.container_path, mount.host_path
            ));
        }

        launch_logs.push(format!("[launch] Workspace dir: {workspace_dir}"));
        launch_logs.push(format!("[launch] Mounts: {} bind mounts", binds.len()));

        // 10. Platform-specific config.
        let is_linux = cfg!(target_os = "linux");
        let privileged;
        let runtime;
        let extra_hosts;

        if is_linux {
            privileged = !docker_status.has_sysbox;
            runtime = if docker_status.has_sysbox {
                Some("sysbox-runc".to_string())
            } else {
                None
            };
            extra_hosts = vec!["host.docker.internal:host-gateway".to_string()];
        } else {
            privileged = true;
            runtime = None;
            extra_hosts = vec![];
        }

        // 10b. Advanced Docker settings.
        let memory_bytes = config
            .docker
            .memory_limit
            .as_deref()
            .and_then(parse_memory_limit);
        let nano_cpus = config
            .docker
            .cpu_limit
            .map(|cpu| (cpu * 1e9) as i64);
        let network_mode = Some(config.docker.network_mode.clone());
        let device_requests = if config.docker.gpu {
            Some(vec![DeviceRequest {
                driver: "nvidia".to_string(),
                count: -1,
                capabilities: vec![vec!["gpu".to_string()]],
            }])
        } else {
            None
        };

        // 10c. Port mappings.
        let mut port_bindings: HashMap<String, Vec<PortBinding>> = HashMap::new();
        let mut exposed_ports: HashMap<String, serde_json::Value> = HashMap::new();
        let mut used_host_ports: HashSet<String> = HashSet::new();

        for port_spec in &config.docker.ports {
            let parts: Vec<&str> = port_spec.split(':').collect();
            if parts.len() != 2 {
                return Err(AppError::Validation(format!(
                    "Invalid port mapping \"{port_spec}\": expected \"hostPort:containerPort\""
                )));
            }
            let host_port = parts[0];
            let container_port_str = parts[1];

            let host_port_num: u16 = host_port.parse().map_err(|_| {
                AppError::Validation(format!(
                    "Invalid host port in \"{port_spec}\": must be 1-65535"
                ))
            })?;
            if host_port_num == 0 {
                return Err(AppError::Validation(format!(
                    "Invalid host port in \"{port_spec}\": must be 1-65535"
                )));
            }

            let container_port_num: u16 = container_port_str.parse().map_err(|_| {
                AppError::Validation(format!(
                    "Invalid container port in \"{port_spec}\": must be 1-65535"
                ))
            })?;
            if container_port_num == 0 {
                return Err(AppError::Validation(format!(
                    "Invalid container port in \"{port_spec}\": must be 1-65535"
                )));
            }

            if !used_host_ports.insert(host_port.to_string()) {
                return Err(AppError::Validation(format!(
                    "Duplicate host port {host_port} in port mappings"
                )));
            }

            let container_port = format!("{container_port_str}/tcp");
            port_bindings.insert(
                container_port.clone(),
                vec![PortBinding {
                    host_port: host_port.to_string(),
                    host_ip: String::new(),
                }],
            );
            exposed_ports.insert(container_port, serde_json::json!({}));
        }

        // 11. Create container.
        launch_logs.push("[launch] Creating container...".into());

        let short_id = &workspace_id[..8.min(workspace_id.len())];
        let container_config = CreateContainerRequest {
            image: RUNTIME_IMAGE_TAG.to_string(),
            entrypoint: Some(vec!["/entrypoint.sh".to_string()]),
            env: container_env,
            exposed_ports,
            host_config: Some(HostConfig {
                binds,
                privileged,
                runtime,
                auto_remove: false,
                extra_hosts,
                memory: memory_bytes,
                nano_cpus,
                network_mode,
                port_bindings,
                device_requests,
            }),
            labels: HashMap::from([
                (DSPATCH_CONTAINER_LABEL.to_string(), "true".to_string()),
                ("com.dspatch.workspace".to_string(), workspace_id.to_string()),
                ("com.dspatch.run".to_string(), run_id.to_string()),
            ]),
        };

        // Pre-cleanup: force-remove any stale container with the same name.
        let container_name = format!("dspatch-ws-{short_id}");
        let _ = self.docker_client.remove_container(&container_name, true).await;

        let container_id = self
            .docker_client
            .create_container(
                &container_config,
                Some(&container_name),
            )
            .await
            .map_err(|e| AppError::Docker(format!("Failed to create container: {e}")))?;

        launch_logs.push(format!(
            "[launch] Container created: {}",
            &container_id[..12.min(container_id.len())]
        ));

        // 12. Start container.
        self.docker_client
            .start_container(&container_id)
            .await
            .map_err(|e| AppError::Docker(format!("Failed to start container: {e}")))?;
        launch_logs.push("[launch] Container started".into());

        // 13. Store deployment info.
        self.workspace_dao.update_run_deployment(
            run_id,
            Some(&container_id),
            Some(server_port),
            Some(api_key),
        )?;

        Ok(container_id)
    }

    // ── Stop ────────────────────────────────────────────────────────────

    /// Stop a workspace: send terminate -> kill container -> cleanup.
    pub async fn stop_workspace(&self, workspace_id: &str) -> Result<()> {
        let active_run = self.workspace_dao.get_active_run(workspace_id)?;
        let active_run = active_run.ok_or_else(|| {
            AppError::Validation("Workspace is not running".into())
        })?;
        let run_id = &active_run.id;

        if active_run.status != "running" && active_run.status != "starting" {
            return Err(AppError::Validation(format!(
                "Cannot stop workspace in status: {}",
                active_run.status
            )));
        }

        // 1. Update run status -> stopping.
        self.workspace_dao
            .update_run_status(run_id, "stopping", None)?;

        // 2. Send terminate command to all connected instances.
        {
            let server = self.server.lock().await;
            if let Some(ref router) = server.host_router() {
                let agents = router.connection_service.connected_agents(run_id);
                for agent in &agents {
                    let instances = router.connection_service.connected_instances(run_id, agent);
                    if instances.is_empty() {
                        // No known instances for this agent — send a single terminate
                        // with empty instance_id so the agent can still shut down.
                        let pkg = Package::Terminate(TerminatePackage {
                            instance_id: String::new(),
                        });
                        let _ = router
                            .connection_service
                            .send_package_to_run(run_id, &pkg)
                            .await;
                    } else {
                        for instance_id in &instances {
                            let pkg = Package::Terminate(TerminatePackage {
                                instance_id: instance_id.clone(),
                            });
                            let _ = router
                                .connection_service
                                .send_package_to_run(run_id, &pkg)
                                .await;
                        }
                    }
                }
            }
        }

        // 3. Wait briefly for graceful shutdown.
        tokio::time::sleep(Duration::from_secs(5)).await;

        // 4. Kill and remove container (force-remove to avoid stale name conflicts).
        if let Some(ref container_id) = active_run.container_id {
            if let Err(e) = self.docker_client.kill_container(container_id).await {
                tracing::warn!(%e, "Container kill failed");
            }
            if let Err(e) = self.docker_client.remove_container(container_id, true).await {
                tracing::warn!(%e, "Container force-remove failed");
            }
        }

        // 5. Update run -> stopped.
        self.workspace_dao.update_run_status(
            run_id,
            "stopped",
            Some(&Utc::now().naive_utc()),
        )?;

        // 6. Mark all agents disconnected, cleanup, and deregister run.
        {
            let server = self.server.lock().await;
            if let Some(ref router) = server.host_router() {
                router
                    .status_service
                    .mark_all_agents_disconnected(workspace_id)
                    .await;
                router
                    .event_service
                    .remove_workspace(workspace_id)
                    .await;
            }
            server.deregister_run(run_id).await;
        }
        self.cancel_monitors(workspace_id).await;

        tracing::info!(workspace_id, "Workspace stopped");
        Ok(())
    }

    // ── Cleanup for deletion ────────────────────────────────────────────

    /// Stops and removes the container for a workspace being deleted.
    pub async fn cleanup_for_deletion(&self, workspace_id: &str) -> Result<()> {
        let active_run = self.workspace_dao.get_active_run(workspace_id)?;

        if let Some(active_run) = active_run {
            let run_id = &active_run.id;

            // Send terminate.
            {
                let server = self.server.lock().await;
                if let Some(ref router) = server.host_router() {
                    let agents = router.connection_service.connected_agents(run_id);
                    for agent in &agents {
                        let pkg = Package::Terminate(TerminatePackage {
                            instance_id: agent.clone(),
                        });
                        let _ = router
                            .connection_service
                            .send_package_to_run(run_id, &pkg)
                            .await;
                    }
                }
            }

            tokio::time::sleep(Duration::from_secs(2)).await;

            // Kill container.
            if let Some(ref container_id) = active_run.container_id {
                let _ = self.docker_client.kill_container(container_id).await;
                if let Err(e) = self.docker_client.remove_container(container_id, true).await {
                    tracing::warn!(%e, "Container removal failed");
                }
            }

            // Mark the run as stopped.
            let _ = self.workspace_dao.update_run_status(
                run_id,
                "stopped",
                Some(&Utc::now().naive_utc()),
            );

            // Deregister run and cleanup bridge state in a single lock.
            {
                let server = self.server.lock().await;
                server.deregister_run(run_id).await;
                if let Some(ref router) = server.host_router() {
                    router
                        .event_service
                        .remove_workspace(workspace_id)
                        .await;
                }
            }
        } else {
            // No active run — still cleanup bridge state.
            let server = self.server.lock().await;
            if let Some(ref router) = server.host_router() {
                router
                    .event_service
                    .remove_workspace(workspace_id)
                    .await;
            }
        }
        self.cancel_monitors(workspace_id).await;

        tracing::info!(workspace_id, "Workspace cleaned up for deletion");
        Ok(())
    }

    // ── Recovery ────────────────────────────────────────────────────────

    /// Recover active workspaces after app restart.
    pub async fn recover_active_workspaces(&self) -> Result<()> {
        {
            let server = self.server.lock().await;
            if !server.is_running() {
                drop(server);
                self.start_server_with_retry().await?;
            }
        }

        // Get all workspaces.
        let workspaces = {
            let mut stream = self.workspace_dao.watch_workspaces();
            stream.next().await
        };
        let workspaces = match workspaces {
            Some(Ok(ws)) => ws,
            Some(Err(e)) => {
                tracing::error!(%e, "Workspace recovery failed");
                return Ok(());
            }
            None => return Ok(()),
        };

        let mut recovered = 0u32;
        let mut failed = 0u32;

        for ws in &workspaces {
            let active_run = match self.workspace_dao.get_active_run(&ws.id) {
                Ok(Some(run)) => run,
                _ => continue,
            };

            let run_id = &active_run.id;
            let api_key = match &active_run.api_key {
                Some(key) => key.clone(),
                None => {
                    self.mark_run_failed(run_id, &ws.id, "No stored API key for recovery")
                        .await;
                    failed += 1;
                    continue;
                }
            };

            // Re-register auth and run tracking.
            {
                let server = self.server.lock().await;
                if let Some(ref router) = server.host_router() {
                    router
                        .event_service
                        .register_workspace_run(&ws.id, run_id);
                }
                server.register_run(run_id, &api_key).await;
            }

            let container_id = match &active_run.container_id {
                Some(id) => id.clone(),
                None => {
                    self.mark_run_failed(run_id, &ws.id, "No container ID for recovery")
                        .await;
                    failed += 1;
                    continue;
                }
            };

            match self.docker_client.inspect_container(&container_id).await {
                Ok(inspect) => {
                    let state = inspect.state.as_ref();
                    let is_running = state.map(|s| s.running).unwrap_or(false);
                    if is_running {
                        // Container alive -- restart monitors.
                        {
                            let server = self.server.lock().await;
                            if let Some(ref router) = server.host_router() {
                                router
                                    .status_service
                                    .mark_all_agents_disconnected(&ws.id)
                                    .await;
                            }
                        }

                        self.start_monitoring(&ws.id, &container_id, run_id)
                            .await;

                        // Re-register inquiry hierarchy.
                        match parser::parse_workspace_config_file(Path::new(&ws.project_path)) {
                            Ok(config) => {
                                let flat_agents = flatten_agent_hierarchy(&config);
                                let server = self.server.lock().await;
                                if let Some(ref router) = server.host_router() {
                                    router
                                        .event_service
                                        .register_workspace(&ws.id, &flat_agents)
                                        .await;
                                }
                            }
                            Err(e) => {
                                tracing::warn!(
                                    workspace_id = &ws.id[..8.min(ws.id.len())],
                                    %e,
                                    "Could not re-register inquiry hierarchy"
                                );
                            }
                        }

                        recovered += 1;
                        tracing::info!(
                            workspace_id = &ws.id[..8.min(ws.id.len())],
                            "Recovered workspace"
                        );
                    } else {
                        // Container dead.
                        if active_run.status == "stopping" {
                            let _ = self.workspace_dao.update_run_status(
                                run_id,
                                "stopped",
                                Some(&Utc::now().naive_utc()),
                            );
                        } else {
                            let exit_code = state.map(|s| s.exit_code).unwrap_or(-1);
                            self.mark_run_failed(
                                run_id,
                                &ws.id,
                                &format!("Container exited (code: {exit_code})"),
                            )
                            .await;
                        }
                        let server = self.server.lock().await;
                        server.deregister_run(run_id).await;
                        if let Some(ref router) = server.host_router() {
                            router
                                .event_service
                                .deregister_workspace_run(&ws.id);
                        }
                        failed += 1;
                    }
                }
                Err(e) => {
                    self.mark_run_failed(
                        run_id,
                        &ws.id,
                        &format!("Container not found: {e}"),
                    )
                    .await;
                    let server = self.server.lock().await;
                    server.deregister_run(run_id).await;
                    if let Some(ref router) = server.host_router() {
                        router
                            .event_service
                            .deregister_workspace_run(&ws.id);
                    }
                    failed += 1;
                }
            }
        }

        if recovered > 0 || failed > 0 {
            tracing::info!(
                recovered,
                failed,
                "Workspace recovery complete"
            );
        }

        Ok(())
    }

    /// Disposes all resources.
    pub async fn dispose(&self) {
        let mut startup = self.startup_monitors.lock().await;
        for (_, handle) in startup.drain() {
            handle.abort();
        }
        let mut lifecycle = self.lifecycle_monitors.lock().await;
        for (_, handles) in lifecycle.drain() {
            handles.log_handle.abort();
            handles.health_handle.abort();
            handles.run_status_handle.abort();
        }
    }

    // ── Private helpers ─────────────────────────────────────────────────

    async fn mark_run_failed(&self, run_id: &str, _workspace_id: &str, reason: &str) {
        let log = AgentLog {
            id: new_id(),
            run_id: run_id.to_string(),
            agent_key: "_system".to_string(),
            instance_id: "_system".to_string(),
            turn_id: None,
            level: LogLevel::Error,
            message: reason.to_string(),
            source: LogSource::Engine,
            timestamp: Utc::now().naive_utc(),
        };
        let _ = self.workspace_dao.insert_agent_log(&log);
        let _ = self.workspace_dao.update_run_status(
            run_id,
            "failed",
            Some(&Utc::now().naive_utc()),
        );
    }

    /// Validates that all `required_mounts` declared by templates are covered.
    fn validate_required_mounts(
        config: &WorkspaceConfig,
        template_mounts: &HashMap<String, TemplateMountInfo>,
    ) -> Result<()> {
        let mounted_paths: HashSet<&str> = config
            .mounts
            .iter()
            .map(|m| m.container_path.as_str())
            .collect();

        for (template_name, info) in template_mounts {
            for required in &info.required_mounts {
                if !required.is_empty() && !mounted_paths.contains(required.as_str()) {
                    return Err(AppError::Validation(format!(
                        "Template \"{template_name}\" requires mount at \"{required}\" \
                         but no matching mount is configured in the workspace."
                    )));
                }
            }
        }
        Ok(())
    }

    /// Resolve agent template references recursively.
    async fn resolve_templates(
        &self,
        agents: &HashMap<String, AgentConfig>,
        mounts: &mut HashMap<String, TemplateMountInfo>,
        template_required_env: &mut HashMap<String, Vec<String>>,
        template_fields: &mut HashMap<String, HashMap<String, String>>,
    ) -> Result<()> {
        for agent in agents.values() {
            if !mounts.contains_key(&agent.template) {
                let template = self
                    .agent_provider_service
                    .get_agent_provider_by_name(&agent.template)
                    .await?;
                let template = template.ok_or_else(|| {
                    AppError::Validation(format!(
                        "Agent provider not found: \"{}\"",
                        agent.template
                    ))
                })?;

                template_required_env
                    .entry(template.name.clone())
                    .or_insert_with(|| template.required_env.clone());
                template_fields
                    .entry(template.name.clone())
                    .or_insert_with(|| template.fields.clone());

                match template.source_type {
                    SourceType::Local => {
                        let source_path = template.source_path.as_deref().unwrap_or("");
                        if source_path.is_empty() {
                            return Err(AppError::Validation(format!(
                                "Template \"{}\" has no source path",
                                agent.template
                            )));
                        }
                        if !Path::new(source_path).is_dir() {
                            return Err(AppError::Validation(format!(
                                "Template source not found: {source_path}"
                            )));
                        }
                        mounts.insert(
                            agent.template.clone(),
                            TemplateMountInfo {
                                source_type: SourceType::Local,
                                host_path: Some(source_path.to_string()),
                                git_url: None,
                                git_branch: None,
                                required_mounts: template.required_mounts.clone(),
                            },
                        );
                    }
                    SourceType::Git => {
                        let git_url = template.git_url.as_deref().unwrap_or("");
                        if git_url.is_empty() {
                            return Err(AppError::Validation(format!(
                                "Template \"{}\" has no git URL",
                                agent.template
                            )));
                        }
                        mounts.insert(
                            agent.template.clone(),
                            TemplateMountInfo {
                                source_type: SourceType::Git,
                                host_path: None,
                                git_url: Some(git_url.to_string()),
                                git_branch: template.git_branch.clone(),
                                required_mounts: template.required_mounts.clone(),
                            },
                        );
                    }
                    SourceType::Hub => {
                        let hub_repo_url = template.hub_repo_url.as_deref().unwrap_or("");
                        if hub_repo_url.is_empty() {
                            return Err(AppError::Validation(format!(
                                "Hub template \"{}\" has no repository URL",
                                agent.template
                            )));
                        }
                        mounts.insert(
                            agent.template.clone(),
                            TemplateMountInfo {
                                source_type: SourceType::Hub,
                                host_path: None,
                                git_url: Some(hub_repo_url.to_string()),
                                git_branch: template.hub_commit_hash.clone(),
                                required_mounts: template.required_mounts.clone(),
                            },
                        );
                    }
                }
            }

            // Recurse into sub-agents.
            if !agent.sub_agents.is_empty() {
                Box::pin(self.resolve_templates(
                    &agent.sub_agents,
                    mounts,
                    template_required_env,
                    template_fields,
                ))
                .await?;
            }
        }
        Ok(())
    }

    /// Decrypts `{{apikey:Name}}` placeholders in an env map.
    async fn decrypt_api_key_placeholders(
        &self,
        env_map: &HashMap<String, String>,
        agent_path: &str,
    ) -> Result<HashMap<String, String>> {
        static API_KEY_RE: OnceLock<Regex> = OnceLock::new();
        let pattern = API_KEY_RE.get_or_init(|| Regex::new(r"\{\{apikey:(.+?)\}\}").unwrap());
        let mut resolved = HashMap::new();

        for (key, value) in env_map {
            if let Some(caps) = pattern.captures(value) {
                let key_name = &caps[1];
                let api_key = self
                    .api_key_service
                    .get_api_key_by_name(key_name)
                    .await?;
                let api_key = api_key.ok_or_else(|| {
                    AppError::Validation(format!(
                        "API key \"{key_name}\" not found (referenced by agent \"{agent_path}\")"
                    ))
                })?;

                let decrypted = match self
                    .crypto
                    .decrypt_string(&api_key.encrypted_key, API_KEY_CRYPTO_CONTEXT)
                    .await
                {
                    Ok(d) => d,
                    Err(AppError::SecureStorageFailure(_)) => return Err(AppError::SecureStorageFailure(
                        format!(
                            "Cannot decrypt API key \"{key_name}\". \
                             The encryption key may have changed."
                        ),
                    )),
                    Err(_) => return Err(AppError::SecureStorageFailure(
                        format!(
                            "Cannot decrypt API key \"{key_name}\". \
                             The encryption key may have changed."
                        ),
                    )),
                };

                let full_match = caps.get(0).unwrap().as_str();
                resolved.insert(
                    key.clone(),
                    value.replace(full_match, &decrypted),
                );
            } else {
                resolved.insert(key.clone(), value.clone());
            }
        }

        Ok(resolved)
    }

    /// Starts the embedded server with port-persistence and retry logic.
    ///
    /// After a successful start, wires the `send_user_input` and
    /// `interrupt_instance` callbacks on the `agent_data` service so that
    /// client API commands can relay messages to connected agents.
    async fn start_server_with_retry(&self) -> Result<u16> {
        {
            let server = self.server.lock().await;
            if server.is_running() {
                return Ok(server.port().ok_or_else(|| {
                    AppError::Server("Server running but port unavailable".into())
                })?);
            }
        }

        let saved_port = self.load_saved_port();
        let mut last_error = String::new();

        for attempt in 1..=SERVER_START_MAX_ATTEMPTS {
            let use_saved = saved_port.is_some() && attempt < SERVER_START_MAX_ATTEMPTS;
            let port_to_try = if use_saved {
                saved_port.unwrap_or(0)
            } else {
                0
            };

            let mut server = self.server.lock().await;
            match server.start(port_to_try, false).await {
                Ok(port) => {
                    if attempt > 1 {
                        tracing::info!(
                            attempt,
                            port,
                            "Server recovered"
                        );
                    }
                    // Wire agent_data callbacks now that the server is running.
                    self.wire_agent_data_callbacks(&server);
                    drop(server);
                    self.save_port(port);
                    return Ok(port);
                }
                Err(e) => {
                    last_error = e.clone();
                    tracing::warn!(
                        attempt,
                        max = SERVER_START_MAX_ATTEMPTS,
                        %e,
                        "Server bind attempt failed"
                    );
                    server.stop().await;
                    drop(server);

                    if attempt < SERVER_START_MAX_ATTEMPTS {
                        tokio::time::sleep(SERVER_RETRY_DELAY).await;
                    }
                }
            }
        }

        Err(AppError::Server(format!(
            "Embedded server failed to start after {SERVER_START_MAX_ATTEMPTS} attempts. \
             Last error: {last_error}"
        )))
    }

    /// Wires `send_user_input` and `interrupt_instance` callbacks on the
    /// `agent_data` service using the server's host router connection service.
    fn wire_agent_data_callbacks(&self, server: &EmbeddedAgentServer) {
        let host_router = match server.host_router() {
            Some(hr) => hr,
            None => return,
        };

        let conn = Arc::clone(&host_router.connection_service);
        let dao = self.agent_data.dao();

        self.agent_data.set_send_user_input(Arc::new({
            let conn = Arc::clone(&conn);
            let dao = Arc::clone(&dao);
            move |run_id: &str, instance_id: &str, text: &str| {
                let agent = dao
                    .find_workspace_agent_by_instance_id(run_id, instance_id)
                    .map_err(|e| format!("DB lookup failed: {e}"))?
                    .ok_or_else(|| {
                        format!("Agent instance {} not found in run {}", instance_id, run_id)
                    })?;

                let agent_key = agent.agent_key;

                if !conn.is_run_connected(run_id) {
                    return Err(format!("Agent {} is not connected", agent_key));
                }

                let pkg = Package::UserInput(UserInputPackage {
                    instance_id: instance_id.to_string(),
                    content: text.to_string(),
                });

                let json_str = pkg.to_json().map_err(|e| format!("Serialize failed: {e}"))?;
                let conn = Arc::clone(&conn);
                let run_id = run_id.to_string();
                let instance_id_owned = instance_id.to_string();

                tokio::spawn(async move {
                    conn.send_to_run(&run_id, &json_str)
                        .await;
                });

                let _ = dao.update_agent_status(
                    &instance_id_owned,
                    &crate::domain::enums::AgentState::Generating,
                );

                Ok(())
            }
        }));

        self.agent_data.set_interrupt_instance(Arc::new({
            let conn = Arc::clone(&conn);
            let dao = Arc::clone(&dao);
            move |run_id: &str, instance_id: &str| {
                let agent = dao
                    .find_workspace_agent_by_instance_id(run_id, instance_id)
                    .map_err(|e| format!("DB lookup failed: {e}"))?
                    .ok_or_else(|| {
                        format!("Agent instance {} not found in run {}", instance_id, run_id)
                    })?;

                let agent_key = agent.agent_key;

                if !conn.is_run_connected(run_id) {
                    return Err(format!("Agent {} is not connected", agent_key));
                }

                let pkg = Package::Interrupt(InterruptPackage {
                    instance_id: instance_id.to_string(),
                });

                let json_str = pkg.to_json().map_err(|e| format!("Serialize failed: {e}"))?;
                let conn = Arc::clone(&conn);
                let run_id = run_id.to_string();

                tokio::spawn(async move {
                    conn.send_to_run(&run_id, &json_str)
                        .await;
                });

                Ok(())
            }
        }));
    }

    fn load_saved_port(&self) -> Option<u16> {
        match self.preference_dao.get_preference(PREF_SERVER_PORT) {
            Ok(Some(raw)) => raw.parse().ok(),
            _ => None,
        }
    }

    fn save_port(&self, port: u16) {
        let _ = self
            .preference_dao
            .set_preference(PREF_SERVER_PORT, &port.to_string());
    }

    /// Starts both startup and lifecycle monitors for a workspace.
    async fn start_monitoring(&self, workspace_id: &str, container_id: &str, run_id: &str) {
        // Startup monitor.
        let ws_id = workspace_id.to_string();
        let r_id = run_id.to_string();
        let dao = Arc::clone(&self.workspace_dao);
        let startup_handle = tokio::spawn(async move {
            startup_monitor_task(&ws_id, &r_id, dao).await;
        });
        self.startup_monitors
            .lock()
            .await
            .insert(workspace_id.to_string(), startup_handle);

        // Lifecycle monitor: log streaming + health polling.
        let ws_id = workspace_id.to_string();
        let r_id = run_id.to_string();
        let c_id = container_id.to_string();
        let dao = Arc::clone(&self.workspace_dao);
        let client = Arc::clone(&self.docker_client);
        let log_handle = tokio::spawn(async move {
            lifecycle_log_task(&ws_id, &r_id, &c_id, dao, client).await;
        });

        let ws_id2 = workspace_id.to_string();
        let r_id2 = run_id.to_string();
        let c_id2 = container_id.to_string();
        let dao2 = Arc::clone(&self.workspace_dao);
        let client2 = Arc::clone(&self.docker_client);
        let server2 = Arc::clone(&self.server);
        let health_handle = tokio::spawn(async move {
            lifecycle_health_task(&ws_id2, &r_id2, &c_id2, dao2, client2, server2).await;
        });

        let ws_id3 = workspace_id.to_string();
        let r_id3 = run_id.to_string();
        let dao3 = Arc::clone(&self.workspace_dao);
        let run_status_handle = tokio::spawn(async move {
            lifecycle_run_status_task(&ws_id3, &r_id3, dao3).await;
        });

        self.lifecycle_monitors.lock().await.insert(
            workspace_id.to_string(),
            LifecycleMonitorHandles {
                log_handle,
                health_handle,
                run_status_handle,
            },
        );
    }

    async fn cancel_monitors(&self, workspace_id: &str) {
        if let Some(handle) = self.startup_monitors.lock().await.remove(workspace_id) {
            handle.abort();
        }
        if let Some(handles) = self.lifecycle_monitors.lock().await.remove(workspace_id) {
            handles.log_handle.abort();
            handles.health_handle.abort();
            handles.run_status_handle.abort();
        }
    }
}

// ── Monitor tasks ──────────────────────────────────────────────────────

/// Startup monitor: watches for agents to connect within the timeout.
async fn startup_monitor_task(
    workspace_id: &str,
    run_id: &str,
    workspace_dao: Arc<WorkspaceDao>,
) {
    let mut stream = workspace_dao.watch_workspace_agents(run_id);
    let timeout = tokio::time::sleep(STARTUP_TIMEOUT);
    tokio::pin!(timeout);

    loop {
        tokio::select! {
            _ = &mut timeout => {
                tracing::warn!(
                    workspace_id,
                    "No agent connected within {}s -- will keep waiting",
                    STARTUP_TIMEOUT.as_secs()
                );
                let log = AgentLog {
                    id: new_id(),
                    run_id: run_id.to_string(),
                    agent_key: "_system".to_string(),
                    instance_id: "_system".to_string(),
                    turn_id: None,
                    level: LogLevel::Warn,
                    message: format!(
                        "No agent connected within {}s -- still waiting",
                        STARTUP_TIMEOUT.as_secs()
                    ),
                    source: LogSource::Engine,
                    timestamp: Utc::now().naive_utc(),
                };
                let _ = workspace_dao.insert_agent_log(&log);
                // Don't return -- keep listening for late connections.
                // But the timeout won't fire again, so just await the stream.
                while let Some(Ok(agents)) = stream.next().await {
                    if agents.iter().any(|a| {
                        a.status == AgentState::Generating
                            || a.status == AgentState::Idle
                            || a.status == AgentState::WaitingForInquiry
                    }) {
                        tracing::info!(workspace_id, "Agent(s) connected (late)");
                        return;
                    }
                }
                return;
            }
            result = stream.next() => {
                match result {
                    Some(Ok(agents)) => {
                        if agents.iter().any(|a| {
                            a.status == AgentState::Generating
                                || a.status == AgentState::Idle
                                || a.status == AgentState::WaitingForInquiry
                        }) {
                            tracing::info!(workspace_id, "Agent(s) connected");
                            return;
                        }
                    }
                    Some(Err(e)) => {
                        tracing::warn!(%e, "Workspace agent watch error");
                    }
                    None => return,
                }
            }
        }
    }
}

/// Lifecycle monitor: streams container logs and classifies log levels.
async fn lifecycle_log_task(
    _workspace_id: &str,
    run_id: &str,
    container_id: &str,
    workspace_dao: Arc<WorkspaceDao>,
    docker_client: Arc<DockerClient>,
) {
    let log_stream = docker_client.container_logs(container_id, true);
    tokio::pin!(log_stream);
    let mut last_level = LogLevel::Info;

    while let Some(result) = log_stream.next().await {
        match result {
            Ok(line) => {
                last_level = classify_log_level(&line, last_level);
                let parsed = parse_docker_timestamp(&line);

                let log = AgentLog {
                    id: new_id(),
                    run_id: run_id.to_string(),
                    agent_key: "_system".to_string(),
                    instance_id: "_system".to_string(),
                    turn_id: None,
                    level: last_level,
                    message: parsed.message,
                    source: LogSource::Engine,
                    timestamp: parsed.timestamp,
                };
                let _ = workspace_dao.insert_agent_log(&log);
            }
            Err(e) => {
                tracing::warn!(%e, "Container log stream error");
            }
        }
    }
}

/// Lifecycle monitor: polls container health at regular intervals.
async fn lifecycle_health_task(
    workspace_id: &str,
    run_id: &str,
    container_id: &str,
    workspace_dao: Arc<WorkspaceDao>,
    docker_client: Arc<DockerClient>,
    server: Arc<Mutex<EmbeddedAgentServer>>,
) {
    let mut interval = tokio::time::interval(HEALTH_CHECK_INTERVAL);
    loop {
        interval.tick().await;

        match docker_client.inspect_container(container_id).await {
            Ok(inspect) => {
                let state = inspect.state.as_ref();
                let is_running = state.map(|s| s.running).unwrap_or(false);
                if !is_running {
                    let exit_code = state.map(|s| s.exit_code).unwrap_or(-1);
                    tracing::warn!(
                        workspace_id,
                        exit_code,
                        "Container exited"
                    );

                    let exit_msg = match exit_code {
                        137 => "Container killed (OOM or manual kill, code 137)".to_string(),
                        1 => "Container crashed (code 1)".to_string(),
                        0 => "Container exited normally (code 0)".to_string(),
                        _ => format!("Container exited with code {exit_code}"),
                    };

                    let level = if exit_code == 0 {
                        LogLevel::Info
                    } else {
                        LogLevel::Error
                    };

                    let log = AgentLog {
                        id: new_id(),
                        run_id: run_id.to_string(),
                        agent_key: "_system".to_string(),
                        instance_id: "_system".to_string(),
                        turn_id: None,
                        level,
                        message: format!("[engine] {exit_msg}"),
                        source: LogSource::Engine,
                        timestamp: Utc::now().naive_utc(),
                    };
                    let _ = workspace_dao.insert_agent_log(&log);

                    // Only transition to failed if still active.
                    if let Ok(Some(active_run)) = workspace_dao.get_active_run(workspace_id) {
                        if active_run.status == "running" || active_run.status == "starting" {
                            let _ = workspace_dao.update_run_status(
                                run_id,
                                "failed",
                                Some(&Utc::now().naive_utc()),
                            );
                        }
                    }

                    // Mark all agents as disconnected — container is gone.
                    {
                        let server = server.lock().await;
                        if let Some(ref router) = server.host_router() {
                            router
                                .status_service
                                .mark_all_agents_disconnected(workspace_id)
                                .await;
                        }
                    }

                    return; // Stop polling.
                }
            }
            Err(e) => {
                tracing::warn!(%e, "Container health check failed");
            }
        }
    }
}

/// Lifecycle monitor: watches run status and self-cancels on terminal state.
///
/// Mirrors the Dart `_watchRunStatus` — listens for DB changes to the run
/// and cancels the lifecycle monitor when the run reaches `stopped` or `failed`,
/// or when the run is deleted.
async fn lifecycle_run_status_task(
    workspace_id: &str,
    run_id: &str,
    workspace_dao: Arc<WorkspaceDao>,
) {
    let mut stream = workspace_dao.watch_workspace_runs(workspace_id);

    while let Some(result) = stream.next().await {
        match result {
            Ok(runs) => {
                let run = runs.iter().find(|r| r.id == run_id);
                match run {
                    None => {
                        // Run was deleted — stop monitoring.
                        tracing::info!(
                            run_id,
                            "Run deleted, stopping lifecycle monitor"
                        );
                        return;
                    }
                    Some(r) if r.status == "stopped" || r.status == "failed" => {
                        tracing::info!(
                            run_id,
                            status = %r.status,
                            "Run terminal, stopping lifecycle monitor"
                        );
                        return;
                    }
                    _ => {}
                }
            }
            Err(e) => {
                tracing::warn!(%e, "Run status watch error");
            }
        }
    }
}

// ── Pure utility functions ─────────────────────────────────────────────

/// Normalize a host path for Docker bind mounts.
///
/// Docker on Windows accepts forward slashes but chokes on single backslashes.
/// Also strips the `\\?\` extended-length prefix that Windows path
/// canonicalization produces — Docker doesn't understand it and the extra
/// colon in the drive letter (`\\?\D:\…`) breaks the bind-mount parser.
pub fn docker_path(path: &str) -> String {
    let normalized = path.replace('\\', "/");
    normalized
        .strip_prefix("//?/")
        .unwrap_or(&normalized)
        .to_string()
}

/// Derive a directory basename from a git URL.
///
/// Handles HTTPS (`https://github.com/org/repo.git`) and SSH
/// (`git@github.com:org/repo.git`) formats. Also strips GitHub
/// `/tree/<ref>` and `/commit/<ref>` suffixes.
pub fn dir_name_from_git_url(url: &str) -> String {
    static RE_TREE_COMMIT: OnceLock<Regex> = OnceLock::new();
    static RE_SPLIT: OnceLock<Regex> = OnceLock::new();
    static RE_GIT: OnceLock<Regex> = OnceLock::new();

    let re = RE_TREE_COMMIT.get_or_init(|| Regex::new(r"/(tree|commit)/[^/]+$").unwrap());
    let cleaned = re.replace(url, "").to_string();
    let re_split = RE_SPLIT.get_or_init(|| Regex::new(r"[/:]").unwrap());
    let last_segment = re_split.split(&cleaned).last().unwrap_or("");
    let re_git = RE_GIT.get_or_init(|| Regex::new(r"\.git$").unwrap());
    re_git.replace(last_segment, "").to_string()
}

/// Parse a GitHub-style URL, splitting `/tree/<ref>` or `/commit/<ref>` into
/// the base clone URL and a ref string. Returns `(base_url, ref)`.
pub fn parse_git_url(url: &str) -> (&str, Option<&str>) {
    static RE_GIT_URL: OnceLock<Regex> = OnceLock::new();
    let re = RE_GIT_URL.get_or_init(|| Regex::new(r"^(https://[^/]+/[^/]+/[^/]+)/(tree|commit)/(.+)$").unwrap());
    if let Some(caps) = re.captures(url) {
        let base = caps.get(1).unwrap();
        let git_ref = caps.get(3).unwrap();
        // Return slices into the original string.
        (&url[base.start()..base.end()], Some(&url[git_ref.start()..git_ref.end()]))
    } else {
        (url, None)
    }
}

/// Builds a flat map of per-agent system metadata for the container.
///
/// Walks the agent hierarchy and produces one entry per agent key:
/// ```json
/// { "lead": { "is_root": true, "peers": "coder,tester" },
///   "coder": { "is_root": false, "peers": "" } }
/// ```
pub fn build_agents_meta(
    agents: &HashMap<String, AgentConfig>,
    template_fields: &HashMap<String, HashMap<String, String>>,
    is_root: bool,
) -> HashMap<String, serde_json::Value> {
    let mut meta = HashMap::new();

    for (key, agent) in agents {
        let mut all_peers: Vec<String> = agent.peers.clone();
        for sub_key in agent.sub_agents.keys() {
            if !all_peers.contains(sub_key) {
                all_peers.push(sub_key.clone());
            }
        }
        let mut entry = serde_json::json!({
            "is_root": is_root,
            "peers": all_peers.join(","),
        });

        if let Some(fields) = template_fields.get(&agent.template) {
            if !fields.is_empty() {
                entry["fields"] = serde_json::to_value(fields).unwrap_or_default();
            }
        }

        meta.insert(key.clone(), entry);

        if !agent.sub_agents.is_empty() {
            let sub_meta = build_agents_meta(&agent.sub_agents, template_fields, false);
            meta.extend(sub_meta);
        }
    }

    meta
}

/// Classifies a log line's severity level.
///
/// Uses `previous_level` to carry `Error` through multi-line blocks like
/// Python tracebacks.
pub fn classify_log_level(line: &str, previous_level: LogLevel) -> LogLevel {
    let lower = line.to_lowercase();

    if lower.contains("error")
        || lower.contains("traceback")
        || lower.contains("exception")
        || lower.contains("fatal")
    {
        return LogLevel::Error;
    }
    if lower.contains("warn") {
        return LogLevel::Warn;
    }

    // Inside an error block, continuation lines inherit error level.
    if previous_level == LogLevel::Error {
        let after_timestamp = strip_docker_timestamp(&lower);
        if after_timestamp.starts_with(' ')
            || after_timestamp.starts_with('\t')
            || after_timestamp.contains("file \"")
            || after_timestamp.contains("in <")
        {
            return LogLevel::Error;
        }
    }

    LogLevel::Info
}

/// Strips Docker log timestamp prefix.
pub fn strip_docker_timestamp(line: &str) -> &str {
    if let Some(idx) = line.find(' ') {
        if idx > 20 && idx < 40 {
            return &line[idx + 1..];
        }
    }
    line
}

/// Parsed Docker log timestamp result.
pub struct ParsedDockerLog {
    pub timestamp: chrono::NaiveDateTime,
    pub message: String,
}

/// Parses the Docker ISO8601 timestamp prefix from a log line.
pub fn parse_docker_timestamp(line: &str) -> ParsedDockerLog {
    if let Some(idx) = line.find(' ') {
        if idx > 20 && idx < 40 {
            let ts_string = &line[..idx];
            if let Ok(parsed) = chrono::DateTime::parse_from_rfc3339(ts_string) {
                return ParsedDockerLog {
                    timestamp: parsed.naive_utc(),
                    message: line[idx + 1..].to_string(),
                };
            }
        }
    }
    ParsedDockerLog {
        timestamp: Utc::now().naive_utc(),
        message: line.to_string(),
    }
}

// parse_memory_limit is re-exported from crate::docker
pub use crate::docker::parse_memory_limit;
