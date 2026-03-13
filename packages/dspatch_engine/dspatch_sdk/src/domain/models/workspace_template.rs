// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A reusable workspace blueprint sourced from the community hub.
///
/// Contains the full workspace configuration ([`config_yaml`]) and a list of
/// agent template references ([`agent_refs`]) needed to instantiate the workspace.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceTemplate {
    pub id: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    pub hub_slug: String,
    pub hub_author: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_category: Option<String>,
    #[serde(default)]
    pub hub_tags: Vec<String>,
    pub hub_version: i64,
    pub config_yaml: String,
    #[serde(default)]
    pub agent_refs: Vec<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
