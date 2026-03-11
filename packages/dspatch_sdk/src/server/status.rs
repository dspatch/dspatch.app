// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Agent state machine — drives agent and workspace state transitions.
//!
//! Ported from `server/status_service.dart`.

use std::sync::Arc;

use crate::db::dao::WorkspaceDao;
use crate::domain::enums::AgentState;

use super::event::EventService;
use super::event_bus::{SdkEvent, SdkEventBus};

/// Drives agent and workspace state transitions based on signals from
/// ConnectionService, EventService, and ContainerService.
pub struct StatusService {
    workspace_dao: Arc<WorkspaceDao>,
    event_service: Arc<EventService>,
    event_bus: Arc<SdkEventBus>,
}

impl StatusService {
    pub fn new(
        workspace_dao: Arc<WorkspaceDao>,
        event_service: Arc<EventService>,
        event_bus: Arc<SdkEventBus>,
    ) -> Self {
        Self {
            workspace_dao,
            event_service,
            event_bus,
        }
    }

    // ── Agent state transitions ──

    /// Try to transition an agent's status. Returns true if applied.
    pub async fn try_transition(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
        new_status: AgentState,
        tag: &str,
    ) -> bool {
        let run_id = match self.event_service.active_run_id(workspace_id) {
            Some(id) => id,
            None => return false,
        };

        let agent = match self
            .workspace_dao
            .find_workspace_agent_by_instance_id(&run_id, instance_id)
        {
            Ok(Some(agent)) => agent,
            _ => return false,
        };

        let current = agent.status;
        if current == new_status {
            return false;
        }
        if !current.can_transition_to(new_status) {
            tracing::warn!(
                tag,
                current = ?current,
                new = ?new_status,
                agent_key,
                "Invalid status transition"
            );
            return false;
        }

        if let Err(e) = self
            .workspace_dao
            .update_agent_status(instance_id, &new_status)
        {
            tracing::warn!(
                tag,
                agent_key,
                error = %e,
                "Failed to update agent status"
            );
            return false;
        }

        tracing::info!(
            tag,
            current = ?current,
            new = ?new_status,
            agent_key,
            "Agent status changed"
        );

        self.event_bus.emit(SdkEvent::InstanceStateChanged {
            workspace_id: workspace_id.to_string(),
            agent_key: agent_key.to_string(),
            instance_id: instance_id.to_string(),
            old_state: current.to_wire().to_string(),
            new_state: new_status.to_wire().to_string(),
        });

        true
    }

    // ── Handler methods ──

    /// Called when a heartbeat reports a new or changed instance state.
    ///
    /// If the instance has no DB row yet (e.g. the Python agent spawned it
    /// autonomously), we create one on-the-fly so the UI can show it.
    pub async fn handle_instance_state_changed(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
        old_state: Option<&str>,
        new_state: &str,
    ) {
        let status = match AgentState::from_wire(new_state) {
            Some(s) => s,
            None => {
                tracing::warn!(
                    new_state,
                    agent_key,
                    instance_id,
                    "Unknown agent status"
                );
                return;
            }
        };

        // If this is a brand-new instance (old_state is None), ensure a DB
        // row exists. create_instance_row is idempotent — it skips insertion
        // if the row already exists (e.g. after app restart or race with spawn).
        if old_state.is_none() {
            self.event_service
                .create_instance_row(workspace_id, agent_key, instance_id, status)
                .await;
        }

        self.try_transition(
            workspace_id,
            agent_key,
            instance_id,
            status,
            "heartbeat",
        )
        .await;
    }

    /// Called when a previously-reported instance disappears from heartbeat.
    pub async fn handle_instance_gone(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
        _last_state: &str,
    ) {
        self.try_transition(
            workspace_id,
            agent_key,
            instance_id,
            AgentState::Disconnected,
            "heartbeat-gone",
        )
        .await;
        self.event_bus.emit(SdkEvent::InstanceGone {
            workspace_id: workspace_id.to_string(),
            agent_key: agent_key.to_string(),
            instance_id: instance_id.to_string(),
        });
    }

    /// Called when an agent establishes a WebSocket connection.
    pub async fn handle_agent_connected(&self, workspace_id: &str, agent_key: &str) {
        tracing::info!(agent_key, workspace_id, "Agent connected");
        self.event_bus.emit(SdkEvent::AgentConnected {
            workspace_id: workspace_id.to_string(),
            agent_key: agent_key.to_string(),
        });
    }

    /// Called when an agent's WebSocket connection drops.
    /// Marks all instances of this agent as disconnected.
    pub async fn handle_agent_disconnected(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) {
        let run_id = match self.event_service.active_run_id(workspace_id) {
            Some(id) => id,
            None => return,
        };

        match self.workspace_dao.get_workspace_agents(&run_id) {
            Ok(agents) => {
                for agent in agents {
                    if agent.agent_key != agent_key {
                        continue;
                    }
                    let current = agent.status;
                    if !current.is_terminal() && current != AgentState::Disconnected {
                        let _ = self.workspace_dao.update_agent_status(
                            &agent.instance_id,
                            &AgentState::Disconnected,
                        );
                    }
                }
            }
            Err(e) => {
                tracing::warn!(
                    agent_key,
                    workspace_id,
                    error = %e,
                    "Failed to mark agent disconnected"
                );
            }
        }
        self.event_bus.emit(SdkEvent::AgentDisconnected {
            workspace_id: workspace_id.to_string(),
            agent_key: agent_key.to_string(),
        });
    }

    /// Called when a container exits (from ContainerService monitoring).
    pub async fn handle_container_exited(
        &self,
        workspace_id: &str,
        _exit_code: Option<i32>,
    ) {
        self.mark_all_agents_disconnected(workspace_id).await;

        let active_run = match self.workspace_dao.get_active_run(workspace_id) {
            Ok(Some(run)) => run,
            _ => return,
        };

        let status = &active_run.status;
        let now = chrono::Utc::now().naive_utc();

        if status == "stopping" {
            let _ = self.workspace_dao.update_run_status(
                &active_run.id,
                "stopped",
                Some(&now),
            );
            self.event_bus.emit(SdkEvent::WorkspaceRunStopped {
                workspace_id: workspace_id.to_string(),
                run_id: active_run.id.clone(),
            });
        } else if status == "running" || status == "starting" {
            let _ = self.workspace_dao.update_run_status(
                &active_run.id,
                "failed",
                Some(&now),
            );
            self.event_bus.emit(SdkEvent::WorkspaceRunFailed {
                workspace_id: workspace_id.to_string(),
                run_id: active_run.id.clone(),
            });
        }
    }

    /// Called when a container health check fails.
    pub async fn handle_health_check_failed(
        &self,
        workspace_id: &str,
        container_id: &str,
        state: &str,
    ) {
        tracing::warn!(
            workspace_id,
            container_id,
            state,
            "Health check failed"
        );

        let active_run = match self.workspace_dao.get_active_run(workspace_id) {
            Ok(Some(run)) => run,
            _ => return,
        };

        if active_run.status == "running" || active_run.status == "starting" {
            let now = chrono::Utc::now().naive_utc();
            let _ = self.workspace_dao.update_run_status(
                &active_run.id,
                "failed",
                Some(&now),
            );
            self.event_bus.emit(SdkEvent::WorkspaceRunFailed {
                workspace_id: workspace_id.to_string(),
                run_id: active_run.id.clone(),
            });
        }
    }

    /// Called by EventService when an agent turn completes.
    pub async fn handle_turn_completed(
        &self,
        workspace_id: &str,
        agent_name: &str,
        instance_id: &str,
        _turn_id: &str,
        _transcript: &str,
    ) {
        self.try_transition(
            workspace_id,
            agent_name,
            instance_id,
            AgentState::Idle,
            "turn-completed",
        )
        .await;
    }

    // ── Bulk operations ──

    /// Marks all non-terminal agents in a workspace as disconnected.
    pub async fn mark_all_agents_disconnected(&self, workspace_id: &str) {
        let run_id = match self.event_service.active_run_id(workspace_id) {
            Some(id) => id,
            None => return,
        };

        if let Ok(agents) = self.workspace_dao.get_workspace_agents(&run_id) {
            for agent in agents {
                let current = agent.status;
                if !current.is_terminal() && current != AgentState::Disconnected {
                    let _ = self.workspace_dao.update_agent_status(
                        &agent.instance_id,
                        &AgentState::Disconnected,
                    );
                }
            }
        }
    }
}
