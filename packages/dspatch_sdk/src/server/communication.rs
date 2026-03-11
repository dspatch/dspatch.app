// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Persists agent output packages to the database.
//!
//! Ported from `server/communication_service.dart`.

use std::sync::Arc;

use chrono::{DateTime, Utc};

use crate::db::dao::WorkspaceDao;
use crate::domain::enums::LogSource;
use crate::domain::models::{AgentActivity, AgentFile, AgentLog, AgentMessage, AgentUsage};

use super::packages::*;

/// Persists agent output packets to the database.
///
/// Handles:
/// - MessagePackage -> agent_messages (delta: append, replace: upsert)
/// - PromptReceivedPackage -> agent_messages (user role)
/// - ActivityPackage -> agent_activity_events (delta/replace with content+data append)
/// - LogPackage -> agent_logs
/// - UsagePackage -> agent_usage_records
/// - FilesPackage -> agent_files
pub struct CommunicationService {
    workspace_dao: Arc<WorkspaceDao>,
}

impl CommunicationService {
    pub fn new(workspace_dao: Arc<WorkspaceDao>) -> Self {
        Self { workspace_dao }
    }

    pub fn handle_output_packet(
        &self,
        _workspace_id: &str,
        agent_key: &str,
        run_id: &str,
        event: &Package,
    ) {
        let result = match event {
            Package::Message(pkg) => self.persist_message(agent_key, run_id, pkg),
            Package::PromptReceived(pkg) => self.persist_prompt_received(agent_key, run_id, pkg),
            Package::Activity(pkg) => self.persist_activity(agent_key, run_id, pkg),
            Package::Log(pkg) => self.persist_log(agent_key, run_id, pkg),
            Package::Usage(pkg) => self.persist_usage(agent_key, run_id, pkg),
            Package::Files(pkg) => self.persist_files(agent_key, run_id, pkg),
            _ => {
                tracing::warn!(
                    pkg_type = event.type_str(),
                    "CommunicationService received unexpected event type"
                );
                Ok(())
            }
        };
        if let Err(e) = result {
            tracing::error!(
                pkg_type = event.type_str(),
                agent_key,
                error = %e,
                "CommunicationService failed to persist"
            );
        }
    }

    fn persist_message(
        &self,
        _agent_key: &str,
        run_id: &str,
        event: &MessagePackage,
    ) -> crate::util::result::Result<()> {
        let message_id = event
            .id
            .as_deref()
            .unwrap_or_else(|| "")
            .to_string();
        let message_id = if message_id.is_empty() {
            uuid::Uuid::new_v4().to_string()
        } else {
            message_id
        };
        let instance_id = &event.instance_id;
        let turn_id = event.turn_id.clone();
        let ts = event
            .ts
            .and_then(|t| DateTime::from_timestamp_millis(t).map(|dt| dt.naive_utc()))
            .unwrap_or_else(|| Utc::now().naive_utc());

        let role = match event.role {
            MessageRole::Assistant => "assistant",
            MessageRole::User => "user",
            MessageRole::Tool => "tool",
        };

        if event.is_delta {
            // Delta mode: try appending first, if no row exists create new.
            let append_result = self
                .workspace_dao
                .append_agent_message_content(&message_id, &event.content);
            if append_result.is_err() {
                // First chunk — insert new row.
                self.workspace_dao.insert_agent_message(&AgentMessage {
                    id: message_id,
                    run_id: run_id.to_string(),
                    instance_id: instance_id.clone(),
                    role: role.to_string(),
                    content: event.content.clone(),
                    model: event.model.clone(),
                    input_tokens: event.input_tokens,
                    output_tokens: event.output_tokens,
                    turn_id,
                    sender_name: event.sender_name.clone(),
                    created_at: ts,
                })?;
            }
        } else {
            // Replace mode: try update, if no row create new.
            let update_result = self.workspace_dao.update_agent_message(
                &message_id,
                Some(&event.content),
                event.model.as_deref(),
                event.input_tokens,
                event.output_tokens,
            );
            if update_result.is_err() {
                self.workspace_dao.insert_agent_message(&AgentMessage {
                    id: message_id,
                    run_id: run_id.to_string(),
                    instance_id: instance_id.clone(),
                    role: role.to_string(),
                    content: event.content.clone(),
                    model: event.model.clone(),
                    input_tokens: event.input_tokens,
                    output_tokens: event.output_tokens,
                    turn_id,
                    sender_name: event.sender_name.clone(),
                    created_at: ts,
                })?;
            }
        }
        Ok(())
    }

    fn persist_prompt_received(
        &self,
        _agent_key: &str,
        run_id: &str,
        event: &PromptReceivedPackage,
    ) -> crate::util::result::Result<()> {
        let ts = event
            .ts
            .and_then(|t| DateTime::from_timestamp_millis(t).map(|dt| dt.naive_utc()))
            .unwrap_or_else(|| Utc::now().naive_utc());

        self.workspace_dao.insert_agent_message(&AgentMessage {
            id: uuid::Uuid::new_v4().to_string(),
            run_id: run_id.to_string(),
            instance_id: event.instance_id.clone(),
            role: "user".to_string(),
            content: event.content.clone(),
            model: None,
            input_tokens: None,
            output_tokens: None,
            turn_id: event.turn_id.clone(),
            sender_name: event.sender_name.clone(),
            created_at: ts,
        })
    }

    fn persist_activity(
        &self,
        agent_key: &str,
        run_id: &str,
        event: &ActivityPackage,
    ) -> crate::util::result::Result<()> {
        let activity_id = event
            .id
            .as_deref()
            .unwrap_or("")
            .to_string();
        let activity_id = if activity_id.is_empty() {
            uuid::Uuid::new_v4().to_string()
        } else {
            activity_id
        };
        let instance_id = &event.instance_id;
        let ts = event
            .ts
            .and_then(|t| DateTime::from_timestamp_millis(t).map(|dt| dt.naive_utc()))
            .unwrap_or_else(|| Utc::now().naive_utc());
        let data_json = event
            .data
            .as_ref()
            .map(|d| serde_json::to_string(d).unwrap_or_default());

        if event.is_delta {
            let mut updated = false;
            if let Some(ref content) = event.content {
                if self
                    .workspace_dao
                    .append_agent_activity_content(&activity_id, content)
                    .is_ok()
                {
                    updated = true;
                }
            }
            if let Some(ref dj) = data_json {
                if self
                    .workspace_dao
                    .append_agent_activity_data(&activity_id, dj)
                    .is_ok()
                {
                    updated = true;
                }
            }
            if !updated {
                self.workspace_dao
                    .insert_agent_activity(&AgentActivity {
                        id: activity_id,
                        run_id: run_id.to_string(),
                        agent_key: agent_key.to_string(),
                        instance_id: instance_id.clone(),
                        turn_id: event.turn_id.clone(),
                        event_type: event.event_type.clone(),
                        data_json,
                        content: event.content.clone(),
                        timestamp: ts,
                    })?;
            }
        } else {
            let update_result = self.workspace_dao.update_agent_activity(
                &activity_id,
                None,
                data_json.as_deref(),
                event.content.as_deref(),
            );
            if update_result.is_err() {
                self.workspace_dao
                    .insert_agent_activity(&AgentActivity {
                        id: activity_id,
                        run_id: run_id.to_string(),
                        agent_key: agent_key.to_string(),
                        instance_id: instance_id.clone(),
                        turn_id: event.turn_id.clone(),
                        event_type: event.event_type.clone(),
                        data_json,
                        content: event.content.clone(),
                        timestamp: ts,
                    })?;
            }
        }
        Ok(())
    }

    fn persist_log(
        &self,
        agent_key: &str,
        run_id: &str,
        event: &LogPackage,
    ) -> crate::util::result::Result<()> {
        let ts = event
            .ts
            .and_then(|t| DateTime::from_timestamp_millis(t).map(|dt| dt.naive_utc()))
            .unwrap_or_else(|| Utc::now().naive_utc());

        self.workspace_dao.insert_agent_log(&AgentLog {
            id: uuid::Uuid::new_v4().to_string(),
            run_id: run_id.to_string(),
            agent_key: agent_key.to_string(),
            instance_id: event.instance_id.clone(),
            turn_id: event.turn_id.clone(),
            level: event.level,
            message: event.message.clone(),
            source: LogSource::Agent,
            timestamp: ts,
        })
    }

    fn persist_usage(
        &self,
        agent_key: &str,
        run_id: &str,
        event: &UsagePackage,
    ) -> crate::util::result::Result<()> {
        let ts = event
            .ts
            .and_then(|t| DateTime::from_timestamp_millis(t).map(|dt| dt.naive_utc()))
            .unwrap_or_else(|| Utc::now().naive_utc());

        self.workspace_dao.insert_agent_usage(&AgentUsage {
            id: uuid::Uuid::new_v4().to_string(),
            run_id: run_id.to_string(),
            agent_key: agent_key.to_string(),
            instance_id: event.instance_id.clone(),
            turn_id: event.turn_id.clone(),
            model: event.model.clone(),
            input_tokens: event.input_tokens,
            output_tokens: event.output_tokens,
            cache_read_tokens: event.cache_read_tokens.unwrap_or(0),
            cache_write_tokens: event.cache_write_tokens.unwrap_or(0),
            cost_usd: event.cost_usd.unwrap_or(0.0),
            timestamp: ts,
        })
    }

    fn persist_files(
        &self,
        agent_key: &str,
        run_id: &str,
        event: &FilesPackage,
    ) -> crate::util::result::Result<()> {
        let ts = event
            .ts
            .and_then(|t| DateTime::from_timestamp_millis(t).map(|dt| dt.naive_utc()))
            .unwrap_or_else(|| Utc::now().naive_utc());

        for file in &event.files {
            let file_path = file
                .get("file_path")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let operation = file
                .get("operation")
                .and_then(|v| v.as_str())
                .unwrap_or("unknown");

            self.workspace_dao.insert_agent_file(&AgentFile {
                id: uuid::Uuid::new_v4().to_string(),
                run_id: run_id.to_string(),
                agent_key: agent_key.to_string(),
                instance_id: event.instance_id.clone(),
                turn_id: event.turn_id.clone(),
                file_path: file_path.to_string(),
                operation: operation.to_string(),
                timestamp: ts,
            })?;
        }
        Ok(())
    }
}
