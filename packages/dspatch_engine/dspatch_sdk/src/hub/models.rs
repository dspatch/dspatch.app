// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Community Hub data models.
//!
//! Ported from `data/hub/hub_models.dart`.

use serde::{Deserialize, Serialize};

/// A lightweight tag reference embedded in summaries.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubTagRef {
    pub slug: String,
    #[serde(rename = "display_name")]
    pub display_name: String,
    pub category: String,
}

/// Full tag model returned by tag-search endpoints (includes id + usage count).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubTag {
    pub id: i64,
    pub slug: String,
    #[serde(rename = "display_name")]
    pub display_name: String,
    pub category: String,
    #[serde(rename = "usage_count", default)]
    pub usage_count: i64,
}

/// Summary of a community-shared agent listing.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubAgentSummary {
    pub slug: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub author: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Vec<HubTagRef>,
    #[serde(default)]
    pub stars: i64,
    #[serde(default)]
    pub downloads: i64,
    #[serde(default)]
    pub verified: bool,
    #[serde(default)]
    pub version: i64,
    #[serde(rename = "user_liked", default)]
    pub user_liked: bool,
    /// `"provider"` (default) or `"template"`.
    #[serde(default = "default_agent_type")]
    pub agent_type: String,
    /// For templates: the provider slug they reference.
    #[serde(rename = "source_slug", skip_serializing_if = "Option::is_none")]
    pub source_slug: Option<String>,
}

fn default_agent_type() -> String {
    "provider".to_string()
}

/// Resolved agent details including repo URL and build info.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubAgentResolve {
    #[serde(rename = "repo_url", skip_serializing_if = "Option::is_none")]
    pub repo_url: Option<String>,
    #[serde(rename = "commit_hash", skip_serializing_if = "Option::is_none")]
    pub commit_hash: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,
    #[serde(rename = "entry_point", skip_serializing_if = "Option::is_none")]
    pub entry_point: Option<String>,
    #[serde(rename = "sdk_version", skip_serializing_if = "Option::is_none")]
    pub sdk_version: Option<String>,
    pub version: i64,
    /// For templates: the dspatch.agent.yml content.
    #[serde(rename = "config_yaml", skip_serializing_if = "Option::is_none")]
    pub config_yaml: Option<String>,
    /// For templates: the backing provider slug.
    #[serde(rename = "source_slug", skip_serializing_if = "Option::is_none")]
    pub source_slug: Option<String>,
}

/// Summary of a community-shared workspace listing.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubWorkspaceSummary {
    pub slug: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub author: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    #[serde(default)]
    pub tags: Vec<HubTagRef>,
    #[serde(default)]
    pub stars: i64,
    #[serde(default)]
    pub downloads: i64,
    #[serde(default)]
    pub verified: bool,
    #[serde(default)]
    pub version: i64,
    #[serde(rename = "user_liked", default)]
    pub user_liked: bool,
    #[serde(rename = "agent_count", default)]
    pub agent_count: i64,
}

/// Resolved workspace details including inline config and agent references.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubWorkspaceResolve {
    #[serde(rename = "config_json")]
    pub config_yaml: serde_json::Value,
    #[serde(rename = "agent_refs", default)]
    pub agent_refs: Vec<String>,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    pub version: i64,
}

/// Version info for checking whether a hub listing has been updated.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubVersionInfo {
    pub slug: String,
    #[serde(rename = "latest_version")]
    pub latest_version: i64,
    #[serde(rename = "updated_at")]
    pub updated_at: String,
}

/// Cursor-based pagination metadata returned alongside list results.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubPagination {
    #[serde(rename = "per_page")]
    pub per_page: i64,
    #[serde(rename = "next_cursor", skip_serializing_if = "Option::is_none")]
    pub next_cursor: Option<String>,
    #[serde(rename = "has_more")]
    pub has_more: bool,
}

/// Category with its listing count, used for filter UI.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HubCategoryCount {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    pub count: i64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hub_agent_summary_serde_roundtrip() {
        let summary = HubAgentSummary {
            slug: "my-agent".to_string(),
            name: "My Agent".to_string(),
            description: Some("A test agent".to_string()),
            author: Some("oak".to_string()),
            category: Some("general".to_string()),
            tags: vec![HubTagRef {
                slug: "python".to_string(),
                display_name: "Python".to_string(),
                category: "language".to_string(),
            }],
            stars: 42,
            downloads: 100,
            verified: true,
            version: 3,
            user_liked: false,
            agent_type: "provider".to_string(),
            source_slug: None,
        };
        let json = serde_json::to_string(&summary).unwrap();
        let deserialized: HubAgentSummary = serde_json::from_str(&json).unwrap();
        assert_eq!(summary, deserialized);
    }

    #[test]
    fn hub_workspace_summary_serde_roundtrip() {
        let summary = HubWorkspaceSummary {
            slug: "my-workspace".to_string(),
            name: "My Workspace".to_string(),
            description: None,
            author: None,
            category: None,
            tags: vec![],
            stars: 0,
            downloads: 0,
            verified: false,
            version: 1,
            user_liked: false,
            agent_count: 3,
        };
        let json = serde_json::to_string(&summary).unwrap();
        let deserialized: HubWorkspaceSummary = serde_json::from_str(&json).unwrap();
        assert_eq!(summary, deserialized);
    }

    #[test]
    fn hub_agent_resolve_serde_roundtrip() {
        let resolve = HubAgentResolve {
            repo_url: Some("https://github.com/oak/agent".to_string()),
            commit_hash: Some("abc123".to_string()),
            branch: Some("main".to_string()),
            entry_point: Some("main.py".to_string()),
            sdk_version: Some("0.1.0".to_string()),
            version: 5,
            config_yaml: None,
            source_slug: None,
        };
        let json = serde_json::to_string(&resolve).unwrap();
        let deserialized: HubAgentResolve = serde_json::from_str(&json).unwrap();
        assert_eq!(resolve, deserialized);
    }

    #[test]
    fn hub_pagination_serde_roundtrip() {
        let pagination = HubPagination {
            per_page: 20,
            next_cursor: Some("abc".to_string()),
            has_more: true,
        };
        let json = serde_json::to_string(&pagination).unwrap();
        let deserialized: HubPagination = serde_json::from_str(&json).unwrap();
        assert_eq!(pagination, deserialized);
    }

    #[test]
    fn hub_version_info_serde_roundtrip() {
        let info = HubVersionInfo {
            slug: "my-agent".to_string(),
            latest_version: 7,
            updated_at: "2026-01-15T09:30:00Z".to_string(),
        };
        let json = serde_json::to_string(&info).unwrap();
        let deserialized: HubVersionInfo = serde_json::from_str(&json).unwrap();
        assert_eq!(info, deserialized);
    }

    #[test]
    fn hub_category_count_serde_roundtrip() {
        let cat = HubCategoryCount {
            category: Some("devops".to_string()),
            count: 15,
        };
        let json = serde_json::to_string(&cat).unwrap();
        let deserialized: HubCategoryCount = serde_json::from_str(&json).unwrap();
        assert_eq!(cat, deserialized);
    }

    #[test]
    fn hub_workspace_resolve_serde_roundtrip() {
        let resolve = HubWorkspaceResolve {
            config_yaml: serde_json::json!({"agents": []}),
            agent_refs: vec!["agent-1".to_string()],
            name: "Test WS".to_string(),
            description: Some("A workspace".to_string()),
            version: 2,
        };
        let json = serde_json::to_string(&resolve).unwrap();
        let deserialized: HubWorkspaceResolve = serde_json::from_str(&json).unwrap();
        assert_eq!(resolve, deserialized);
    }

    #[test]
    fn hub_tag_serde_roundtrip() {
        let tag = HubTag {
            id: 1,
            slug: "python".to_string(),
            display_name: "Python".to_string(),
            category: "language".to_string(),
            usage_count: 42,
        };
        let json = serde_json::to_string(&tag).unwrap();
        let deserialized: HubTag = serde_json::from_str(&json).unwrap();
        assert_eq!(tag, deserialized);
    }
}
