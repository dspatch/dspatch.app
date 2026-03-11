// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::{
    AgentActivity, AgentFile, AgentLog, AgentMessage, AgentUsage, WorkspaceAgent,
};
use crate::util::result::Result;

use super::WatchStream;

/// Read/write access to agent runtime data within workspace runs.
#[async_trait]
pub trait AgentDataService: Send + Sync {
    /// Watches all agents for a workspace run.
    fn watch_workspace_agents(&self, run_id: &str) -> WatchStream<Vec<WorkspaceAgent>>;

    /// Watches messages for a specific agent instance within a run.
    fn watch_agent_messages(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> WatchStream<Vec<AgentMessage>>;

    /// Watches activity entries for a specific agent instance within a run.
    fn watch_agent_activity(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> WatchStream<Vec<AgentActivity>>;

    /// Watches log entries for a run, optionally filtered by `instance_id`.
    fn watch_agent_logs(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> WatchStream<Vec<AgentLog>>;

    /// Watches usage entries for a run, optionally filtered by `instance_id`.
    fn watch_agent_usage(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> WatchStream<Vec<AgentUsage>>;

    /// Watches file entries for a run, optionally filtered by `instance_id`.
    fn watch_agent_files(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> WatchStream<Vec<AgentFile>>;

    /// Sends user text input to a specific agent instance.
    async fn send_user_input_to_agent(
        &self,
        run_id: &str,
        instance_id: &str,
        text: &str,
    ) -> Result<()>;

    /// Sends an interrupt signal to a specific agent instance.
    async fn interrupt_instance(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Result<()>;
}
