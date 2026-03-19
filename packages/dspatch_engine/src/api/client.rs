// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! [`ApiClient`] implementation using `reqwest`.
//!
//! Ported from `data/api/http_api_client.dart`.

use std::collections::HashMap;
use std::sync::RwLock;
use std::time::Duration;

use async_trait::async_trait;

use crate::domain::models::ApiResponse;
use crate::domain::services::ApiClient;
use crate::util::result::Result;

/// [`ApiClient`] implementation using `reqwest`.
pub struct HttpApiClient {
    base_url: String,
    client: reqwest::Client,
    token: RwLock<Option<String>>,
}

impl HttpApiClient {
    /// Creates a new HTTP API client for the given base URL.
    pub fn new(base_url: impl Into<String>) -> Self {
        let client = reqwest::Client::builder()
            .connect_timeout(Duration::from_secs(10))
            .timeout(Duration::from_secs(30))
            .build()
            .expect("failed to build reqwest client");
        Self {
            base_url: base_url.into(),
            client,
            token: RwLock::new(None),
        }
    }

    /// Builds a full URL from `path` and optional query parameters.
    fn build_url(&self, path: &str, query_params: Option<&HashMap<String, String>>) -> String {
        let base = &self.base_url;
        let base_url = format!("{base}{path}");
        if let Some(params) = query_params {
            if !params.is_empty() {
                let pairs: Vec<(&str, &str)> =
                    params.iter().map(|(k, v)| (k.as_str(), v.as_str())).collect();
                if let Ok(url) = reqwest::Url::parse_with_params(&base_url, &pairs) {
                    return url.to_string();
                }
            }
        }
        base_url
    }

    /// Returns common headers (Accept, Authorization, optional Content-Type).
    fn headers(&self, json: bool) -> reqwest::header::HeaderMap {
        let mut headers = reqwest::header::HeaderMap::new();
        headers.insert("Accept", "application/json".parse().unwrap());
        if json {
            headers.insert("Content-Type", "application/json".parse().unwrap());
        }
        if let Ok(guard) = self.token.read() {
            if let Some(ref token) = *guard {
                if let Ok(val) = format!("Bearer {token}").parse() {
                    headers.insert("Authorization", val);
                }
            }
        }
        headers
    }

    /// Parses a reqwest response into an [`ApiResponse`].
    fn parse_response(status: u16, body: &str) -> ApiResponse {
        let data = if !body.is_empty() {
            serde_json::from_str::<serde_json::Value>(body)
                .ok()
                .filter(|v| v.is_object())
        } else {
            None
        };

        if status < 200 || status >= 300 {
            tracing::warn!(tag = "api", "API {status}");
        }

        ApiResponse {
            status_code: status,
            raw_body: body.to_string(),
            data,
        }
    }
}

#[async_trait]
impl ApiClient for HttpApiClient {
    async fn get(
        &self,
        path: &str,
        query_params: Option<&HashMap<String, String>>,
    ) -> Result<ApiResponse> {
        let url = self.build_url(path, query_params);
        tracing::info!(tag = "api", "GET {path}");

        let response = self
            .client
            .get(&url)
            .headers(self.headers(false))
            .send()
            .await
            .map_err(|e| crate::util::error::AppError::Api {
                message: e.to_string(),
                status_code: None,
                body: None,
            })?;

        let status = response.status().as_u16();
        let body = response.text().await.unwrap_or_default();
        Ok(Self::parse_response(status, &body))
    }

    async fn post(
        &self,
        path: &str,
        body: Option<serde_json::Value>,
    ) -> Result<ApiResponse> {
        let url = self.build_url(path, None);
        tracing::info!(tag = "api", "POST {path}");

        let has_body = body.is_some();
        let mut request = self.client.post(&url).headers(self.headers(has_body));
        if let Some(body) = body {
            request = request.json(&body);
        }

        let response = request.send().await.map_err(|e| {
            crate::util::error::AppError::Api {
                message: e.to_string(),
                status_code: None,
                body: None,
            }
        })?;

        let status = response.status().as_u16();
        let body = response.text().await.unwrap_or_default();
        Ok(Self::parse_response(status, &body))
    }

    async fn put(
        &self,
        path: &str,
        body: Option<serde_json::Value>,
    ) -> Result<ApiResponse> {
        let url = self.build_url(path, None);
        tracing::info!(tag = "api", "PUT {path}");

        let has_body = body.is_some();
        let mut request = self.client.put(&url).headers(self.headers(has_body));
        if let Some(body) = body {
            request = request.json(&body);
        }

        let response = request.send().await.map_err(|e| {
            crate::util::error::AppError::Api {
                message: e.to_string(),
                status_code: None,
                body: None,
            }
        })?;

        let status = response.status().as_u16();
        let body = response.text().await.unwrap_or_default();
        Ok(Self::parse_response(status, &body))
    }

    async fn delete(&self, path: &str) -> Result<ApiResponse> {
        let url = self.build_url(path, None);
        tracing::info!(tag = "api", "DELETE {path}");

        let response = self
            .client
            .delete(&url)
            .headers(self.headers(false))
            .send()
            .await
            .map_err(|e| crate::util::error::AppError::Api {
                message: e.to_string(),
                status_code: None,
                body: None,
            })?;

        let status = response.status().as_u16();
        let body = response.text().await.unwrap_or_default();
        Ok(Self::parse_response(status, &body))
    }

    fn set_token(&self, token: Option<&str>) {
        if let Ok(mut guard) = self.token.write() {
            *guard = token.map(|t| t.to_string());
        }
    }

    fn token(&self) -> Option<String> {
        self.token.read().ok().and_then(|g| g.clone())
    }

    fn dispose(&self) {
        // reqwest::Client is reference-counted; dropping handles cleanup.
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn http_api_client_construction() {
        let client = HttpApiClient::new("https://api.example.com");
        assert!(client.token().is_none());

        client.set_token(Some("test-token"));
        assert_eq!(client.token(), Some("test-token".to_string()));

        client.set_token(None);
        assert!(client.token().is_none());
    }

    #[test]
    fn build_url_without_params() {
        let client = HttpApiClient::new("https://api.example.com");
        let url = client.build_url("/api/auth/login", None);
        assert_eq!(url, "https://api.example.com/api/auth/login");
    }

    #[test]
    fn build_url_with_params() {
        let client = HttpApiClient::new("https://api.example.com");
        let mut params = HashMap::new();
        params.insert("page".to_string(), "1".to_string());
        let url = client.build_url("/api/items", Some(&params));
        assert_eq!(url, "https://api.example.com/api/items?page=1");
    }

    #[test]
    fn parse_response_success() {
        let resp = HttpApiClient::parse_response(200, r#"{"token":"abc"}"#);
        assert!(resp.is_success());
        assert!(resp.data.is_some());
        assert_eq!(resp.data.unwrap()["token"], "abc");
    }

    #[test]
    fn parse_response_empty_body() {
        let resp = HttpApiClient::parse_response(204, "");
        assert!(resp.is_success());
        assert!(resp.data.is_none());
    }

    #[test]
    fn parse_response_error() {
        let resp = HttpApiClient::parse_response(404, r#"{"error":"not found"}"#);
        assert!(!resp.is_success());
        assert!(resp.is_stealth_failure());
    }
}
