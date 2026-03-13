// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! FRB-annotated API surface for the d:spatch SDK.
//!
//! This module exposes [`RustSdk`] — an opaque handle wrapping `Arc<DspatchSdk>`
//! — to Flutter via `flutter_rust_bridge`. Domain types are exposed directly
//! (no more bridge wrapper types).
//!
//! # Runtime rules
//!
//! - **`async fn`**: FRB provides its own Tokio runtime — `tokio::spawn` etc.
//!   work normally inside these methods.
//! - **`fn` (sync)**: FRB calls these from a plain thread pool with **no Tokio
//!   context**. Any async work MUST go through `self.rt` (e.g. `self.rt.spawn`,
//!   `self.rt.block_on`).
//!   **Never use bare `tokio::spawn` in sync methods — it will panic.**

use flutter_rust_bridge::frb;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::frb_generated::StreamSink;
use crate::config::DspatchConfig;
use crate::domain::models::{
    AgentProvider, AgentTemplate, ApiKey,
    AuthTokens, BackupCodesData, CreateAgentProviderRequest, CreateWorkspaceRequest,
    Device, DeviceRegistrationRequest, DockerStatus, FileEntry,
    TotpSetupData, UpdateAgentProviderRequest, Workspace, WorkspaceTemplate,
};
use crate::docker::ContainerStats;
use crate::domain::services::ContainerSummary;
use chrono::NaiveDateTime;


/// A single captured package frame, flattened for the Flutter bridge.
pub struct BridgePackageLogEntry {
    pub timestamp: NaiveDateTime,
    /// "sent" or "received".
    pub direction: String,
    pub raw_json: String,
    pub roundtrip_mismatch: bool,
    pub roundtrip_json: Option<String>,
    pub error: Option<String>,
}
use crate::hub::{
    HubAgentResolve, HubAgentSummary, HubCategoryCount, HubPagination, HubTag,
    HubWorkspaceResolve, HubWorkspaceSummary,
};
use crate::sdk::{DatabaseReadyState, DspatchSdk};
use crate::workspace_config::config::WorkspaceConfig;
use crate::workspace_config::validation::ConfigValidationError;

/// The main SDK handle exposed to Flutter via FRB.
/// FRB auto-detects this as opaque (contains Arc).
#[frb(opaque)]
pub struct RustSdk {
    inner: Arc<DspatchSdk>,
    /// Dedicated Tokio runtime for stream forwarding and blocking service lookups.
    /// FRB calls sync methods from its own thread pool (no Tokio context),
    /// so we maintain our own runtime.
    rt: Arc<Runtime>,
}

#[frb]
impl RustSdk {
    // ── Construction & Lifecycle ────────────────────────────────────────

    /// Create a new SDK instance with default config.
    #[frb(sync)]
    pub fn new() -> Self {
        crate::util::logger::init_logging();
        let rt = Runtime::new().expect("Failed to create Tokio runtime");
        Self {
            inner: Arc::new(DspatchSdk::new(DspatchConfig::default())),
            rt: Arc::new(rt),
        }
    }

    /// Create with custom config.
    #[frb(sync)]
    pub fn with_config(
        server_port: u16,
        backend_url: Option<String>,
        assets_dir: Option<String>,
    ) -> Self {
        crate::util::logger::init_logging();
        let rt = Runtime::new().expect("Failed to create Tokio runtime");
        Self {
            inner: Arc::new(DspatchSdk::new(DspatchConfig {
                server_port,
                backend_url,
                assets_dir,
            })),
            rt: Arc::new(rt),
        }
    }

    /// Initialize the SDK (opens database, starts auth watcher, spawns
    /// recovery listener for active workspaces).
    pub async fn initialize(&self) -> Result<(), String> {
        // Spawn the recovery listener BEFORE initialize so it catches the
        // first DatabaseReadyState::Ready emission.
        self.inner.spawn_recovery_listener();
        self.inner.initialize().await.map_err(|e| e.to_string())
    }

    /// Dispose the SDK (stops server, closes database).
    pub async fn dispose(&self) -> Result<(), String> {
        self.inner.dispose().await.map_err(|e| e.to_string())
    }

    /// Check if the database is ready.
    pub async fn is_database_ready(&self) -> bool {
        self.inner.is_database_ready().await
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 4: Workspace Methods
    // ════════════════════════════════════════════════════════════════════

    /// Returns a single workspace by id.
    pub async fn get_workspace(&self, id: String) -> Result<Workspace, String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.get_workspace(&id).await.map_err(|e| e.to_string())
    }

    /// Creates a new workspace.
    pub async fn create_workspace(
        &self,
        request: CreateWorkspaceRequest,
    ) -> Result<Workspace, String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.create_workspace(request)
            .await
            .map_err(|e| e.to_string())
    }

    /// Deletes a workspace by id.
    pub async fn delete_workspace(&self, id: String) -> Result<(), String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.delete_workspace(&id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Launches a workspace container.
    pub async fn launch_workspace(&self, id: String) -> Result<(), String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.launch_workspace(&id)
            .await
            .map_err(|e| e.to_string())?;
        // Ensure the send_user_input callback is wired after the server starts.
        self.inner
            .ensure_send_user_input_wired()
            .await
            .map_err(|e| e.to_string())
    }

    /// Stops a workspace container.
    pub async fn stop_workspace(&self, id: String) -> Result<(), String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.stop_workspace(&id)
            .await
            .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 5: Template & API Key Methods
    // ════════════════════════════════════════════════════════════════════

    /// Returns a single agent provider by id.
    pub async fn get_agent_provider(&self, id: String) -> Result<AgentProvider, String> {
        let svc = self.inner.providers().await.map_err(|e| e.to_string())?;
        svc.get_agent_provider(&id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Creates a new agent provider.
    pub async fn create_agent_provider(
        &self,
        request: CreateAgentProviderRequest,
    ) -> Result<AgentProvider, String> {
        let svc = self.inner.providers().await.map_err(|e| e.to_string())?;
        svc.create_agent_provider(request)
            .await
            .map_err(|e| e.to_string())
    }

    /// Partially updates an agent provider by id.
    pub async fn update_agent_provider(
        &self,
        id: String,
        request: UpdateAgentProviderRequest,
    ) -> Result<AgentProvider, String> {
        let svc = self.inner.providers().await.map_err(|e| e.to_string())?;
        svc.update_agent_provider(&id, request)
            .await
            .map_err(|e| e.to_string())
    }

    /// Deletes an agent provider by id.
    pub async fn delete_agent_provider(&self, id: String) -> Result<(), String> {
        let svc = self.inner.providers().await.map_err(|e| e.to_string())?;
        svc.delete_agent_provider(&id)
            .await
            .map_err(|e| e.to_string())
    }

    // ── Agent Templates (lightweight config presets) ────────────────────

    /// Creates a new agent template from a provider.
    pub async fn create_agent_template(
        &self,
        name: String,
        source_uri: String,
    ) -> Result<AgentTemplate, String> {
        let svc = self.inner.templates().await.map_err(|e| e.to_string())?;
        svc.create_agent_template(&name, &source_uri)
            .await
            .map_err(|e| e.to_string())
    }

    /// Deletes an agent template by id.
    pub async fn delete_agent_template(&self, id: String) -> Result<(), String> {
        let svc = self.inner.templates().await.map_err(|e| e.to_string())?;
        svc.delete_agent_template(&id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Updates an existing agent template's name and source URI.
    pub async fn update_agent_template(
        &self,
        id: String,
        name: String,
        source_uri: String,
    ) -> Result<(), String> {
        let svc = self.inner.templates().await.map_err(|e| e.to_string())?;
        svc.update_agent_template(&id, &name, &source_uri)
            .await
            .map_err(|e| e.to_string())
    }

    /// Creates a new API key.
    pub async fn create_api_key(
        &self,
        name: String,
        provider_label: String,
        encrypted_key: Vec<u8>,
        display_hint: Option<String>,
    ) -> Result<(), String> {
        let svc = self.inner.api_keys().await.map_err(|e| e.to_string())?;
        svc.create_api_key(
            &name,
            &provider_label,
            encrypted_key,
            display_hint.as_deref(),
        )
        .await
        .map_err(|e| e.to_string())
    }

    /// Returns an API key by name, or None if not found.
    pub async fn get_api_key_by_name(&self, name: String) -> Result<Option<ApiKey>, String> {
        let svc = self.inner.api_keys().await.map_err(|e| e.to_string())?;
        svc.get_api_key_by_name(&name)
            .await
            .map_err(|e| e.to_string())
    }

    /// Deletes an API key by id.
    pub async fn delete_api_key(&self, id: String) -> Result<(), String> {
        let svc = self.inner.api_keys().await.map_err(|e| e.to_string())?;
        svc.delete_api_key(&id).await.map_err(|e| e.to_string())
    }

    /// Sends user text input to a specific agent instance.
    pub async fn send_user_input_to_agent(
        &self,
        run_id: String,
        instance_id: String,
        text: String,
    ) -> Result<(), String> {
        let svc = self.inner.agent_data().await.map_err(|e| e.to_string())?;
        svc.send_user_input_to_agent(&run_id, &instance_id, &text)
            .await
            .map_err(|e| e.to_string())
    }

    /// Sends an interrupt signal to a specific agent instance.
    pub async fn interrupt_instance(
        &self,
        run_id: String,
        instance_id: String,
    ) -> Result<(), String> {
        let svc = self.inner.agent_data().await.map_err(|e| e.to_string())?;
        svc.interrupt_instance(&run_id, &instance_id)
            .await
            .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 7: Auth Methods
    // ════════════════════════════════════════════════════════════════════

    /// Returns whether the user is currently authenticated.
    #[frb(sync)]
    pub fn is_authenticated(&self) -> bool {
        self.inner.auth_service().is_authenticated()
    }

    /// Logs in with username and password.
    pub async fn login(
        &self,
        username: String,
        password: String,
    ) -> Result<AuthTokens, String> {
        let auth = self.inner.auth_service();
        auth.login(&username, &password)
            .await
            .map_err(|e| e.to_string())
    }

    /// Registers a new account.
    pub async fn register(
        &self,
        username: String,
        email: String,
        password: String,
    ) -> Result<AuthTokens, String> {
        let auth = self.inner.auth_service();
        auth.register(&username, &email, &password)
            .await
            .map_err(|e| e.to_string())
    }

    /// Verifies email with a code.
    pub async fn verify_email(&self, code: String) -> Result<(), String> {
        let auth = self.inner.auth_service();
        auth.verify_email(&code).await.map_err(|e| e.to_string())
    }

    /// Verifies 2FA code.
    pub async fn verify_2fa(
        &self,
        code: String,
        is_backup_code: bool,
    ) -> Result<AuthTokens, String> {
        let auth = self.inner.auth_service();
        auth.verify_2fa(&code, is_backup_code)
            .await
            .map_err(|e| e.to_string())
    }

    /// Requests 2FA setup (returns TOTP URI and secret).
    pub async fn setup_2fa(&self) -> Result<TotpSetupData, String> {
        let auth = self.inner.auth_service();
        auth.setup_2fa().await.map_err(|e| e.to_string())
    }

    /// Confirms 2FA setup with a code (returns backup codes).
    pub async fn confirm_2fa(&self, code: String) -> Result<BackupCodesData, String> {
        let auth = self.inner.auth_service();
        auth.confirm_2fa(&code).await.map_err(|e| e.to_string())
    }

    /// Acknowledges backup codes (advances auth flow).
    pub async fn acknowledge_backup_codes(&self) -> Result<(), String> {
        let auth = self.inner.auth_service();
        auth.acknowledge_backup_codes()
            .await
            .map_err(|e| e.to_string())
    }

    /// Registers this device with the backend.
    pub async fn register_device(
        &self,
        request: DeviceRegistrationRequest,
        identity_key_hex: Option<String>,
    ) -> Result<AuthTokens, String> {
        let auth = self.inner.auth_service();
        auth.register_device(request, identity_key_hex.as_deref())
            .await
            .map_err(|e| e.to_string())
    }

    /// Logs out and clears stored tokens.
    pub async fn logout(&self) -> Result<(), String> {
        let auth = self.inner.auth_service();
        auth.logout().await.map_err(|e| e.to_string())
    }

    /// Enters anonymous mode (local-only, no backend connection).
    pub async fn enter_anonymous_mode(&self) -> Result<(), String> {
        let auth = self.inner.auth_service();
        auth.enter_anonymous_mode()
            .await
            .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 8: Inquiry Methods
    // ════════════════════════════════════════════════════════════════════

    /// Responds to a workspace inquiry.
    pub async fn respond_to_inquiry(
        &self,
        inquiry_id: String,
        response_text: Option<String>,
        response_suggestion_index: Option<i32>,
    ) -> Result<(), String> {
        let svc = self.inner.inquiries().await.map_err(|e| e.to_string())?;
        svc.respond_to_workspace_inquiry(
            &inquiry_id,
            response_text.as_deref(),
            response_suggestion_index,
        )
        .await
        .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 9: Docker, Server, Preferences
    // ════════════════════════════════════════════════════════════════════

    /// Detects Docker daemon status.
    pub async fn detect_docker_status(&self) -> Result<DockerStatus, String> {
        let svc = self.inner.docker_service();
        svc.detect_status().await.map_err(|e| e.to_string())
    }

    /// Lists all d:spatch-managed containers.
    pub async fn list_containers(&self) -> Result<Vec<ContainerSummary>, String> {
        let svc = self.inner.docker_service();
        svc.list_containers().await.map_err(|e| e.to_string())
    }

    /// Stops a container by id.
    pub async fn stop_container(&self, id: String) -> Result<(), String> {
        let svc = self.inner.docker_service();
        svc.stop_container(&id).await.map_err(|e| e.to_string())
    }

    /// Removes a container by id.
    pub async fn remove_container(&self, id: String) -> Result<(), String> {
        let svc = self.inner.docker_service();
        svc.remove_container(&id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Stops all running d:spatch containers. Returns the count stopped.
    pub async fn stop_all_containers(&self) -> Result<i32, String> {
        let svc = self.inner.docker_service();
        svc.stop_all_containers()
            .await
            .map_err(|e| e.to_string())
    }

    /// Removes all stopped d:spatch containers. Returns the count removed.
    pub async fn delete_stopped_containers(&self) -> Result<i32, String> {
        let svc = self.inner.docker_service();
        svc.delete_stopped_containers()
            .await
            .map_err(|e| e.to_string())
    }

    /// Removes orphaned containers (stopped, no matching active session).
    pub async fn clean_orphaned_containers(&self) -> Result<i32, String> {
        let svc = self.inner.docker_service();
        svc.clean_orphaned().await.map_err(|e| e.to_string())
    }

    /// Deletes the d:spatch runtime image.
    pub async fn delete_runtime_image(&self) -> Result<(), String> {
        let svc = self.inner.docker_service();
        svc.delete_runtime_image()
            .await
            .map_err(|e| e.to_string())
    }

    /// Starts the embedded agent server. Returns the bound port number.
    pub async fn start_server(&self, preferred_port: Option<u16>) -> Result<u16, String> {
        self.inner
            .start_server(preferred_port)
            .await
            .map_err(|e| e.to_string())
    }

    /// Stops the embedded agent server.
    pub async fn stop_server(&self) -> Result<(), String> {
        self.inner.stop_server().await.map_err(|e| e.to_string())
    }

    /// Returns the value for a preference key, or None if not set.
    pub async fn get_preference(&self, key: String) -> Result<Option<String>, String> {
        let svc = self.inner.preferences().await.map_err(|e| e.to_string())?;
        svc.get_preference(&key)
            .await
            .map_err(|e| e.to_string())
    }

    /// Sets a preference key to value.
    pub async fn set_preference(&self, key: String, value: String) -> Result<(), String> {
        let svc = self.inner.preferences().await.map_err(|e| e.to_string())?;
        svc.set_preference(&key, &value)
            .await
            .map_err(|e| e.to_string())
    }

    /// Removes the preference for key.
    pub async fn delete_preference(&self, key: String) -> Result<(), String> {
        let svc = self.inner.preferences().await.map_err(|e| e.to_string())?;
        svc.delete_preference(&key)
            .await
            .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 10: Hub, Config Parser, Crypto
    // ════════════════════════════════════════════════════════════════════

    /// Browse community agents with optional filtering and pagination.
    pub async fn hub_browse_agents(
        &self,
        cursor: Option<String>,
        category: Option<String>,
        search: Option<String>,
        per_page: u32,
    ) -> Result<(Vec<HubAgentSummary>, HubPagination), String> {
        let hc = self.inner.hub_client().read().await;
        hc.browse_agents(
            cursor.as_deref(),
            category.as_deref(),
            search.as_deref(),
            per_page,
        )
        .await
        .map_err(|e| e.to_string())
    }

    /// List available agent categories.
    pub async fn hub_agent_categories(&self) -> Result<Vec<HubCategoryCount>, String> {
        let hc = self.inner.hub_client().read().await;
        hc.agent_categories().await.map_err(|e| e.to_string())
    }

    /// Browse community workspaces with optional filtering and pagination.
    pub async fn hub_browse_workspaces(
        &self,
        cursor: Option<String>,
        category: Option<String>,
        search: Option<String>,
        per_page: u32,
    ) -> Result<(Vec<HubWorkspaceSummary>, HubPagination), String> {
        let hc = self.inner.hub_client().read().await;
        hc.browse_workspaces(
            cursor.as_deref(),
            category.as_deref(),
            search.as_deref(),
            per_page,
        )
        .await
        .map_err(|e| e.to_string())
    }

    /// List available workspace categories.
    pub async fn hub_workspace_categories(&self) -> Result<Vec<HubCategoryCount>, String> {
        let hc = self.inner.hub_client().read().await;
        hc.workspace_categories().await.map_err(|e| e.to_string())
    }

    /// Resolve an agent slug to its repo URL and build metadata.
    pub async fn hub_resolve_agent(
        &self,
        slug: String,
    ) -> Result<HubAgentResolve, String> {
        let hc = self.inner.hub_client().read().await;
        hc.resolve_agent(&slug).await.map_err(|e| e.to_string())
    }

    /// Resolve a workspace slug to its config YAML and agent references.
    pub async fn hub_resolve_workspace(
        &self,
        slug: String,
    ) -> Result<HubWorkspaceResolve, String> {
        let hc = self.inner.hub_client().read().await;
        hc.resolve_workspace(&slug)
            .await
            .map_err(|e| e.to_string())
    }

    /// Get the current user's voted slugs for a given target type.
    pub async fn hub_my_votes(
        &self,
        target_type: String,
    ) -> Result<Vec<String>, String> {
        let hc = self.inner.hub_client().read().await;
        hc.my_votes(&target_type).await.map_err(|e| e.to_string())
    }

    /// Returns popular tags, optionally filtered by category.
    pub async fn hub_popular_tags(
        &self,
        category: Option<String>,
        limit: u32,
    ) -> Result<Vec<HubTag>, String> {
        let hc = self.inner.hub_client().read().await;
        hc.popular_tags(category.as_deref(), limit)
            .await
            .map_err(|e| e.to_string())
    }

    /// Searches tags by query string, optionally filtered by category.
    pub async fn hub_search_tags(
        &self,
        query: Option<String>,
        category: Option<String>,
        limit: u32,
    ) -> Result<Vec<HubTag>, String> {
        let hc = self.inner.hub_client().read().await;
        hc.search_tags(query.as_deref(), category.as_deref(), limit)
            .await
            .map_err(|e| e.to_string())
    }

    /// Checks all local hub-sourced agent providers for updates.
    /// Returns a list of hub slugs that have a newer version available.
    pub async fn check_for_agent_updates(&self) -> Result<Vec<String>, String> {
        let checker = self
            .inner
            .hub_version_checker()
            .await
            .map_err(|e| e.to_string())?;
        Ok(checker.check_for_agent_updates().await)
    }

    /// Checks all local hub workspace templates for updates.
    /// Returns a list of hub slugs that have a newer version available.
    pub async fn check_for_workspace_updates(&self) -> Result<Vec<String>, String> {
        let checker = self
            .inner
            .hub_version_checker()
            .await
            .map_err(|e| e.to_string())?;
        Ok(checker.check_for_workspace_updates().await)
    }

    /// Submits an agent provider to the community hub.
    /// `tags_json` is an optional JSON array string, e.g. `[{"slug":"x","category":"general"}]`.
    pub async fn hub_submit_agent(
        &self,
        name: String,
        repo_url: String,
        branch: Option<String>,
        description: Option<String>,
        category: Option<String>,
        tags_json: Option<String>,
        entry_point: Option<String>,
        sdk_version: Option<String>,
    ) -> Result<(), String> {
        let tags: Option<Vec<serde_json::Value>> = match &tags_json {
            Some(s) => Some(serde_json::from_str(s).map_err(|e| e.to_string())?),
            None => None,
        };
        let hc = self.inner.hub_client().read().await;
        hc.submit_agent(
            &name,
            &repo_url,
            branch.as_deref(),
            description.as_deref(),
            category.as_deref(),
            tags.as_deref(),
            entry_point.as_deref(),
            sdk_version.as_deref(),
        )
        .await
        .map_err(|e| e.to_string())
    }

    /// Submits an agent template to the community hub.
    /// `tags_json` is an optional JSON array string.
    pub async fn hub_submit_template(
        &self,
        name: String,
        config_yaml: String,
        source_slug: String,
        description: Option<String>,
        category: Option<String>,
        tags_json: Option<String>,
    ) -> Result<(), String> {
        let tags: Option<Vec<serde_json::Value>> = match &tags_json {
            Some(s) => Some(serde_json::from_str(s).map_err(|e| e.to_string())?),
            None => None,
        };
        let hc = self.inner.hub_client().read().await;
        hc.submit_template(
            &name,
            &config_yaml,
            &source_slug,
            description.as_deref(),
            category.as_deref(),
            tags.as_deref(),
        )
        .await
        .map_err(|e| e.to_string())
    }

    /// Submits a workspace config to the community hub.
    /// `config_json` is the workspace config as a JSON string.
    /// `tags_json` is an optional JSON array string.
    pub async fn hub_submit_workspace(
        &self,
        name: String,
        config_json: String,
        description: Option<String>,
        category: Option<String>,
        tags_json: Option<String>,
    ) -> Result<(), String> {
        let config_yaml: serde_json::Value =
            serde_json::from_str(&config_json).map_err(|e| e.to_string())?;
        let tags: Option<Vec<serde_json::Value>> = match &tags_json {
            Some(s) => Some(serde_json::from_str(s).map_err(|e| e.to_string())?),
            None => None,
        };
        let hc = self.inner.hub_client().read().await;
        hc.submit_workspace(
            &name,
            &config_yaml,
            description.as_deref(),
            category.as_deref(),
            tags.as_deref(),
        )
        .await
        .map_err(|e| e.to_string())
    }

    /// Toggles a vote (like) on a community hub agent. Returns the JSON response as a string.
    pub async fn hub_vote_agent(
        &self,
        slug: String,
    ) -> Result<String, String> {
        let hc = self.inner.hub_client().read().await;
        let val = hc.vote_agent(&slug).await.map_err(|e| e.to_string())?;
        serde_json::to_string(&val).map_err(|e| e.to_string())
    }

    /// Toggles a vote (like) on a community hub workspace. Returns the JSON response as a string.
    pub async fn hub_vote_workspace(
        &self,
        slug: String,
    ) -> Result<String, String> {
        let hc = self.inner.hub_client().read().await;
        let val = hc.vote_workspace(&slug).await.map_err(|e| e.to_string())?;
        serde_json::to_string(&val).map_err(|e| e.to_string())
    }

    /// Resolves a hub workspace and returns its fields as FRB-friendly types.
    /// Returns (config_yaml_string, agent_refs, name, description, version).
    pub async fn hub_resolve_workspace_details(
        &self,
        slug: String,
    ) -> Result<(String, Vec<String>, String, Option<String>, i64), String> {
        let hc = self.inner.hub_client().read().await;
        let resolved = hc.resolve_workspace(&slug).await.map_err(|e| e.to_string())?;
        let config_yaml_string = serde_yaml::to_string(&resolved.config_yaml)
            .map_err(|e| e.to_string())?;
        Ok((
            config_yaml_string,
            resolved.agent_refs,
            resolved.name,
            resolved.description,
            resolved.version,
        ))
    }

    // ════════════════════════════════════════════════════════════════════
    // Run History Management
    // ════════════════════════════════════════════════════════════════════

    /// Deletes a single workspace run and all its child data.
    pub async fn delete_workspace_run(
        &self,
        run_id: String,
    ) -> Result<(), String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.delete_workspace_run(&run_id).map_err(|e| e.to_string())
    }

    /// Deletes all non-active (stopped/failed) runs for a workspace.
    pub async fn delete_non_active_runs(
        &self,
        workspace_id: String,
    ) -> Result<(), String> {
        let svc = self.inner.workspaces().await.map_err(|e| e.to_string())?;
        svc.delete_non_active_runs(&workspace_id).map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Container Stats
    // ════════════════════════════════════════════════════════════════════

    /// Returns one-shot resource usage stats for a running container.
    pub async fn container_stats(
        &self,
        container_id: String,
    ) -> Result<ContainerStats, String> {
        let client = self.inner.docker_client();
        client
            .container_stats(&container_id)
            .await
            .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Auth: Resend Verification
    // ════════════════════════════════════════════════════════════════════

    /// Resends the email verification code.
    pub async fn resend_verification(&self) -> Result<(), String> {
        let auth = self.inner.auth_service();
        auth.resend_verification().await.map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // Cleanup Stale Agents
    // ════════════════════════════════════════════════════════════════════

    /// Deletes all disconnected instance rows for an agent. Returns count deleted.
    pub async fn cleanup_stale_instances(
        &self,
        workspace_id: String,
        agent_key: String,
    ) -> Result<u32, String> {
        let server_guard = self.inner.server().read().await;
        let server_arc = server_guard
            .as_ref()
            .ok_or_else(|| "Server not running".to_string())?;
        let server = server_arc.lock().await;
        let router = server
            .host_router()
            .ok_or_else(|| "Host router not available".to_string())?;
        let count = router
            .event_service
            .cleanup_stale_instances(&workspace_id, &agent_key)
            .await;
        Ok(count as u32)
    }

    // ════════════════════════════════════════════════════════════════════
    // Per-Instance Lifecycle Control
    // ════════════════════════════════════════════════════════════════════

    /// Starts a new root instance for an agent. Returns the new instance ID.
    pub async fn start_root_instance(
        &self,
        workspace_id: String,
        agent_key: String,
    ) -> Result<String, String> {
        let server_guard = self.inner.server().read().await;
        let server_arc = server_guard
            .as_ref()
            .ok_or_else(|| "Server not running".to_string())?;
        let server = server_arc.lock().await;
        let router = server
            .host_router()
            .ok_or_else(|| "Host router not available".to_string())?;
        router
            .event_service
            .start_root_instance(&workspace_id, &agent_key)
            .await
            .map_err(|e| e.to_string())
    }

    /// Starts a new sub-instance for an agent. Returns the new instance ID.
    pub async fn start_sub_instance(
        &self,
        workspace_id: String,
        agent_key: String,
    ) -> Result<String, String> {
        let server_guard = self.inner.server().read().await;
        let server_arc = server_guard
            .as_ref()
            .ok_or_else(|| "Server not running".to_string())?;
        let server = server_arc.lock().await;
        let router = server
            .host_router()
            .ok_or_else(|| "Host router not available".to_string())?;
        router
            .event_service
            .start_sub_instance(&workspace_id, &agent_key)
            .await
            .map_err(|e| e.to_string())
    }

    /// Stops a specific instance of an agent.
    pub async fn stop_instance(
        &self,
        workspace_id: String,
        agent_key: String,
        instance_id: String,
    ) -> Result<(), String> {
        let server_guard = self.inner.server().read().await;
        let server_arc = server_guard
            .as_ref()
            .ok_or_else(|| "Server not running".to_string())?;
        let server = server_arc.lock().await;
        let router = server
            .host_router()
            .ok_or_else(|| "Host router not available".to_string())?;
        router
            .event_service
            .stop_instance(&workspace_id, &agent_key, &instance_id)
            .await;
        Ok(())
    }

    // ════════════════════════════════════════════════════════════════════
    // Package Inspector
    // ════════════════════════════════════════════════════════════════════

    /// Returns all captured package log entries for a run.
    pub async fn package_inspector_entries(
        &self,
        run_id: String,
    ) -> Result<Vec<BridgePackageLogEntry>, String> {
        let server_guard = self.inner.server().read().await;
        let server_arc = server_guard
            .as_ref()
            .ok_or_else(|| "Server not running".to_string())?;
        let server = server_arc.lock().await;
        let router = server
            .host_router()
            .ok_or_else(|| "Host router not available".to_string())?;
        let entries = router.package_inspector.entries_for_run(&run_id);
        Ok(entries
            .into_iter()
            .map(|e| {
                use crate::server::inspector::PackageDirection;
                BridgePackageLogEntry {
                    timestamp: e.timestamp.naive_utc(),
                    direction: match e.direction {
                        PackageDirection::Sent => "sent".to_string(),
                        PackageDirection::Received => "received".to_string(),
                    },
                    raw_json: e.raw_json,
                    roundtrip_mismatch: e.roundtrip_mismatch,
                    roundtrip_json: e.roundtrip_json,
                    error: e.error,
                }
            })
            .collect())
    }

    /// Parses a workspace config YAML string.
    pub fn parse_workspace_config(
        &self,
        yaml: String,
    ) -> Result<WorkspaceConfig, String> {
        crate::workspace_config::parser::parse_workspace_config(&yaml)
            .map_err(|e| e.to_string())
    }

    /// Validates a workspace config and returns a list of errors (empty = valid).
    pub fn validate_workspace_config(
        &self,
        config: WorkspaceConfig,
    ) -> Vec<ConfigValidationError> {
        crate::workspace_config::validation::validate_config(&config)
    }

    /// Encodes a workspace config as a YAML string.
    pub fn encode_workspace_yaml(
        &self,
        config: WorkspaceConfig,
    ) -> Result<String, String> {
        crate::workspace_config::parser::encode_yaml(&config).map_err(|e| e.to_string())
    }

    /// Resolves all providers referenced in a workspace config.
    ///
    /// Checks that every agent's provider exists locally, that required env
    /// vars are provided, that `{{apikey:Name}}` placeholders reference
    /// existing API keys, and that required mounts are covered by workspace
    /// mounts.
    pub async fn resolve_workspace_templates(
        &self,
        config: WorkspaceConfig,
    ) -> Result<crate::workspace_config::template_resolver::TemplateResolutionResult, String> {
        let provider_svc = self.inner.providers().await.map_err(|e| e.to_string())?;
        let api_key_svc = self.inner.api_keys().await.map_err(|e| e.to_string())?;
        Ok(
            crate::workspace_config::template_resolver::resolve_workspace_templates(
                &config,
                &provider_svc,
                &api_key_svc,
            )
            .await,
        )
    }

    /// Encrypts a UTF-8 string using AES-256-GCM with the given key_id.
    pub async fn encrypt_string(
        &self,
        plaintext: String,
        key_id: String,
    ) -> Result<Vec<u8>, String> {
        let crypto = self.inner.crypto();
        crypto
            .encrypt_string(&plaintext, &key_id)
            .await
            .map_err(|e| e.to_string())
    }

    /// Decrypts an AES-256-GCM blob back to a UTF-8 string.
    pub async fn decrypt_string(
        &self,
        blob: Vec<u8>,
        key_id: String,
    ) -> Result<String, String> {
        let crypto = self.inner.crypto();
        crypto
            .decrypt_string(&blob, &key_id)
            .await
            .map_err(|e| e.to_string())
    }

    // ════════════════════════════════════════════════════════════════════
    // SDK Event Bus (deprecated — events now flow through DB + table invalidation)
    // ════════════════════════════════════════════════════════════════════

    /// Stub — the SdkEventBus has been removed. Events now flow through
    /// ephemeral DB tables + table invalidation. This function is retained
    /// only because frb_generated.rs references it; it will be deleted when
    /// the FRB bridge is removed.
    pub fn watch_sdk_events(
        &self,
        _sink: StreamSink<crate::server::event_bus::SdkEvent>,
    ) -> Result<(), String> {
        Err("SdkEventBus removed — use watch_* streams instead".into())
    }

    // ════════════════════════════════════════════════════════════════════
    // Task 11: Device, File Browser
    // ════════════════════════════════════════════════════════════════════

    /// Returns the current device.
    #[frb(sync)]
    pub fn current_device(&self) -> Device {
        self.inner.device_service().current_device().clone()
    }

    /// Lists immediate children of a directory path.
    pub async fn list_directory(
        &self,
        project_path: String,
        directory_path: String,
    ) -> Result<Vec<FileEntry>, String> {
        let browser = self.inner.create_file_browser(&project_path);
        browser
            .list_directory(&directory_path)
            .await
            .map_err(|e| e.to_string())
    }

    /// Watches database state changes (Ready / Closed / MigrationPending).
    pub fn watch_database_state(
        &self,
        sink: StreamSink<DatabaseReadyState>,
    ) -> Result<(), String> {
        let mut rx = self.inner.subscribe_database_state();
        self.rt.spawn(async move {
            loop {
                match rx.recv().await {
                    Ok(state) => {
                        if sink.add(state).is_err() {
                            break;
                        }
                    }
                    Err(_) => break,
                }
            }
        });
        Ok(())
    }

    /// Returns whether a migration decision is pending.
    pub async fn is_migration_pending(&self) -> bool {
        self.inner.is_migration_pending().await
    }

    /// Migrates the anonymous database to the per-user path.
    ///
    /// Call only after `watch_database_state` emits `MigrationPending`.
    pub async fn perform_migration(&self) -> Result<(), String> {
        self.inner.perform_migration().await.map_err(|e| e.to_string())
    }

    /// Skips migration and opens a fresh per-user database.
    ///
    /// The anonymous database remains on disk untouched.
    pub async fn skip_migration(&self) -> Result<(), String> {
        self.inner.skip_migration().await.map_err(|e| e.to_string())
    }
}
