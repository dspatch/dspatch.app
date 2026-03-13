// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

use crate::domain::enums::{AuthMode, TokenScope};

/// The current authentication state of the app.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthState {
    pub mode: AuthMode,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token_scope: Option<TokenScope>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub username: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub device_id: Option<String>,
}

impl AuthState {
    /// Local-only mode, no server connection.
    pub fn anonymous() -> Self {
        Self {
            mode: AuthMode::Anonymous,
            token: None,
            token_scope: None,
            username: None,
            email: None,
            device_id: None,
        }
    }

    /// App startup, auth not yet determined.
    pub fn undetermined() -> Self {
        Self {
            mode: AuthMode::Undetermined,
            token: None,
            token_scope: None,
            username: None,
            email: None,
            device_id: None,
        }
    }
}
