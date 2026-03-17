// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A discrete activity event from an agent within a workspace.
///
/// Activity events capture tool calls, status changes, and other
/// agent-reported events. The [`event_type`] categorises the event,
/// and [`data_json`] carries event-specific payload as a JSON string.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct AgentActivity {
    pub id: String,
    pub run_id: String,
    pub agent_key: String,
    pub instance_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,
    pub event_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data_json: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub content: Option<String>,
    pub timestamp: NaiveDateTime,
}
