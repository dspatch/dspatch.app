// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local agent data service — wraps WorkspaceDao watch methods.

use std::sync::Arc;

use futures::StreamExt;

use crate::db::dao::WorkspaceDao;
use crate::domain::models::{
    AgentActivity, AgentFile, AgentLog, AgentMessage, AgentUsage, WorkspaceAgent,
};
use crate::domain::services::WatchStream;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Callback type for sending user input to an agent via the connection layer.
///
/// Takes (run_id, instance_id, text) and returns whether the send succeeded.
pub type SendUserInputFn =
    Arc<dyn Fn(&str, &str, &str) -> std::result::Result<(), String> + Send + Sync>;

/// Callback type for sending an interrupt signal to an agent instance.
///
/// Takes (run_id, instance_id) and returns whether the send succeeded.
pub type InterruptInstanceFn =
    Arc<dyn Fn(&str, &str) -> std::result::Result<(), String> + Send + Sync>;

/// Local implementation of agent data service backed by [`WorkspaceDao`].
///
/// For `send_user_input_to_agent` and `interrupt_instance`, optional callbacks
/// are used since the connection layer is wired up later by the facade.
pub struct LocalAgentDataService {
    dao: Arc<WorkspaceDao>,
    send_user_input: std::sync::RwLock<Option<SendUserInputFn>>,
    interrupt_instance: std::sync::RwLock<Option<InterruptInstanceFn>>,
}

impl LocalAgentDataService {
    pub fn new(dao: Arc<WorkspaceDao>) -> Self {
        Self {
            dao,
            send_user_input: std::sync::RwLock::new(None),
            interrupt_instance: std::sync::RwLock::new(None),
        }
    }

    /// Returns a reference to the underlying WorkspaceDao.
    pub fn dao(&self) -> Arc<WorkspaceDao> {
        Arc::clone(&self.dao)
    }

    /// Sets the callback for sending user input to agents.
    ///
    /// Uses interior mutability so this works through `Arc<Self>`.
    pub fn set_send_user_input(&self, callback: SendUserInputFn) {
        *self.send_user_input.write().unwrap_or_else(|e| e.into_inner()) = Some(callback);
    }

    /// Returns a reference to the internal send_user_input lock (for checking if wired).
    pub fn send_user_input_ref(&self) -> &std::sync::RwLock<Option<SendUserInputFn>> {
        &self.send_user_input
    }

    /// Sets the callback for interrupting agent instances.
    pub fn set_interrupt_instance(&self, callback: InterruptInstanceFn) {
        *self.interrupt_instance.write().unwrap_or_else(|e| e.into_inner()) = Some(callback);
    }

    /// Watches all agents for a workspace run.
    pub fn watch_workspace_agents(&self, run_id: &str) -> WatchStream<Vec<WorkspaceAgent>> {
        let stream = self.dao.watch_workspace_agents(run_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspace_agents error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches messages for a specific agent instance within a run.
    pub fn watch_agent_messages(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> WatchStream<Vec<AgentMessage>> {
        let stream = self.dao.watch_agent_messages(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_agent_messages error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches activity entries for a specific agent instance within a run.
    pub fn watch_agent_activity(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> WatchStream<Vec<AgentActivity>> {
        let stream = self.dao.watch_agent_activity(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_agent_activity error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches log entries for a run, optionally filtered by `instance_id`.
    pub fn watch_agent_logs(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> WatchStream<Vec<AgentLog>> {
        let stream = self.dao.watch_agent_logs(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_agent_logs error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches usage entries for a run, optionally filtered by `instance_id`.
    pub fn watch_agent_usage(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> WatchStream<Vec<AgentUsage>> {
        let stream = self.dao.watch_agent_usage(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_agent_usage error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches file entries for a run, optionally filtered by `instance_id`.
    pub fn watch_agent_files(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> WatchStream<Vec<AgentFile>> {
        let stream = self.dao.watch_agent_files(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_agent_files error: {e}");
                    None
                }
            }
        }))
    }

    /// Sends user text input to a specific agent instance.
    ///
    /// Delegates to the registered callback. Returns an error if no callback
    /// is registered or if the send fails.
    pub async fn send_user_input_to_agent(
        &self,
        run_id: &str,
        instance_id: &str,
        text: &str,
    ) -> Result<()> {
        let guard = self.send_user_input.read().unwrap_or_else(|e| e.into_inner());
        let callback = guard.as_ref().ok_or_else(|| {
            AppError::Server("Connection service not wired up yet".to_string())
        })?;
        callback(run_id, instance_id, text).map_err(|e| AppError::Server(e))
    }

    /// Sends an interrupt signal to a specific agent instance.
    ///
    /// Delegates to the registered callback. Returns an error if no callback
    /// is registered or if the send fails.
    pub async fn interrupt_instance(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Result<()> {
        let guard = self.interrupt_instance.read().unwrap_or_else(|e| e.into_inner());
        let callback = guard.as_ref().ok_or_else(|| {
            AppError::Server("Connection service not wired up yet".to_string())
        })?;
        callback(run_id, instance_id).map_err(|e| AppError::Server(e))
    }
}
