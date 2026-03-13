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

        // ── All other commands — not yet implemented ────────────────

        _ => Err(AppError::Internal(format!(
            "Command not yet implemented: {:?}",
            std::mem::discriminant(command)
        ))),
    }
}

fn to_json<T: serde::Serialize>(value: T) -> Result<serde_json::Value> {
    serde_json::to_value(value)
        .map_err(|e| AppError::Internal(format!("serialize error: {e}")))
}
