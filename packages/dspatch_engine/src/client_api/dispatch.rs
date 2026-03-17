// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Command dispatcher — routes typed commands to service methods.

use std::collections::HashMap;

use futures::StreamExt;

use crate::client_api::commands::Command;
use crate::client_api::ephemeral::EphemeralEventEmitter;
use crate::domain::models::CreateWorkspaceRequest;
use crate::docker::{DSPATCH_CONTAINER_LABEL, RUNTIME_IMAGE_TAG};
use crate::engine::service_registry::ServiceRegistry;
use crate::hub::HubApiClient;
use crate::util::error::AppError;
use crate::util::result::Result;
use crate::workspace_config::{parser, validation};

/// Dispatches a typed command to the appropriate service method.
pub async fn dispatch_command(
    command: &Command,
    services: &ServiceRegistry,
    ephemeral: &EphemeralEventEmitter,
) -> Result<serde_json::Value> {
    match command {
        // ── Workspace Commands ──────────────────────────────────────

        Command::GetWorkspace { id } => {
            let workspace = services.workspaces().get_workspace(id).await?;
            to_json(workspace)
        }

        Command::CreateWorkspace {
            project_path,
            config_yaml,
        } => {
            let request = CreateWorkspaceRequest {
                project_path: project_path.clone(),
                config_yaml: config_yaml.clone(),
            };
            let workspace = services.workspaces().create_workspace(request).await?;
            to_json(workspace)
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
            Ok(serde_json::json!({ "value": value }))
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

        Command::CreateApiKey {
            name,
            value,
            provider_name,
        } => {
            let encrypted = services
                .crypto()
                .encrypt_string(value, "api_key")
                .await?;
            let provider_label = provider_name.as_deref().unwrap_or("");
            // Build display hint: last 4 characters of the plaintext value.
            let hint: String = value.chars().rev().take(4).collect::<Vec<_>>().into_iter().rev().collect();
            let display_hint = if hint.is_empty() { None } else { Some(hint.as_str()) };
            services
                .api_keys()
                .create_api_key(name, provider_label, encrypted, display_hint)
                .await?;
            Ok(serde_json::Value::Null)
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

        Command::CreateAgentTemplate { params } => {
            let name = params["name"]
                .as_str()
                .ok_or_else(|| AppError::Validation("Missing 'name' field".into()))?;
            let source_uri = params["source_uri"]
                .as_str()
                .ok_or_else(|| AppError::Validation("Missing 'source_uri' field".into()))?;
            let template = services
                .agent_templates()
                .create_agent_template(name, source_uri)
                .await?;
            to_json(template)
        }

        Command::UpdateAgentTemplate { params } => {
            let id = params["id"]
                .as_str()
                .ok_or_else(|| AppError::Validation("Missing 'id' field".into()))?;
            let name = params["name"]
                .as_str()
                .ok_or_else(|| AppError::Validation("Missing 'name' field".into()))?;
            let source_uri = params["source_uri"]
                .as_str()
                .ok_or_else(|| AppError::Validation("Missing 'source_uri' field".into()))?;
            services
                .agent_templates()
                .update_agent_template(id, name, source_uri)
                .await?;
            Ok(serde_json::Value::Null)
        }

        Command::DeleteAgentTemplate { id } => {
            services.agent_templates().delete_agent_template(id).await?;
            Ok(serde_json::Value::Null)
        }

        // ── Agent Interaction Commands ────────────────────────────

        Command::SendUserInputToAgent {
            run_id,
            instance_id,
            text,
        } => {
            services
                .agent_data()
                .send_user_input_to_agent(run_id, instance_id, text)
                .await?;
            Ok(serde_json::Value::Null)
        }

        Command::InterruptInstance {
            run_id, instance_id, ..
        } => {
            services
                .agent_data()
                .interrupt_instance(run_id, instance_id)
                .await?;
            Ok(serde_json::Value::Null)
        }

        // ── Instance Lifecycle Commands ─────────────────────────

        Command::StartRootInstance { .. }
        | Command::StartSubInstance { .. }
        | Command::StopInstance { .. }
        | Command::CleanupStaleInstances { .. } => Err(AppError::Server(
            "Instance lifecycle requires a running workspace".into(),
        )),

        // ── Docker Commands ─────────────────────────────────────

        Command::DetectDockerStatus => {
            let status = services.docker_service().detect_status().await?;
            Ok(serde_json::to_value(&status).unwrap())
        }

        Command::ListContainers => {
            let mut filters = HashMap::new();
            filters.insert(
                "label".to_string(),
                vec![DSPATCH_CONTAINER_LABEL.to_string()],
            );
            let containers = services
                .docker()
                .list_containers(true, Some(&filters))
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            to_json(containers)
        }

        Command::StopContainer { id } => {
            services
                .docker()
                .stop_container(id, 10)
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            Ok(serde_json::Value::Null)
        }

        Command::RemoveContainer { id } => {
            services
                .docker()
                .remove_container(id, true)
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            Ok(serde_json::Value::Null)
        }

        Command::StopAllContainers => {
            let mut filters = HashMap::new();
            filters.insert(
                "label".to_string(),
                vec![DSPATCH_CONTAINER_LABEL.to_string()],
            );
            let containers = services
                .docker()
                .list_containers(false, Some(&filters))
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            for c in &containers {
                let _ = services.docker().stop_container(&c.id, 10).await;
            }
            Ok(serde_json::Value::Null)
        }

        Command::DeleteStoppedContainers => {
            let mut filters = HashMap::new();
            filters.insert(
                "label".to_string(),
                vec![DSPATCH_CONTAINER_LABEL.to_string()],
            );
            filters.insert("status".to_string(), vec!["exited".to_string()]);
            let containers = services
                .docker()
                .list_containers(true, Some(&filters))
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            for c in &containers {
                let _ = services.docker().remove_container(&c.id, false).await;
            }
            Ok(serde_json::Value::Null)
        }

        Command::CleanOrphanedContainers => {
            // Orphaned = dspatch-managed containers with no matching workspace in DB.
            let mut filters = HashMap::new();
            filters.insert(
                "label".to_string(),
                vec![DSPATCH_CONTAINER_LABEL.to_string()],
            );
            let containers = services
                .docker()
                .list_containers(true, Some(&filters))
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            let workspaces = services.workspaces().list_workspaces()?;
            let workspace_ids: std::collections::HashSet<&str> =
                workspaces.iter().map(|w| w.id.as_str()).collect();
            for c in &containers {
                // Check if container's workspace label matches a known workspace.
                let ws_id = c.labels.get("com.dspatch.workspace_id");
                if ws_id.map_or(true, |id| !workspace_ids.contains(id.as_str())) {
                    let _ = services.docker().stop_container(&c.id, 5).await;
                    let _ = services.docker().remove_container(&c.id, true).await;
                }
            }
            Ok(serde_json::Value::Null)
        }

        Command::BuildRuntimeImage => {
            let stream = services.docker_service().build_runtime_image();
            let docker_client = services.docker().clone();
            let emitter = ephemeral.clone_sender();
            tokio::spawn(async move {
                let mut stream = std::pin::pin!(stream);
                let mut got_lines = false;
                while let Some(line) = stream.next().await {
                    got_lines = true;
                    emitter.emit("build_log_line", serde_json::json!({ "line": line }));
                }
                // Verify the image actually exists after the stream ends.
                let image_exists = docker_client
                    .list_images(Some(RUNTIME_IMAGE_TAG))
                    .await
                    .map(|imgs| !imgs.is_empty())
                    .unwrap_or(false);
                if image_exists {
                    emitter.emit("build_complete", serde_json::json!({}));
                } else {
                    let reason = if got_lines {
                        "Build process failed"
                    } else {
                        "Build context assembly failed — check engine logs"
                    };
                    emitter.emit("build_failed", serde_json::json!({ "error": reason }));
                }
            });
            Ok(serde_json::json!({ "started": true }))
        }

        Command::DeleteRuntimeImage => {
            services
                .docker()
                .remove_image(RUNTIME_IMAGE_TAG, true)
                .await
                .map_err(|e| AppError::Docker(e.to_string()))?;
            Ok(serde_json::Value::Null)
        }

        Command::ContainerStats { run_id } => Err(AppError::Server(format!(
            "Container stats requires run_id→container mapping (run_id: {run_id})"
        ))),

        // ── Hub Commands ────────────────────────────────────────

        Command::HubBrowseAgents { params } => {
            let hub = require_hub(services)?;
            let cursor = params.get("cursor").and_then(|v| v.as_str());
            let category = params.get("category").and_then(|v| v.as_str());
            let search = params.get("search").and_then(|v| v.as_str());
            let per_page = params.get("per_page").and_then(|v| v.as_u64()).unwrap_or(20) as u32;
            let (agents, pagination) = hub
                .browse_agents(cursor, category, search, per_page)
                .await
                .map_err(hub_err)?;
            Ok(serde_json::json!({ "data": agents, "pagination": pagination }))
        }

        Command::HubAgentCategories => {
            let hub = require_hub(services)?;
            let categories = hub.agent_categories().await.map_err(hub_err)?;
            Ok(serde_json::json!({ "data": categories }))
        }

        Command::HubBrowseWorkspaces { params } => {
            let hub = require_hub(services)?;
            let cursor = params.get("cursor").and_then(|v| v.as_str());
            let category = params.get("category").and_then(|v| v.as_str());
            let search = params.get("search").and_then(|v| v.as_str());
            let per_page = params.get("per_page").and_then(|v| v.as_u64()).unwrap_or(20) as u32;
            let (workspaces, pagination) = hub
                .browse_workspaces(cursor, category, search, per_page)
                .await
                .map_err(hub_err)?;
            Ok(serde_json::json!({ "data": workspaces, "pagination": pagination }))
        }

        Command::HubWorkspaceCategories => {
            let hub = require_hub(services)?;
            let categories = hub.workspace_categories().await.map_err(hub_err)?;
            Ok(serde_json::json!({ "data": categories }))
        }

        Command::HubResolveAgent { agent_id } => {
            let hub = require_hub(services)?;
            let resolved = hub.resolve_agent(agent_id).await.map_err(hub_err)?;
            to_json(resolved)
        }

        Command::HubResolveWorkspace { workspace_id } => {
            let hub = require_hub(services)?;
            let resolved = hub.resolve_workspace(workspace_id).await.map_err(hub_err)?;
            to_json(resolved)
        }

        Command::HubResolveWorkspaceDetails { params } => {
            let hub = require_hub(services)?;
            let slug = params["workspace_id"]
                .as_str()
                .ok_or_else(|| AppError::Validation("Missing 'workspace_id' field".into()))?;
            let resolved = hub.resolve_workspace(slug).await.map_err(hub_err)?;
            to_json(resolved)
        }

        Command::HubMyVotes { item_type } => {
            let hub = require_hub(services)?;
            let slugs = hub.my_votes(item_type).await.map_err(hub_err)?;
            Ok(serde_json::json!({ "slugs": slugs }))
        }

        Command::HubPopularTags { params } => {
            let hub = require_hub(services)?;
            let category = params.get("category").and_then(|v| v.as_str());
            let limit = params.get("limit").and_then(|v| v.as_u64()).unwrap_or(20) as u32;
            let tags = hub.popular_tags(category, limit).await.map_err(hub_err)?;
            Ok(serde_json::json!({ "data": tags }))
        }

        Command::HubSearchTags { params } => {
            let hub = require_hub(services)?;
            let query = params.get("query").and_then(|v| v.as_str());
            let category = params.get("category").and_then(|v| v.as_str());
            let limit = params.get("limit").and_then(|v| v.as_u64()).unwrap_or(20) as u32;
            let tags = hub.search_tags(query, category, limit).await.map_err(hub_err)?;
            Ok(serde_json::json!({ "data": tags }))
        }

        Command::CheckForAgentUpdates => {
            // TODO: Implement version checking against installed agent templates.
            Ok(serde_json::json!({ "updates": [] }))
        }

        Command::CheckForWorkspaceUpdates => {
            // TODO: Implement version checking against installed workspace templates.
            Ok(serde_json::json!({ "updates": [] }))
        }

        Command::HubSubmitAgent { params } => {
            let hub = require_hub(services)?;
            let name = params["name"].as_str()
                .ok_or_else(|| AppError::Validation("Missing 'name' field".into()))?;
            let repo_url = params["repo_url"].as_str()
                .ok_or_else(|| AppError::Validation("Missing 'repo_url' field".into()))?;
            let branch = params.get("branch").and_then(|v| v.as_str());
            let description = params.get("description").and_then(|v| v.as_str());
            let category = params.get("category").and_then(|v| v.as_str());
            let tags = params.get("tags").and_then(|v| v.as_array());
            let entry_point = params.get("entry_point").and_then(|v| v.as_str());
            let sdk_version = params.get("sdk_version").and_then(|v| v.as_str());
            hub.submit_agent(name, repo_url, branch, description, category,
                tags.map(|t| t.as_slice()), entry_point, sdk_version)
                .await
                .map_err(hub_err)?;
            Ok(serde_json::Value::Null)
        }

        Command::HubSubmitTemplate { params } => {
            let hub = require_hub(services)?;
            let name = params["name"].as_str()
                .ok_or_else(|| AppError::Validation("Missing 'name' field".into()))?;
            let config_yaml = params["config_yaml"].as_str()
                .ok_or_else(|| AppError::Validation("Missing 'config_yaml' field".into()))?;
            let source_uri = params["source_uri"].as_str()
                .ok_or_else(|| AppError::Validation("Missing 'source_uri' field".into()))?;
            let description = params.get("description").and_then(|v| v.as_str());
            let category = params.get("category").and_then(|v| v.as_str());
            let tags = params.get("tags").and_then(|v| v.as_array());
            hub.submit_template(name, config_yaml, source_uri, description, category,
                tags.map(|t| t.as_slice()))
                .await
                .map_err(hub_err)?;
            Ok(serde_json::Value::Null)
        }

        Command::HubSubmitWorkspace { params } => {
            let hub = require_hub(services)?;
            let name = params["name"].as_str()
                .ok_or_else(|| AppError::Validation("Missing 'name' field".into()))?;
            let config_yaml = &params["config_json"];
            let description = params.get("description").and_then(|v| v.as_str());
            let category = params.get("category").and_then(|v| v.as_str());
            let tags = params.get("tags").and_then(|v| v.as_array());
            hub.submit_workspace(name, config_yaml, description, category,
                tags.map(|t| t.as_slice()))
                .await
                .map_err(hub_err)?;
            Ok(serde_json::Value::Null)
        }

        Command::HubVoteAgent { agent_id, .. } => {
            let hub = require_hub(services)?;
            let result = hub.vote_agent(agent_id).await.map_err(hub_err)?;
            Ok(result)
        }

        Command::HubVoteWorkspace { workspace_id, .. } => {
            let hub = require_hub(services)?;
            let result = hub.vote_workspace(workspace_id).await.map_err(hub_err)?;
            Ok(result)
        }

        // ── Config Parser Commands ──────────────────────────────

        Command::ParseWorkspaceConfig { yaml } => {
            let config = parser::parse_workspace_config(yaml)
                .map_err(|e| AppError::Validation(format!("Invalid workspace config: {e}")))?;
            to_json(config)
        }

        Command::ValidateWorkspaceConfig { yaml } => {
            let config = parser::parse_workspace_config(yaml)
                .map_err(|e| AppError::Validation(format!("Invalid workspace config: {e}")))?;
            let errors = validation::validate_config(&config);
            to_json(serde_json::json!({
                "valid": errors.is_empty(),
                "errors": errors.iter().map(|e| serde_json::json!({
                    "field": e.field,
                    "message": e.message,
                })).collect::<Vec<_>>(),
            }))
        }

        Command::EncodeWorkspaceYaml { config } => {
            let config: crate::workspace_config::config::WorkspaceConfig =
                serde_json::from_value(config.clone()).map_err(|e| {
                    AppError::Validation(format!("Invalid workspace config object: {e}"))
                })?;
            let yaml = parser::encode_yaml(&config)
                .map_err(|e| AppError::Internal(format!("YAML encoding failed: {e}")))?;
            Ok(serde_json::json!({ "yaml": yaml }))
        }

        Command::ResolveWorkspaceTemplates { workspace_id } => {
            let workspace = services.workspaces().get_workspace(workspace_id).await?;
            let project_path = std::path::Path::new(&workspace.project_path);
            let config = parser::parse_workspace_config_file(project_path)
                .map_err(|e| AppError::Validation(format!("Failed to parse config: {e}")))?;
            let result = crate::workspace_config::template_resolver::resolve_workspace_templates(
                &config,
                services.agent_providers(),
                services.api_keys(),
            )
            .await;
            to_json(result)
        }

        // ── Crypto Commands ─────────────────────────────────────

        Command::EncryptString { plaintext } => {
            let blob = services
                .crypto()
                .encrypt_string(plaintext, "user")
                .await?;
            let hex = hex::encode(&blob);
            Ok(serde_json::json!({ "ciphertext": hex }))
        }

        Command::DecryptString { ciphertext } => {
            let blob = hex::decode(ciphertext)
                .map_err(|e| AppError::Validation(format!("Invalid hex ciphertext: {e}")))?;
            let plaintext = services
                .crypto()
                .decrypt_string(&blob, "user")
                .await?;
            Ok(serde_json::json!({ "plaintext": plaintext }))
        }

        // ── File Browser ────────────────────────────────────────

        Command::ListDirectory { path } => {
            let entries = services.file_browser().list_directory(path).await?;
            to_json(entries)
        }

        // ── Package Inspector ───────────────────────────────────

        Command::PackageInspectorEntries { .. } => Err(AppError::Server(
            "Package inspector requires a running workspace".into(),
        )),

        // ── Server Lifecycle ────────────────────────────────────

        Command::StartServer { .. } | Command::StopServer => Err(AppError::Internal(
            "Server lifecycle managed by engine internally — not a client command".into(),
        )),

        // ── Database Lifecycle ───────────────────────────────────
        // Intercepted in ws.rs before dispatch — these need the SDK,
        // not ServiceRegistry, and must work when services are None.

        Command::GetDatabaseState
        | Command::PerformMigration
        | Command::SkipMigration
        | Command::RefreshCredentials { .. }
        | Command::Logout => Err(AppError::Internal(
            "This command is handled by the WebSocket layer before dispatch".into(),
        )),
    }
}

fn to_json<T: serde::Serialize>(value: T) -> Result<serde_json::Value> {
    serde_json::to_value(value)
        .map_err(|e| AppError::Internal(format!("serialize error: {e}")))
}

/// Returns the hub client or an API error if not configured.
fn require_hub(services: &ServiceRegistry) -> Result<&HubApiClient> {
    services
        .hub_client()
        .map(|c| c.as_ref())
        .ok_or_else(|| AppError::Api {
            message: "Hub requires backend connection — not configured".into(),
            status_code: None,
            body: None,
        })
}

/// Maps a `HubApiException` to `AppError::Api`.
fn hub_err(e: crate::hub::HubApiException) -> AppError {
    AppError::Api {
        message: e.body.clone(),
        status_code: Some(e.status_code),
        body: Some(e.body),
    }
}
