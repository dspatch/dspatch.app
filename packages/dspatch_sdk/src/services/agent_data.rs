// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local agent data service — wraps WorkspaceDao methods.

use std::pin::Pin;
use std::sync::Arc;

use futures::Stream;

use crate::db::dao::WorkspaceDao;
use crate::domain::models::{AgentLog, AgentMessage};
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

    /// Returns a stream of agent messages for the given run and instance.
    pub fn watch_agent_messages(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Pin<Box<dyn Stream<Item = Vec<AgentMessage>> + Send>> {
        use futures::StreamExt;
        let stream = self.dao.watch_agent_messages(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async { r.ok() }))
    }

    /// Returns a stream of agent logs for the given run, optionally filtered
    /// by instance.
    pub fn watch_agent_logs(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> Pin<Box<dyn Stream<Item = Vec<AgentLog>> + Send>> {
        use futures::StreamExt;
        let stream = self.dao.watch_agent_logs(run_id, instance_id);
        Box::pin(stream.filter_map(|r| async { r.ok() }))
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
