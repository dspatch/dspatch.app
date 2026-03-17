// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use crate::domain::enums::SourceType;

/// A reusable agent definition that can be assigned to workspaces.
///
/// Providers define the source code location ([`source_type`] + [`source_path`] or
/// [`git_url`]), the process [`entry_point`], and a list of environment variable
/// key names ([`required_env`]) that must be provided at the workspace level.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct AgentProvider {
    pub id: String,
    pub name: String,
    pub source_type: SourceType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub git_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub git_branch: Option<String>,
    pub entry_point: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub readme: Option<String>,
    #[serde(default)]
    pub required_env: Vec<String>,
    #[serde(default)]
    pub required_mounts: Vec<String>,
    #[serde(default)]
    pub fields: HashMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_slug: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_author: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_category: Option<String>,
    #[serde(default)]
    pub hub_tags: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_version: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_repo_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_commit_hash: Option<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
