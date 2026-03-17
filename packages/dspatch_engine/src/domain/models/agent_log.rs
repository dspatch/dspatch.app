// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use crate::domain::enums::{LogLevel, LogSource};

/// A log entry produced by or about an agent within a workspace.
///
/// Logs are scoped to a specific agent instance via [`agent_key`] and
/// [`instance_id`]. The [`source`] indicates whether the log came from
/// the agent itself or from the engine infrastructure.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct AgentLog {
    pub id: String,
    pub run_id: String,
    pub agent_key: String,
    pub instance_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,
    pub level: LogLevel,
    pub message: String,
    pub source: LogSource,
    pub timestamp: NaiveDateTime,
}
