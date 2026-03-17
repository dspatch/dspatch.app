// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::domain::enums::SourceType;

/// Value object carrying partial updates for an existing [`AgentProvider`].
///
/// Only non-null fields are applied. Used by the agent provider edit form.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct UpdateAgentProviderRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_type: Option<SourceType>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub git_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub git_branch: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entry_point: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub readme: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub required_env: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub required_mounts: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub fields: Option<HashMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_slug: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_author: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_category: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_tags: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_version: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_repo_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hub_commit_hash: Option<String>,
}
