// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// JWT token scope levels matching the backend's progressive auth flow.
///
/// `AwaitingBackupConfirmation` is a client-side gate between 2FA setup
/// and device registration. The backend issues a `DeviceRegistration`
/// token immediately after 2FA confirm, but the client persists the
/// backup codes to secure storage and holds at this scope until the user
/// explicitly confirms they've saved them.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TokenScope {
    /// After registration, before email is verified.
    #[serde(rename = "email_verification")]
    EmailVerification,

    /// After password login, before verifying existing 2FA.
    #[serde(rename = "partial_2fa")]
    Partial2fa,

    /// After email verified during registration, before 2FA is set up.
    #[serde(rename = "setup_2fa")]
    Setup2fa,

    /// Client-side: 2FA confirmed, user must confirm backup codes are saved.
    #[serde(rename = "awaiting_backup_confirmation")]
    AwaitingBackupConfirmation,

    /// After backup codes confirmed, before device registration.
    #[serde(rename = "device_registration")]
    DeviceRegistration,

    /// Fully authenticated with registered device.
    #[serde(rename = "full")]
    Full,
}
