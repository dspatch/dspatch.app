// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! HTTP client for the d:spatch Community Hub API.
//!
//! Ported from `data/hub/hub_api_client.dart`.

use std::collections::HashMap;
use std::fmt;
use std::sync::RwLock;
use std::time::Duration;

use super::models::*;

/// HTTP client for the d:spatch Community Hub public and authenticated APIs.
///
/// Public endpoints (no auth required):
///   - Browse / search / resolve agents and workspaces
///   - Fetch categories and version info
///
/// Authenticated endpoints (require [`auth_token`](Self::auth_token)):
///   - Submit agents and workspaces
pub struct HubApiClient {
    base_url: String,
    auth_token: RwLock<Option<String>>,
    client: reqwest::Client,
}

impl HubApiClient {
    pub fn new(base_url: impl Into<String>, auth_token: Option<String>) -> Self {
        let client = reqwest::Client::builder()
            .connect_timeout(Duration::from_secs(10))
            .timeout(Duration::from_secs(30))
            .build()
            .expect("failed to build reqwest client");
        Self {
            base_url: base_url.into(),
            auth_token: RwLock::new(auth_token),
            client,
        }
    }

    /// Returns the base URL of this client.
    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    /// Returns a clone of the current auth token, if set.
    pub fn auth_token(&self) -> Option<String> {
        self.auth_token.read().unwrap_or_else(|e| e.into_inner()).clone()
    }

    /// Sets the auth token for authenticated endpoints.
    pub fn set_auth_token(&self, token: Option<String>) {
        *self.auth_token.write().unwrap_or_else(|e| e.into_inner()) = token;
    }

    // ─── Public -- Agents ─────────────────────────────────────────────

    /// Browse community agents with optional filtering and cursor-based pagination.
    pub async fn browse_agents(
        &self,
        cursor: Option<&str>,
        category: Option<&str>,
        search: Option<&str>,
        per_page: u32,
    ) -> Result<(Vec<HubAgentSummary>, HubPagination), HubApiException> {
        let mut params = HashMap::new();
        params.insert("per_page".to_string(), per_page.to_string());
        if let Some(c) = cursor {
            params.insert("cursor".to_string(), c.to_string());
        }
        if let Some(cat) = category {
            params.insert("category".to_string(), cat.to_string());
        }
        if let Some(s) = search {
            params.insert("search".to_string(), s.to_string());
        }

        let json = self.get("/public/agents", Some(&params)).await?;
        let data: Vec<HubAgentSummary> = serde_json::from_value(json["data"].clone())
            .unwrap_or_default();
        let pagination: HubPagination = serde_json::from_value(json["pagination"].clone())
            .map_err(|e| HubApiException::new(0, format!("pagination parse error: {e}")))?;
        Ok((data, pagination))
    }

    /// List available agent categories with counts.
    pub async fn agent_categories(&self) -> Result<Vec<HubCategoryCount>, HubApiException> {
        let json = self.get("/public/agents/categories", None).await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    /// Resolve an agent slug to its repo URL and build metadata.
    pub async fn resolve_agent(
        &self,
        slug: &str,
    ) -> Result<HubAgentResolve, HubApiException> {
        let json = self
            .get(&format!("/public/agents/resolve/{slug}"), None)
            .await?;
        let data = if json.get("data").is_some() {
            json["data"].clone()
        } else {
            json
        };
        serde_json::from_value(data)
            .map_err(|e| HubApiException::new(0, format!("parse error: {e}")))
    }

    /// Batch-check latest versions for a list of agent slugs.
    pub async fn agent_versions(
        &self,
        slugs: &[String],
    ) -> Result<Vec<HubVersionInfo>, HubApiException> {
        let mut params = HashMap::new();
        params.insert("slugs".to_string(), slugs.join(","));
        let json = self
            .get("/public/agents/versions", Some(&params))
            .await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    // ─── Public -- Workspaces ─────────────────────────────────────────

    /// Browse community workspaces with optional filtering and cursor-based pagination.
    pub async fn browse_workspaces(
        &self,
        cursor: Option<&str>,
        category: Option<&str>,
        search: Option<&str>,
        per_page: u32,
    ) -> Result<(Vec<HubWorkspaceSummary>, HubPagination), HubApiException> {
        let mut params = HashMap::new();
        params.insert("per_page".to_string(), per_page.to_string());
        if let Some(c) = cursor {
            params.insert("cursor".to_string(), c.to_string());
        }
        if let Some(cat) = category {
            params.insert("category".to_string(), cat.to_string());
        }
        if let Some(s) = search {
            params.insert("search".to_string(), s.to_string());
        }

        let json = self.get("/public/workspaces", Some(&params)).await?;
        let data: Vec<HubWorkspaceSummary> =
            serde_json::from_value(json["data"].clone()).unwrap_or_default();
        let pagination: HubPagination = serde_json::from_value(json["pagination"].clone())
            .map_err(|e| HubApiException::new(0, format!("pagination parse error: {e}")))?;
        Ok((data, pagination))
    }

    /// List available workspace categories with counts.
    pub async fn workspace_categories(&self) -> Result<Vec<HubCategoryCount>, HubApiException> {
        let json = self
            .get("/public/workspaces/categories", None)
            .await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    /// Resolve a workspace slug to its config YAML and agent references.
    pub async fn resolve_workspace(
        &self,
        slug: &str,
    ) -> Result<HubWorkspaceResolve, HubApiException> {
        let json = self
            .get(&format!("/public/workspaces/resolve/{slug}"), None)
            .await?;
        let data = if json.get("data").is_some() {
            json["data"].clone()
        } else {
            json
        };
        serde_json::from_value(data)
            .map_err(|e| HubApiException::new(0, format!("parse error: {e}")))
    }

    /// Batch-check latest versions for a list of workspace slugs.
    pub async fn workspace_versions(
        &self,
        slugs: &[String],
    ) -> Result<Vec<HubVersionInfo>, HubApiException> {
        let mut params = HashMap::new();
        params.insert("slugs".to_string(), slugs.join(","));
        let json = self
            .get("/public/workspaces/versions", Some(&params))
            .await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    // ─── Public -- Tags ───────────────────────────────────────────────

    /// Search tags with optional category filter.
    pub async fn search_tags(
        &self,
        query: Option<&str>,
        category: Option<&str>,
        limit: u32,
    ) -> Result<Vec<HubTag>, HubApiException> {
        let mut params = HashMap::new();
        params.insert("limit".to_string(), limit.to_string());
        if let Some(q) = query {
            if !q.is_empty() {
                params.insert("q".to_string(), q.to_string());
            }
        }
        if let Some(cat) = category {
            params.insert("category".to_string(), cat.to_string());
        }
        let json = self
            .get("/public/tags/search", Some(&params))
            .await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    /// Get popular tags, optionally filtered by category.
    pub async fn popular_tags(
        &self,
        category: Option<&str>,
        limit: u32,
    ) -> Result<Vec<HubTag>, HubApiException> {
        let mut params = HashMap::new();
        params.insert("limit".to_string(), limit.to_string());
        if let Some(cat) = category {
            params.insert("category".to_string(), cat.to_string());
        }
        let json = self
            .get("/public/tags/popular", Some(&params))
            .await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    // ─── Public -- Trending ───────────────────────────────────────────

    /// Get trending agents.
    pub async fn trending_agents(&self) -> Result<Vec<HubAgentSummary>, HubApiException> {
        let json = self.get("/public/agents/trending", None).await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    /// Get trending workspaces.
    pub async fn trending_workspaces(
        &self,
    ) -> Result<Vec<HubWorkspaceSummary>, HubApiException> {
        let json = self
            .get("/public/workspaces/trending", None)
            .await?;
        Ok(serde_json::from_value(json["data"].clone()).unwrap_or_default())
    }

    // ─── Authenticated -- Votes ───────────────────────────────────────

    /// Toggle like on an agent. Returns `{liked: bool, stars: int}`.
    pub async fn vote_agent(
        &self,
        author: &str,
        slug: &str,
    ) -> Result<serde_json::Value, HubApiException> {
        self.post(&format!("/api/hub/agents/{author}/{slug}/vote"), &serde_json::json!({}))
            .await
    }

    /// Toggle like on a workspace. Returns `{liked: bool, stars: int}`.
    pub async fn vote_workspace(
        &self,
        slug: &str,
    ) -> Result<serde_json::Value, HubApiException> {
        self.post(
            &format!("/api/hub/workspaces/{slug}/vote"),
            &serde_json::json!({}),
        )
        .await
    }

    /// Get the current user's voted slugs for a given target type.
    pub async fn my_votes(
        &self,
        target_type: &str,
    ) -> Result<Vec<String>, HubApiException> {
        let mut params = HashMap::new();
        params.insert("type".to_string(), target_type.to_string());
        let json = self.get("/api/hub/my/votes", Some(&params)).await?;
        Ok(json["slugs"]
            .as_array()
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect()
            })
            .unwrap_or_default())
    }

    // ─── Authenticated -- Submit ──────────────────────────────────────

    /// Submit a new agent to the community hub.
    #[allow(clippy::too_many_arguments)]
    pub async fn submit_agent(
        &self,
        name: &str,
        repo_url: &str,
        branch: Option<&str>,
        description: Option<&str>,
        category: Option<&str>,
        tags: Option<&[serde_json::Value]>,
        entry_point: Option<&str>,
        sdk_version: Option<&str>,
    ) -> Result<(), HubApiException> {
        let mut body = serde_json::json!({
            "name": name,
            "repo_url": repo_url,
        });
        if let Some(b) = branch {
            body["branch"] = serde_json::json!(b);
        }
        if let Some(d) = description {
            body["description"] = serde_json::json!(d);
        }
        if let Some(c) = category {
            body["category"] = serde_json::json!(c);
        }
        if let Some(t) = tags {
            body["tags"] = serde_json::json!(t);
        }
        if let Some(ep) = entry_point {
            body["entry_point"] = serde_json::json!(ep);
        }
        if let Some(sv) = sdk_version {
            body["sdk_version"] = serde_json::json!(sv);
        }

        self.post("/api/hub/agents/submit", &body).await?;
        Ok(())
    }

    /// Submit an agent template to the community hub.
    ///
    /// Templates reference a source provider via `source_uri` and include their
    /// `config_yaml` (dspatch.agent.yml content). No `repo_url` is needed —
    /// the backend inherits it from the source provider.
    pub async fn submit_template(
        &self,
        name: &str,
        config_yaml: &str,
        source_uri: &str,
        description: Option<&str>,
        category: Option<&str>,
        tags: Option<&[serde_json::Value]>,
    ) -> Result<(), HubApiException> {
        let mut body = serde_json::json!({
            "name": name,
            "listing_type": "template",
            "config_yaml": config_yaml,
            "source_uri": source_uri,
        });
        if let Some(d) = description {
            body["description"] = serde_json::json!(d);
        }
        if let Some(c) = category {
            body["category"] = serde_json::json!(c);
        }
        if let Some(t) = tags {
            body["tags"] = serde_json::json!(t);
        }
        self.post("/api/hub/agents/submit", &body).await?;
        Ok(())
    }

    /// Submit a new workspace to the community hub.
    pub async fn submit_workspace(
        &self,
        name: &str,
        config_yaml: &serde_json::Value,
        description: Option<&str>,
        category: Option<&str>,
        tags: Option<&[serde_json::Value]>,
    ) -> Result<(), HubApiException> {
        let mut body = serde_json::json!({
            "name": name,
            "config_json": config_yaml,
        });
        if let Some(d) = description {
            body["description"] = serde_json::json!(d);
        }
        if let Some(c) = category {
            body["category"] = serde_json::json!(c);
        }
        if let Some(t) = tags {
            body["tags"] = serde_json::json!(t);
        }

        self.post("/api/hub/workspaces/submit", &body).await?;
        Ok(())
    }

    // ─── Helpers ──────────────────────────────────────────────────────

    async fn get(
        &self,
        path: &str,
        params: Option<&HashMap<String, String>>,
    ) -> Result<serde_json::Value, HubApiException> {
        let url = format!("{}{}", self.base_url, path);
        tracing::info!(tag = "hub", "HUB GET {path}");

        let mut request = self.client.get(&url).header("Accept", "application/json");
        if let Some(params) = params {
            request = request.query(params);
        }
        if let Some(ref token) = *self.auth_token.read().unwrap_or_else(|e| e.into_inner()) {
            request = request.header("Authorization", format!("Bearer {token}"));
        }

        let response = request
            .send()
            .await
            .map_err(|e| HubApiException::new(0, e.to_string()))?;

        self.parse_response(response).await
    }

    async fn post(
        &self,
        path: &str,
        body: &serde_json::Value,
    ) -> Result<serde_json::Value, HubApiException> {
        let url = format!("{}{}", self.base_url, path);
        tracing::info!(tag = "hub", "HUB POST {path}");

        let mut request = self
            .client
            .post(&url)
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .json(body);
        if let Some(ref token) = *self.auth_token.read().unwrap_or_else(|e| e.into_inner()) {
            request = request.header("Authorization", format!("Bearer {token}"));
        }

        let response = request
            .send()
            .await
            .map_err(|e| HubApiException::new(0, e.to_string()))?;

        self.parse_response(response).await
    }

    async fn parse_response(
        &self,
        response: reqwest::Response,
    ) -> Result<serde_json::Value, HubApiException> {
        let status = response.status().as_u16();
        let body = response
            .text()
            .await
            .map_err(|e| HubApiException::new(status, e.to_string()))?;

        if status < 200 || status >= 300 {
            tracing::warn!(tag = "hub", "Hub API {status}");
            return Err(HubApiException::new(status, body));
        }

        if body.is_empty() {
            return Ok(serde_json::json!({}));
        }

        let decoded: serde_json::Value = serde_json::from_str(&body)
            .map_err(|e| HubApiException::new(status, format!("JSON parse error: {e}")))?;

        if decoded.is_object() {
            Ok(decoded)
        } else {
            Ok(serde_json::json!({ "data": decoded }))
        }
    }
}

/// Exception thrown when the Hub API returns a non-2xx status code.
#[derive(Debug, Clone)]
pub struct HubApiException {
    pub status_code: u16,
    pub body: String,
}

impl HubApiException {
    pub fn new(status_code: u16, body: impl Into<String>) -> Self {
        Self {
            status_code,
            body: body.into(),
        }
    }
}

impl fmt::Display for HubApiException {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "HubApiException({}): {}", self.status_code, self.body)
    }
}

impl std::error::Error for HubApiException {}
