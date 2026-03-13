// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A workspace directory recently used when creating a session.
///
/// Enables quick re-selection of previous project paths. [`is_git_repo`]
/// indicates whether the path contained a `.git` directory at last use.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RecentProject {
    pub id: String,
    pub path: String,
    pub name: String,
    #[serde(default)]
    pub is_git_repo: bool,
    pub last_used_at: NaiveDateTime,
}
