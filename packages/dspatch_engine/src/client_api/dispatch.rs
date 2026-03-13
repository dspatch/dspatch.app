// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Command dispatcher — routes typed commands to service methods.

use crate::client_api::commands::Command;
use crate::engine::service_registry::ServiceRegistry;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Dispatches a typed command to the appropriate service method.
pub async fn dispatch_command(
    command: &Command,
    services: &ServiceRegistry,
) -> Result<serde_json::Value> {
    match command {
        // ── Workspace Commands ──────────────────────────────────────

        Command::GetWorkspace { id } => {
            let workspace = services.workspaces().get_workspace(id).await?;
            to_json(workspace)
        }

        Command::CreateWorkspace { .. } => {
            // TODO: wire when Command fields are updated to match CreateWorkspaceRequest (needs config_yaml)
            Err(AppError::Internal(
                "create_workspace not yet wired — requires config_yaml field".into(),
            ))
        }

        Command::DeleteWorkspace { id } => {
            services.workspaces().delete_workspace(id).await?;
            Ok(serde_json::Value::Null)
        }

        Command::LaunchWorkspace { id } => {
            services.workspaces().launch_workspace(id).await?;
            Ok(serde_json::Value::Null)
        }

        Command::StopWorkspace { id } => {
            services.workspaces().stop_workspace(id).await?;
            Ok(serde_json::Value::Null)
        }

        Command::DeleteWorkspaceRun { run_id } => {
            services.workspaces().delete_workspace_run(run_id)?;
            Ok(serde_json::Value::Null)
        }

        Command::DeleteNonActiveRuns { workspace_id } => {
            services
                .workspaces()
                .delete_non_active_runs(workspace_id)?;
            Ok(serde_json::Value::Null)
        }

        // ── Agent Provider Commands ─────────────────────────────────

        Command::GetAgentProvider { id } => {
            let provider = services.agent_providers().get_agent_provider(id).await?;
            to_json(provider)
        }

        Command::CreateAgentProvider { request } => {
            let req: crate::domain::models::CreateAgentProviderRequest =
                serde_json::from_value(request.clone()).map_err(|e| {
                    AppError::Validation(format!("Invalid agent provider request: {e}"))
                })?;
            let provider = services
                .agent_providers()
                .create_agent_provider(req)
                .await?;
            to_json(provider)
        }

        Command::UpdateAgentProvider { id, request } => {
            let req: crate::domain::models::UpdateAgentProviderRequest =
                serde_json::from_value(request.clone()).map_err(|e| {
                    AppError::Validation(format!("Invalid update request: {e}"))
                })?;
            let provider = services
                .agent_providers()
                .update_agent_provider(id, req)
                .await?;
            to_json(provider)
        }

        Command::DeleteAgentProvider { id } => {
            services.agent_providers().delete_agent_provider(id).await?;
            Ok(serde_json::Value::Null)
        }

        // ── Preference Commands ─────────────────────────────────────

        Command::GetPreference { key } => {
            let value = services.preferences().get_preference(key).await?;
            match value {
                Some(v) => Ok(serde_json::Value::String(v)),
                None => Ok(serde_json::Value::Null),
            }
        }

        Command::SetPreference { key, value } => {
            services.preferences().set_preference(key, value).await?;
            Ok(serde_json::Value::Null)
        }

        Command::DeletePreference { key } => {
            services.preferences().delete_preference(key).await?;
            Ok(serde_json::Value::Null)
        }

        // ── API Key Commands ────────────────────────────────────────

        Command::GetApiKeyByName { name } => {
            let api_key = services.api_keys().get_api_key_by_name(name).await?;
            to_json(api_key)
        }

        Command::CreateApiKey { .. } => {
            // TODO: wire when crypto service is available (needs encryption of plaintext key)
            Err(AppError::Internal(
                "create_api_key not yet wired — requires crypto service for key encryption".into(),
            ))
        }

        Command::DeleteApiKey { id } => {
            services.api_keys().delete_api_key(id).await?;
            Ok(serde_json::Value::Null)
        }

        // ── Inquiry Commands ────────────────────────────────────────

        Command::RespondToInquiry {
            inquiry_id,
            response,
            choice_index,
        } => {
            services
                .inquiries()
                .respond_to_workspace_inquiry(
                    inquiry_id,
                    Some(response.as_str()),
                    *choice_index,
                )
                .await?;
            Ok(serde_json::Value::Null)
        }

        // ── Agent Template Commands ───────────────────────────────

        Command::CreateAgentTemplate { .. } => {
            // TODO: wire when Command fields match create_agent_template(name, source_uri, provider_id)
            Err(AppError::Internal(
                "agent template creation not yet wired — command params need restructuring".into(),
            ))
        }

        Command::UpdateAgentTemplate { .. } => {
            // TODO: wire when Command fields match update_agent_template(id, name, source_uri)
            Err(AppError::Internal(
                "agent template update not yet wired — command params need restructuring".into(),
            ))
        }

        Command::DeleteAgentTemplate { id } => {
            services.agent_templates().delete_agent_template(id).await?;
            Ok(serde_json::Value::Null)
        }

        // ── Agent Interaction Commands ────────────────────────────

        Command::SendUserInputToAgent { .. } => {
            // TODO: wire when Command fields match send_user_input_to_agent(run_id, instance_id, text)
            // Command has (run_id, agent_key, content) but service expects (run_id, instance_id, text)
            Err(AppError::Internal(
                "send_user_input_to_agent not yet wired — command fields don't match service signature".into(),
            ))
        }

        Command::InterruptInstance { run_id, instance_id, .. } => {
            // agent_key is available but the service only needs (run_id, instance_id)
            services.agent_data().interrupt_instance(run_id, instance_id).await?;
            Ok(serde_json::Value::Null)
        }

        // ── Instance Lifecycle Commands — NOT_IMPLEMENTED ─────────
        // TODO: requires container orchestration

        Command::StartRootInstance { .. }
        | Command::StartSubInstance { .. }
        | Command::StopInstance { .. }
        | Command::CleanupStaleInstances { .. } => {
            Err(AppError::Internal(
                "Instance lifecycle commands not yet wired — requires container orchestration".into(),
            ))
        }

        // ── Docker Commands — NOT_IMPLEMENTED ─────────────────────
        // TODO: requires DockerClient (bollard crate + Docker daemon)

        Command::DetectDockerStatus
        | Command::ListContainers
        | Command::StopContainer { .. }
        | Command::RemoveContainer { .. }
        | Command::StopAllContainers
        | Command::DeleteStoppedContainers
        | Command::CleanOrphanedContainers
        | Command::DeleteRuntimeImage
        | Command::ContainerStats { .. } => {
            Err(AppError::Internal(
                "Docker commands not yet wired — requires DockerClient".into(),
            ))
        }

        // ── Hub Commands — NOT_IMPLEMENTED ────────────────────────
        // TODO: requires backend connection

        Command::HubBrowseAgents { .. }
        | Command::HubAgentCategories
        | Command::HubBrowseWorkspaces { .. }
        | Command::HubWorkspaceCategories
        | Command::HubResolveAgent { .. }
        | Command::HubResolveWorkspace { .. }
        | Command::HubResolveWorkspaceDetails { .. }
        | Command::HubMyVotes { .. }
        | Command::HubPopularTags { .. }
        | Command::HubSearchTags { .. }
        | Command::CheckForAgentUpdates
        | Command::CheckForWorkspaceUpdates
        | Command::HubSubmitAgent { .. }
        | Command::HubSubmitTemplate { .. }
        | Command::HubSubmitWorkspace { .. }
        | Command::HubVoteAgent { .. }
        | Command::HubVoteWorkspace { .. } => {
            Err(AppError::Internal(
                "Hub commands require backend connection — not yet wired".into(),
            ))
        }

        // ── Config Parser Commands — NOT_IMPLEMENTED ──────────────
        // TODO: wire config parser service

        Command::ParseWorkspaceConfig { .. }
        | Command::ValidateWorkspaceConfig { .. }
        | Command::EncodeWorkspaceYaml { .. }
        | Command::ResolveWorkspaceTemplates { .. } => {
            Err(AppError::Internal(
                "Config parser commands not yet wired".into(),
            ))
        }

        // ── Crypto Commands — NOT_IMPLEMENTED ─────────────────────
        // TODO: requires key store

        Command::EncryptString { .. } | Command::DecryptString { .. } => {
            Err(AppError::Internal(
                "Crypto commands require key store — not yet wired".into(),
            ))
        }

        // ── File Browser — NOT_IMPLEMENTED ────────────────────────
        // TODO: LocalFileBrowserService not in ServiceRegistry; also show_hidden param mismatch

        Command::ListDirectory { .. } => {
            Err(AppError::Internal(
                "File browser not yet wired in ServiceRegistry".into(),
            ))
        }

        // ── Package Inspector — NOT_IMPLEMENTED ──────────────────

        Command::PackageInspectorEntries { .. } => {
            Err(AppError::Internal(
                "Package inspector not yet wired".into(),
            ))
        }

        // ── Server Lifecycle ──────────────────────────────────────

        Command::StartServer { .. } | Command::StopServer => {
            Err(AppError::Internal(
                "Server lifecycle managed by engine internally — not a client command".into(),
            ))
        }
    }
}

fn to_json<T: serde::Serialize>(value: T) -> Result<serde_json::Value> {
    serde_json::to_value(value)
        .map_err(|e| AppError::Internal(format!("serialize error: {e}")))
}
