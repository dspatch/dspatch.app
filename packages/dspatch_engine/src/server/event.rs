// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Simplified event processing service.
//!
//! The engine is now a thin relay. Complex routing logic (chains, inquiry
//! bubbling, cycle detection, spawn orchestration) has moved into the
//! dspatch-router binary running inside the container.
//!
//! EventService responsibilities:
//! - Persist output packages to DB via on_output_packet delegate
//! - Forward state reports / heartbeats (handled by ConnectionService)
//! - Track active run IDs per workspace

use std::collections::HashMap;
use std::sync::{Arc, RwLock};

use tokio::sync::Mutex;

use crate::db::dao::WorkspaceDao;
use crate::domain::enums::AgentState;
use crate::domain::models::WorkspaceAgent;
use crate::util::new_id;

use super::packages::*;

// ── Callback types ──────────────────────────────────────────────────

pub type OnOutputPacketFn =
    Arc<dyn Fn(String, String, String, Package) + Send + Sync>;

pub type OnTurnCompletedFn =
    Arc<dyn Fn(String, String, String, String, String) + Send + Sync>;

/// Simplified event processing service.
///
/// - Parses agent events and delegates output-packet persistence
/// - Manages active run tracking
pub struct EventService {
    pub workspace_dao: Arc<WorkspaceDao>,

    // ── Delegates for output + status ──
    pub on_output_packet: Mutex<Option<OnOutputPacketFn>>,
    pub on_turn_completed: Mutex<Option<OnTurnCompletedFn>>,

    // ── Active run tracking ──
    /// Uses `std::sync::RwLock` so sync callbacks can look up run IDs
    /// without spawning OS threads.
    active_run_ids: RwLock<HashMap<String, String>>,
    run_id_to_workspace_id: RwLock<HashMap<String, String>>,
}

impl EventService {
    pub fn new(workspace_dao: Arc<WorkspaceDao>) -> Self {
        Self {
            workspace_dao,
            on_output_packet: Mutex::new(None),
            on_turn_completed: Mutex::new(None),
            active_run_ids: RwLock::new(HashMap::new()),
            run_id_to_workspace_id: RwLock::new(HashMap::new()),
        }
    }

    // ── Active run tracking ──

    pub fn register_workspace_run(&self, workspace_id: &str, run_id: &str) {
        self.active_run_ids
            .write()
            .unwrap_or_else(|e| e.into_inner())
            .insert(workspace_id.to_string(), run_id.to_string());
        self.run_id_to_workspace_id
            .write()
            .unwrap_or_else(|e| e.into_inner())
            .insert(run_id.to_string(), workspace_id.to_string());
    }

    pub fn deregister_workspace_run(&self, workspace_id: &str) {
        let run_id = self.active_run_ids.write().unwrap_or_else(|e| e.into_inner()).remove(workspace_id);
        if let Some(run_id) = run_id {
            self.run_id_to_workspace_id.write().unwrap_or_else(|e| e.into_inner()).remove(&run_id);
        }
    }

    /// Sync-safe active run ID lookup.
    pub fn active_run_id(&self, workspace_id: &str) -> Option<String> {
        self.active_run_ids
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .get(workspace_id)
            .cloned()
    }

    /// Sync-safe workspace ID lookup by run ID.
    pub fn workspace_id_for_run(&self, run_id: &str) -> Option<String> {
        self.run_id_to_workspace_id
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .get(run_id)
            .cloned()
    }

    // ── Workspace registration (simplified) ──

    /// Register workspace agent hierarchy. Previously stored flat_agents and
    /// hierarchies for routing; now a no-op since the router owns that data.
    pub async fn register_workspace(
        &self,
        _workspace_id: &str,
        _agents: &[crate::workspace_config::flat_agent::FlatAgent],
    ) {
        // No-op: router owns agent hierarchy now.
    }

    /// Remove workspace data. Previously cleaned up hierarchies, flat_agents,
    /// pending bubbles, and timers. Now just deregisters the run.
    pub async fn remove_workspace(&self, workspace_id: &str) {
        self.deregister_workspace_run(workspace_id);
    }

    // ── Event dispatch ──

    /// Handle an inbound package from the router.
    ///
    /// The engine receives all packages from the router over a single WebSocket.
    /// Its job is to persist output and forward commands.
    pub async fn handle_event(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: Package,
    ) {
        match event {
            // Output packages → persist to DB via on_output_packet delegate
            Package::Message(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event).await;
            }
            Package::PromptReceived(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event).await;
            }
            Package::Activity(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event).await;
            }
            Package::Log(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event).await;
            }
            Package::Usage(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event).await;
            }
            Package::Files(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event).await;
            }
            // StateReport and Heartbeat are handled by ConnectionService/StatusService
            // via their own callbacks — nothing to do here.
            Package::StateReport(_) | Package::Heartbeat(_) => {}
            // InquiryRequest: the router surfaces inquiries that need user attention.
            // The engine persists them to DB (table invalidation notifies the UI).
            Package::InquiryRequest(ref pkg) => {
                self.handle_inquiry_create(workspace_id, agent_key, pkg).await;
            }
            // TalkToResponse: the router completed a talk_to chain and is reporting
            // the result. Persist the instance result row and fire on_turn_completed.
            Package::TalkToResponse(ref pkg) => {
                self.handle_talk_to_response(workspace_id, agent_key, pkg).await;
            }
            _ => {
                tracing::debug!(
                    type_str = event.type_str(),
                    "Ignoring package type in EventService"
                );
            }
        }
    }

    async fn handle_output(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: &Package,
    ) {
        let run_id = {
            let ids = self.active_run_ids.read().unwrap_or_else(|e| e.into_inner());
            match ids.get(workspace_id) {
                Some(id) => id.clone(),
                None => return,
            }
        };

        let cb = self.on_output_packet.lock().await;
        if let Some(ref cb) = *cb {
            cb(
                workspace_id.to_string(),
                agent_key.to_string(),
                run_id,
                event.clone(),
            );
        }
    }

    async fn handle_talk_to_response(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: &TalkToResponsePackage,
    ) {
        // Insert InstanceResult row if we have a turn_id.
        if let Some(ref turn_id) = event.turn_id {
            let run_id = self.active_run_id(workspace_id);
            if let Some(ref run_id) = run_id {
                let result_id = new_id();
                let _ = self.workspace_dao.insert_instance_result(
                    &result_id,
                    run_id,
                    agent_key,
                    &event.instance_id,
                    turn_id,
                    Some(&event.request_id),
                );

                // Assemble transcript and fire on_turn_completed.
                let transcript = self.assemble_transcript(&event.instance_id, turn_id).await;
                let cb = self.on_turn_completed.lock().await;
                if let Some(ref cb) = *cb {
                    cb(
                        workspace_id.to_string(),
                        agent_key.to_string(),
                        event.instance_id.clone(),
                        turn_id.clone(),
                        transcript,
                    );
                }
            }
        }
    }

    async fn handle_inquiry_create(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: &InquiryRequestPackage,
    ) {
        let run_id = {
            let ids = self.active_run_ids.read().unwrap_or_else(|e| e.into_inner());
            match ids.get(workspace_id) {
                Some(id) => id.clone(),
                None => return,
            }
        };

        // Create inquiry in DB.
        let priority = match event.priority {
            WireInquiryPriority::Normal => crate::domain::enums::InquiryPriority::Normal,
            WireInquiryPriority::High => crate::domain::enums::InquiryPriority::High,
            WireInquiryPriority::Urgent => crate::domain::enums::InquiryPriority::Urgent,
        };
        let inquiry = crate::domain::models::WorkspaceInquiry {
            id: event.inquiry_id.clone(),
            run_id: run_id.clone(),
            agent_key: agent_key.to_string(),
            instance_id: event.instance_id.clone(),
            status: crate::domain::enums::InquiryStatus::Pending,
            priority,
            content_markdown: event.content_markdown.clone(),
            attachments_json: None,
            suggestions_json: if event.suggestions.is_empty() {
                None
            } else {
                Some(serde_json::to_string(&event.suggestions).unwrap_or_default())
            },
            response_text: None,
            response_suggestion_index: None,
            responded_by_agent_key: None,
            forwarding_chain_json: None,
            created_at: chrono::Utc::now().naive_utc(),
            responded_at: None,
        };
        let _ = self.workspace_dao.insert_workspace_inquiry(&inquiry);
        // Table invalidation handles notification to consumers (UI).
    }

    /// Assembles a compressed transcript from DB records for a given instance
    /// and turn. Only includes the agent's own output messages (role != "user"),
    /// not received prompts. Activities are counted and shown as summary lines
    /// between messages (e.g. "--- 3 activities recorded ---").
    pub async fn assemble_transcript(
        &self,
        instance_id: &str,
        turn_id: &str,
    ) -> String {
        // Fetch messages, excluding role=user (prompts / talk_to requests).
        let messages = match self.workspace_dao.get_messages_for_turn(instance_id, turn_id) {
            Ok(all) => all.into_iter().filter(|m| m.role != "user").collect::<Vec<_>>(),
            Err(e) => {
                tracing::warn!(
                    instance_id, turn_id, error = %e,
                    "Failed to fetch messages for transcript assembly"
                );
                Vec::new()
            }
        };

        // Fetch activities (only used for counting, not content).
        let activities = match self
            .workspace_dao
            .get_activities_for_turn(instance_id, turn_id)
        {
            Ok(a) => a,
            Err(e) => {
                tracing::warn!(
                    instance_id, turn_id, error = %e,
                    "Failed to fetch activities for transcript assembly"
                );
                Vec::new()
            }
        };

        // Merge messages and activities by timestamp, then build transcript.
        enum Entry {
            Message { content: String },
            Activity,
        }
        let mut timeline: Vec<(chrono::NaiveDateTime, Entry)> = Vec::new();
        for msg in &messages {
            timeline.push((msg.created_at, Entry::Message { content: msg.content.clone() }));
        }
        for act in &activities {
            timeline.push((act.timestamp, Entry::Activity));
        }
        timeline.sort_by_key(|(ts, _)| *ts);

        let mut buf = String::new();
        let mut activity_count: usize = 0;

        for (_, entry) in &timeline {
            match entry {
                Entry::Message { content } => {
                    if activity_count > 0 {
                        let word = if activity_count == 1 { "activity" } else { "activities" };
                        buf.push_str(&format!("\n--- {} {} recorded ---\n", activity_count, word));
                        activity_count = 0;
                    }
                    if !buf.is_empty() {
                        buf.push('\n');
                    }
                    buf.push_str(content);
                }
                Entry::Activity => {
                    activity_count += 1;
                }
            }
        }
        if activity_count > 0 {
            let word = if activity_count == 1 { "activity" } else { "activities" };
            buf.push_str(&format!("\n--- {} {} recorded ---\n", activity_count, word));
        }

        buf
    }

    /// Creates a WorkspaceAgent DB row with generated display name and status.
    ///
    /// Idempotent — skips insertion if a row for this instance_id already exists.
    pub async fn create_instance_row(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
        initial_state: AgentState,
    ) {
        let run_id = match self.active_run_id(workspace_id) {
            Some(id) => id,
            None => return,
        };

        // Skip if a row already exists (race between heartbeat and spawn).
        if let Ok(Some(_)) = self.workspace_dao.find_workspace_agent_by_instance_id(&run_id, instance_id) {
            return;
        }

        // Generate a short 4-char hex display name.
        let display_name = format!("{:04x}", rand::random::<u16>());

        let now = chrono::Utc::now().naive_utc();
        let agent = WorkspaceAgent {
            id: new_id(),
            run_id,
            agent_key: agent_key.to_string(),
            instance_id: instance_id.to_string(),
            display_name,
            chain_json: String::new(),
            status: initial_state,
            created_at: now,
            updated_at: now,
        };
        let _ = self.workspace_dao.insert_workspace_agent(&agent);
        // Table invalidation handles notification to consumers.
    }

    /// Deletes a stale disconnected instance row from the DB.
    pub async fn cleanup_instance(
        &self,
        _workspace_id: &str,
        _agent_key: &str,
        instance_id: &str,
    ) {
        let _ = self
            .workspace_dao
            .delete_workspace_agent_by_instance_id(instance_id);
        tracing::info!(instance_id, "Cleaned up stale instance row");
    }

    /// Deletes ALL disconnected instance rows for an agent. Returns count deleted.
    pub async fn cleanup_stale_instances(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) -> usize {
        let run_id = match self.active_run_id(workspace_id) {
            Some(id) => id,
            None => return 0,
        };

        let agents = match self.workspace_dao.get_workspace_agents(&run_id) {
            Ok(a) => a,
            Err(_) => return 0,
        };

        let mut count = 0;
        for agent in agents {
            if agent.agent_key == agent_key && agent.status == AgentState::Disconnected {
                let _ = self
                    .workspace_dao
                    .delete_workspace_agent_by_instance_id(&agent.instance_id);
                count += 1;
            }
        }
        if count > 0 {
            tracing::info!(agent_key, count, "Cleaned up stale instances");
        }
        count
    }
}
