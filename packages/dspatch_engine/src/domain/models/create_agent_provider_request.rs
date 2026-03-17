// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::domain::enums::SourceType;

/// Value object carrying all fields needed to create a new [`AgentProvider`].
///
/// Used by the agent provider form to bundle validated inputs before passing
/// them to the agent provider service.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct CreateAgentProviderRequest {
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
}
