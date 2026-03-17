// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use crate::domain::enums::AgentState;

/// An agent instance within a workspace run.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct WorkspaceAgent {
    pub id: String,
    pub run_id: String,
    pub agent_key: String,
    pub instance_id: String,
    pub display_name: String,
    #[serde(default)]
    pub chain_json: String,
    pub status: AgentState,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
