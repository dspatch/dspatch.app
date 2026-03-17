// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Wrapper around an HTTP response from the backend API.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct ApiResponse {
    pub status_code: u16,
    pub raw_body: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,
}

impl ApiResponse {
    /// Whether the response indicates success (2xx).
    pub fn is_success(&self) -> bool {
        self.status_code >= 200 && self.status_code < 300
    }

    /// The backend uses 404 as a stealth failure for invalid credentials.
    pub fn is_stealth_failure(&self) -> bool {
        self.status_code == 404
    }

    /// Whether the response indicates rate limiting (429).
    pub fn is_rate_limited(&self) -> bool {
        self.status_code == 429
    }

    /// Whether the response indicates a validation error (400).
    pub fn is_validation_error(&self) -> bool {
        self.status_code == 400
    }

    /// Whether the response indicates a conflict (409).
    pub fn is_conflict(&self) -> bool {
        self.status_code == 409
    }
}
