// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Data returned by the backend when setting up TOTP 2FA.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TotpSetupData {
    /// The `otpauth://...` URI for QR code rendering.
    pub totp_uri: String,

    /// Base32-encoded TOTP secret for manual entry.
    pub secret: String,
}
