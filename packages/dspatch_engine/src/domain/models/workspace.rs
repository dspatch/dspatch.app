// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A workspace containing one or more agents.
///
/// A workspace defines the project and its agent configuration.
/// Runtime state (containers, ports) is tracked by [`WorkspaceRun`].
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct Workspace {
    pub id: String,
    pub name: String,
    pub project_path: String,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
