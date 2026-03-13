// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use async_trait::async_trait;

use crate::domain::models::ApiResponse;
use crate::util::result::Result;

/// HTTP client for the d:spatch backend API.
///
/// Handles base URL configuration, authorization headers, and JSON
/// serialization. In anonymous mode, this service is unused --
/// all calls go through local services instead.
#[async_trait]
pub trait ApiClient: Send + Sync {
    /// Sends a GET request to `path` with optional query parameters.
    async fn get(
        &self,
        path: &str,
        query_params: Option<&HashMap<String, String>>,
    ) -> Result<ApiResponse>;

    /// Sends a POST request to `path` with optional JSON body.
    async fn post(
        &self,
        path: &str,
        body: Option<serde_json::Value>,
    ) -> Result<ApiResponse>;

    /// Sends a PUT request to `path` with optional JSON body.
    async fn put(
        &self,
        path: &str,
        body: Option<serde_json::Value>,
    ) -> Result<ApiResponse>;

    /// Sends a DELETE request to `path`.
    async fn delete(&self, path: &str) -> Result<ApiResponse>;

    /// Sets the authorization token for subsequent requests.
    fn set_token(&self, token: Option<&str>);

    /// Current token, if any.
    fn token(&self) -> Option<String>;

    /// Disposes the HTTP client.
    fn dispose(&self);
}
