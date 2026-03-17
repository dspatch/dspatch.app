// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A single execution run of a workspace.
///
/// Tracks the container, server port, and lifecycle timestamps.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct WorkspaceRun {
    pub id: String,
    pub workspace_id: String,
    pub run_number: i64,
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub container_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub server_port: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api_key: Option<String>,
    pub started_at: NaiveDateTime,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stopped_at: Option<NaiveDateTime>,
}
