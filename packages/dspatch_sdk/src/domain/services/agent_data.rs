// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::util::result::Result;

/// Read/write access to agent runtime data within workspace runs.
#[async_trait]
pub trait AgentDataService: Send + Sync {
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
