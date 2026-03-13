// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A file operation performed by an agent within a workspace.
///
/// Tracks file reads, writes, and deletes for audit and display
/// in the workspace files tab.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AgentFile {
    pub id: String,
    pub run_id: String,
    pub agent_key: String,
    pub instance_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,
    pub file_path: String,
    pub operation: String,
    pub timestamp: NaiveDateTime,
}
