// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local auth service — offline-only, always anonymous mode.

use std::sync::Arc;

use tokio::sync::broadcast;

use crate::domain::enums::{AuthMode, TokenScope};
use crate::domain::models::{
    AuthState, AuthTokens, BackupCodesData, DeviceRegistrationRequest, TotpSetupData,
};
use crate::domain::services::WatchStream;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Not-available error for all backend auth operations in local mode.
const NOT_AVAILABLE: &str = "Not available in local mode";

/// Local-only auth service. Always in anonymous mode.
///
/// All backend auth operations (login, register, 2FA, etc.) return
/// `AppError::Auth` since there is no server connection.
pub struct LocalAuthService {
    state: Arc<tokio::sync::RwLock<AuthState>>,
    tx: broadcast::Sender<AuthState>,
}

impl LocalAuthService {
    pub fn new() -> Self {
        let (tx, _) = broadcast::channel(16);
        Self {
            state: Arc::new(tokio::sync::RwLock::new(AuthState::anonymous())),
            tx,
        }
    }

    // ── State ──

    /// Emits `true` when authenticated, `false` otherwise.
    pub fn watch_auth_state(&self) -> WatchStream<bool> {
        Box::pin(futures::stream::once(async { true }))
    }

    /// Emits the full [`AuthState`].
    pub fn watch_full_auth_state(&self) -> WatchStream<AuthState> {
        let current = {
            // We'll emit the current state first, then listen for changes.
            let state = self.state.clone();
            let rx = self.tx.subscribe();
            async_stream::stream! {
                // Emit current state.
                yield state.read().await.clone();
                // Then listen for updates.
                let mut rx = rx;
                while let Ok(new_state) = rx.recv().await {
                    yield new_state;
                }
            }
        };
        Box::pin(current)
    }

    /// Current auth state snapshot.
    pub async fn current_auth_state(&self) -> AuthState {
        self.state.read().await.clone()
    }

    /// Initializes the auth service — enters anonymous mode.
    pub async fn initialize(&self) -> Result<()> {
        let state = AuthState::anonymous();
        *self.state.write().await = state.clone();
        let _ = self.tx.send(state);
        Ok(())
    }

    /// Always `true` in local mode.
    pub fn is_authenticated(&self) -> bool {
        true
    }

    /// Always `false` — no server connection in local mode.
    pub fn is_connected_mode(&self) -> bool {
        false
    }

    /// Always [`AuthMode::Anonymous`].
    pub fn auth_mode(&self) -> AuthMode {
        AuthMode::Anonymous
    }

    /// Always `None` — no token scope in anonymous mode.
    pub fn token_scope(&self) -> Option<TokenScope> {
        None
    }

    // ── Login flow (not available) ──

    pub async fn login(&self, _username: &str, _password: &str) -> Result<AuthTokens> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn verify_2fa(&self, _code: &str, _is_backup_code: bool) -> Result<AuthTokens> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    // ── Registration flow (not available) ──

    pub async fn register(
        &self,
        _username: &str,
        _email: &str,
        _password: &str,
    ) -> Result<AuthTokens> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn verify_email(&self, _code: &str) -> Result<()> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn resend_verification(&self) -> Result<()> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn setup_2fa(&self) -> Result<TotpSetupData> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn confirm_2fa(&self, _code: &str) -> Result<BackupCodesData> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn get_backup_codes(&self) -> Result<Option<Vec<String>>> {
        Ok(None)
    }

    pub async fn acknowledge_backup_codes(&self) -> Result<()> {
        Ok(())
    }

    pub async fn register_device(
        &self,
        _request: DeviceRegistrationRequest,
        _identity_key_hex: Option<&str>,
    ) -> Result<AuthTokens> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    // ── Token management (not available) ──

    pub async fn refresh_token(&self) -> Result<AuthTokens> {
        Err(AppError::Auth(NOT_AVAILABLE.to_string()))
    }

    pub async fn logout(&self) -> Result<()> {
        let state = AuthState::anonymous();
        *self.state.write().await = state.clone();
        let _ = self.tx.send(state);
        Ok(())
    }

    // ── Anonymous mode ──

    /// No-op — already in anonymous mode.
    pub async fn enter_anonymous_mode(&self) -> Result<()> {
        Ok(())
    }
}
