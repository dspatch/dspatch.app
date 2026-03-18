// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Typed command enum for the client API command dispatcher.
//!
//! Each variant corresponds to one bridge method from the old `api.rs`.
//! Uses serde's `tag = "method"` for automatic deserialization from the
//! JSON `params` value.
//!
//! ## Adding a new command
//!
//! 1. Add a variant to [`Command`] with `#[serde(rename = "method_name")]`
//! 2. Add a match arm in `dispatch::dispatch_command()` (Task 4)
//! 3. Write a test in `tests/engine_tests.rs`
//!
//! ## Grouping
//!
//! Variants are grouped by service in comments. The enum is flat (not nested)
//! because serde tagged unions don't support nesting, and a flat enum gives
//! us exhaustive match checking.

use serde::Deserialize;

/// A typed command received from the client over WebSocket.
///
/// Deserialized from the `params` field of a `ClientFrame::Command`.
/// The `method` field in the JSON maps to the variant via `#[serde(rename)]`.
#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "method")]
pub enum Command {
    // ── Workspace Commands ──────────────────────────────────────────────

    #[serde(rename = "get_workspace")]
    GetWorkspace { id: String },

    #[serde(rename = "create_workspace")]
    CreateWorkspace {
        project_path: String,
        config_yaml: String,
    },

    #[serde(rename = "delete_workspace")]
    DeleteWorkspace { id: String },

    #[serde(rename = "launch_workspace")]
    LaunchWorkspace { id: String },

    #[serde(rename = "stop_workspace")]
    StopWorkspace { id: String },

    #[serde(rename = "delete_workspace_run")]
    DeleteWorkspaceRun { run_id: String },

    #[serde(rename = "delete_non_active_runs")]
    DeleteNonActiveRuns { workspace_id: String },

    // ── Agent Provider Commands ─────────────────────────────────────────

    #[serde(rename = "get_agent_provider")]
    GetAgentProvider { id: String },

    #[serde(rename = "create_agent_provider")]
    CreateAgentProvider {
        #[serde(flatten)]
        request: serde_json::Value,
    },

    #[serde(rename = "update_agent_provider")]
    UpdateAgentProvider {
        id: String,
        #[serde(flatten)]
        request: serde_json::Value,
    },

    #[serde(rename = "delete_agent_provider")]
    DeleteAgentProvider { id: String },

    // ── Agent Template Commands ─────────────────────────────────────────

    #[serde(rename = "create_agent_template")]
    CreateAgentTemplate {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "update_agent_template")]
    UpdateAgentTemplate {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "delete_agent_template")]
    DeleteAgentTemplate { id: String },

    // ── API Key Commands ────────────────────────────────────────────────

    #[serde(rename = "create_api_key")]
    CreateApiKey {
        name: String,
        value: String,
        provider_name: Option<String>,
    },

    #[serde(rename = "get_api_key_by_name")]
    GetApiKeyByName { name: String },

    #[serde(rename = "delete_api_key")]
    DeleteApiKey { id: String },

    // ── Preference Commands ─────────────────────────────────────────────

    #[serde(rename = "get_preference")]
    GetPreference { key: String },

    #[serde(rename = "set_preference")]
    SetPreference { key: String, value: String },

    #[serde(rename = "delete_preference")]
    DeletePreference { key: String },

    // ── Inquiry Commands ────────────────────────────────────────────────

    #[serde(rename = "respond_to_inquiry")]
    RespondToInquiry {
        inquiry_id: String,
        response: String,
        #[serde(default)]
        choice_index: Option<i32>,
    },

    // ── Agent Interaction Commands ──────────────────────────────────────

    #[serde(rename = "send_user_input_to_agent")]
    SendUserInputToAgent {
        run_id: String,
        instance_id: String,
        text: String,
    },

    #[serde(rename = "interrupt_instance")]
    InterruptInstance {
        run_id: String,
        agent_key: String,
        instance_id: String,
    },

    // ── Instance Lifecycle Commands ─────────────────────────────────────

    #[serde(rename = "start_root_instance")]
    StartRootInstance {
        run_id: String,
        agent_key: String,
    },

    #[serde(rename = "start_sub_instance")]
    StartSubInstance {
        run_id: String,
        agent_key: String,
        parent_instance_id: String,
    },

    #[serde(rename = "stop_instance")]
    StopInstance {
        run_id: String,
        agent_key: String,
        instance_id: String,
    },

    #[serde(rename = "cleanup_stale_instances")]
    CleanupStaleInstances {
        workspace_id: String,
        run_id: String,
    },

    // ── Docker Commands ─────────────────────────────────────────────────

    #[serde(rename = "detect_docker_status")]
    DetectDockerStatus,

    #[serde(rename = "list_containers")]
    ListContainers,

    #[serde(rename = "stop_container")]
    StopContainer { id: String },

    #[serde(rename = "remove_container")]
    RemoveContainer { id: String },

    #[serde(rename = "stop_all_containers")]
    StopAllContainers,

    #[serde(rename = "delete_stopped_containers")]
    DeleteStoppedContainers,

    #[serde(rename = "clean_orphaned_containers")]
    CleanOrphanedContainers,

    #[serde(rename = "build_runtime_image")]
    BuildRuntimeImage,

    #[serde(rename = "delete_runtime_image")]
    DeleteRuntimeImage,

    #[serde(rename = "container_stats")]
    ContainerStats { run_id: String },

    // ── Hub Commands ────────────────────────────────────────────────────

    #[serde(rename = "hub_browse_agents")]
    HubBrowseAgents {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_agent_categories")]
    HubAgentCategories,

    #[serde(rename = "hub_browse_workspaces")]
    HubBrowseWorkspaces {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_workspace_categories")]
    HubWorkspaceCategories,

    #[serde(rename = "hub_resolve_agent")]
    HubResolveAgent { agent_id: String },

    #[serde(rename = "hub_resolve_workspace")]
    HubResolveWorkspace { workspace_id: String },

    #[serde(rename = "hub_resolve_workspace_details")]
    HubResolveWorkspaceDetails {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_my_votes")]
    HubMyVotes { item_type: String },

    #[serde(rename = "hub_popular_tags")]
    HubPopularTags {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_search_tags")]
    HubSearchTags {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "check_for_agent_updates")]
    CheckForAgentUpdates,

    #[serde(rename = "check_for_workspace_updates")]
    CheckForWorkspaceUpdates,

    #[serde(rename = "hub_submit_agent")]
    HubSubmitAgent {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_submit_template")]
    HubSubmitTemplate {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_submit_workspace")]
    HubSubmitWorkspace {
        #[serde(flatten)]
        params: serde_json::Value,
    },

    #[serde(rename = "hub_vote_agent")]
    HubVoteAgent { author: String, slug: String, vote: i32 },

    #[serde(rename = "hub_vote_workspace")]
    HubVoteWorkspace { workspace_id: String, vote: i32 },

    // ── Git Commands ────────────────────────────────────────────────────

    #[serde(rename = "git_preflight_check")]
    GitPreflightCheck { directory: String },

    // ── Config Parser Commands ──────────────────────────────────────────

    #[serde(rename = "parse_workspace_config")]
    ParseWorkspaceConfig { yaml: String },

    #[serde(rename = "validate_workspace_config")]
    ValidateWorkspaceConfig { yaml: String },

    #[serde(rename = "encode_workspace_yaml")]
    EncodeWorkspaceYaml {
        config: serde_json::Value,
    },

    #[serde(rename = "resolve_workspace_templates")]
    ResolveWorkspaceTemplates { workspace_id: String },

    // ── Crypto Commands ─────────────────────────────────────────────────

    #[serde(rename = "encrypt_string")]
    EncryptString { plaintext: String },

    #[serde(rename = "decrypt_string")]
    DecryptString { ciphertext: String },

    // ── File Browser Commands ───────────────────────────────────────────

    #[serde(rename = "list_directory")]
    ListDirectory { path: String },

    // ── Package Inspector Commands ──────────────────────────────────────

    #[serde(rename = "package_inspector_entries")]
    PackageInspectorEntries { run_id: String },

    // ── Server Lifecycle Commands ───────────────────────────────────────

    #[serde(rename = "start_server")]
    StartServer {
        #[serde(default)]
        preferred_port: Option<u16>,
    },

    #[serde(rename = "stop_server")]
    StopServer,

    // ── Database Lifecycle Commands ───────────────────────────────────

    #[serde(rename = "get_database_state")]
    GetDatabaseState,

    #[serde(rename = "perform_migration")]
    PerformMigration,

    #[serde(rename = "skip_migration")]
    SkipMigration,

    // ── Session Commands ──────────────────────────────────────────────

    #[serde(rename = "refresh_credentials")]
    RefreshCredentials {
        backend_token: String,
        #[serde(default)]
        device_id: Option<String>,
        #[serde(default)]
        identity_key_seed: Option<String>,
    },

    #[serde(rename = "logout")]
    Logout,

    // ── Sync Commands ─────────────────────────────────────────────────

    #[serde(rename = "sync_status")]
    SyncStatus,

    #[serde(rename = "online_devices")]
    OnlineDevices,
}
