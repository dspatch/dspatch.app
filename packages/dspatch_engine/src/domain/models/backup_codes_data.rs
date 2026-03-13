// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

use super::auth_tokens::AuthTokens;

/// Data returned after confirming 2FA setup: backup codes + new token.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BackupCodesData {
    /// Single-use recovery codes (displayed once to the user).
    pub backup_codes: Vec<String>,

    /// New token with `TokenScope::DeviceRegistration` scope.
    pub tokens: AuthTokens,
}
