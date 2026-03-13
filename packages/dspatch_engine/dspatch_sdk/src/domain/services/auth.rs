// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::enums::{AuthMode, TokenScope};
use crate::domain::models::{
    AuthState, AuthTokens, BackupCodesData, DeviceRegistrationRequest, TotpSetupData,
};
use crate::util::result::Result;

/// Manages authentication state and backend auth flows.
///
/// In local mode, the user is always authenticated and
/// [`AuthService::is_connected_mode`] is `false`. In connected mode,
/// this handles the full auth lifecycle.
#[async_trait]
pub trait AuthService: Send + Sync {
    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    /// Current auth state snapshot.
    fn current_auth_state(&self) -> AuthState;

    /// Performs any one-time setup (e.g. token refresh, session restore).
    async fn initialize(&self) -> Result<()>;

    /// Whether the user is currently authenticated (connected+full OR anonymous).
    fn is_authenticated(&self) -> bool;

    /// Whether the app is connected to the d:spatch backend server.
    fn is_connected_mode(&self) -> bool;

    /// Current auth mode.
    fn auth_mode(&self) -> AuthMode;

    /// Current token scope (`None` if anonymous or unauthenticated).
    fn token_scope(&self) -> Option<TokenScope>;

    // -------------------------------------------------------------------------
    // Login flow
    // -------------------------------------------------------------------------

    /// Authenticate with username + password.
    /// Returns a partial token (`Partial2fa` scope) on success.
    async fn login(&self, username: &str, password: &str) -> Result<AuthTokens>;

    /// Verify 2FA code (TOTP or backup code) during login.
    /// Returns a full token on success.
    async fn verify_2fa(&self, code: &str, is_backup_code: bool) -> Result<AuthTokens>;

    // -------------------------------------------------------------------------
    // Registration flow
    // -------------------------------------------------------------------------

    /// Create a new account. Returns a partial token on success.
    async fn register(
        &self,
        username: &str,
        email: &str,
        password: &str,
    ) -> Result<AuthTokens>;

    /// Verify email with a 6-digit code.
    async fn verify_email(&self, code: &str) -> Result<()>;

    /// Resend the email verification code.
    async fn resend_verification(&self) -> Result<()>;

    /// Begin TOTP 2FA setup. Returns the TOTP URI and secret.
    async fn setup_2fa(&self) -> Result<TotpSetupData>;

    /// Confirm 2FA setup with a TOTP code.
    /// Returns backup codes. The auth state holds at
    /// [`TokenScope::AwaitingBackupConfirmation`] until
    /// [`AuthService::acknowledge_backup_codes`] is called.
    async fn confirm_2fa(&self, code: &str) -> Result<BackupCodesData>;

    /// Returns the persisted backup codes, or `None` if none are stored.
    async fn get_backup_codes(&self) -> Result<Option<Vec<String>>>;

    /// User confirms they saved their backup codes. Upgrades the auth
    /// state to [`TokenScope::DeviceRegistration`] and clears stored codes.
    async fn acknowledge_backup_codes(&self) -> Result<()>;

    /// Register this device with the server (first device).
    /// Returns a full-scope token on success.
    async fn register_device(
        &self,
        request: DeviceRegistrationRequest,
        identity_key_hex: Option<&str>,
    ) -> Result<AuthTokens>;

    // -------------------------------------------------------------------------
    // Token management
    // -------------------------------------------------------------------------

    /// Refresh the current JWT. Returns a new full token.
    async fn refresh_token(&self) -> Result<AuthTokens>;

    /// Sign out and clear all stored credentials.
    async fn logout(&self) -> Result<()>;

    // -------------------------------------------------------------------------
    // Anonymous mode
    // -------------------------------------------------------------------------

    /// Enter local-only anonymous mode (no server connection).
    async fn enter_anonymous_mode(&self) -> Result<()>;
}
