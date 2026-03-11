// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! [`AuthService`] implementation that communicates with the d:spatch backend.
//!
//! Handles the full authentication lifecycle: login, registration,
//! 2FA, device registration, token refresh, and anonymous fallback.
//!
//! Ported from `data/api/connected_auth_service.dart`.

use std::sync::Arc;

use async_trait::async_trait;
use tokio::sync::{broadcast, RwLock};

use crate::domain::enums::{AuthMode, TokenScope};
use crate::domain::models::{
    AuthState, AuthTokens, BackupCodesData, DeviceRegistrationRequest, TotpSetupData,
};
use crate::domain::services::{ApiClient, AuthService, WatchStream};
use crate::util::error::AppError;
use crate::util::result::Result;

use base64::Engine;

use super::token_storage::TokenStorage;

/// [`AuthService`] implementation that communicates with the d:spatch backend.
pub struct ConnectedAuthService {
    api: Arc<dyn ApiClient>,
    storage: Arc<TokenStorage>,
    state: RwLock<AuthState>,
    tx: broadcast::Sender<AuthState>,
    /// In-memory cache of backup codes set during [`confirm_2fa`].
    pending_backup_codes: RwLock<Option<Vec<String>>>,
}

impl ConnectedAuthService {
    pub fn new(api: Arc<dyn ApiClient>, storage: Arc<TokenStorage>) -> Self {
        let (tx, _) = broadcast::channel(16);
        Self {
            api,
            storage,
            state: RwLock::new(AuthState::undetermined()),
            tx,
            pending_backup_codes: RwLock::new(None),
        }
    }

    /// Returns a raw broadcast receiver for auth state changes.
    ///
    /// Unlike [`watch_full_auth_state`], this returns a receiver that can be
    /// subscribed to before any state is emitted, preventing race conditions.
    pub fn subscribe_auth_state(&self) -> broadcast::Receiver<AuthState> {
        self.tx.subscribe()
    }

    /// Emits a new auth state.
    async fn emit(&self, state: AuthState) {
        *self.state.write().await = state.clone();
        let _ = self.tx.send(state);
    }

    /// Maps a backend scope string to a [`TokenScope`].
    fn parse_scope(raw: Option<&str>) -> TokenScope {
        match raw {
            Some("email_verification") => TokenScope::EmailVerification,
            Some("partial_2fa") => TokenScope::Partial2fa,
            Some("setup_2fa") => TokenScope::Setup2fa,
            Some("device_registration") => TokenScope::DeviceRegistration,
            Some("full") => TokenScope::Full,
            _ => TokenScope::Partial2fa,
        }
    }

    /// Calls `GET /api/auth/status` to validate the current token.
    async fn fetch_account_status(&self) -> Option<AuthState> {
        let response = match self.api.get("/api/auth/status", None).await {
            Ok(r) => r,
            Err(e) => {
                tracing::error!(tag = "auth", "Account status fetch error: {e}");
                return None;
            }
        };

        if !response.is_success() {
            return None;
        }

        let data = response.data.as_ref()?;
        let token = data["token"]
            .as_str()
            .map(|s| s.to_string())
            .or_else(|| self.api.token())
            .unwrap_or_default();
        let scope = Self::parse_scope(data["scope"].as_str());
        let username = data["username"].as_str().map(|s| s.to_string());
        let email = data["email"].as_str().map(|s| s.to_string());

        if !token.is_empty() {
            self.api.set_token(Some(&token));
            let _ = self.storage.set_token(&token);
        }
        let _ = self.storage.set_token_scope(scope);
        if let Some(ref u) = username {
            let _ = self.storage.set_username(u);
        }
        if let Some(ref e) = email {
            let _ = self.storage.set_email(e);
        }

        let resolved_username = username.or_else(|| self.storage.get_username().ok().flatten());
        let device_id = resolved_username
            .as_deref()
            .and_then(|u| self.storage.get_device_id(u).ok().flatten());
        let resolved_email = email.or_else(|| self.storage.get_email().ok().flatten());

        let current = self.state.read().await;
        let state = AuthState {
            mode: AuthMode::Connected,
            token: if token.is_empty() {
                current.token.clone()
            } else {
                Some(token)
            },
            token_scope: Some(scope),
            username: resolved_username,
            email: resolved_email,
            device_id,
        };
        drop(current);
        self.emit(state.clone()).await;
        Some(state)
    }
}

#[async_trait]
impl AuthService for ConnectedAuthService {
    // ─── State ────────────────────────────────────────────────────────

    fn watch_auth_state(&self) -> WatchStream<bool> {
        let current = self.current_auth_state();
        let mut rx = self.tx.subscribe();
        let is_authed = |s: &AuthState| {
            s.mode == AuthMode::Anonymous
                || (s.mode == AuthMode::Connected && s.token_scope == Some(TokenScope::Full))
        };
        Box::pin(async_stream::stream! {
            // Yield current state first so late subscribers don't miss it.
            yield is_authed(&current);
            loop {
                match rx.recv().await {
                    Ok(s) => yield is_authed(&s),
                    Err(_) => break,
                }
            }
        })
    }

    fn watch_full_auth_state(&self) -> WatchStream<AuthState> {
        // Yield the current state first so late subscribers don't miss it,
        // then forward all future broadcasts.
        let current = self.current_auth_state();
        let mut rx = self.tx.subscribe();
        Box::pin(async_stream::stream! {
            yield current;
            loop {
                match rx.recv().await {
                    Ok(state) => yield state,
                    Err(_) => break,
                }
            }
        })
    }

    fn current_auth_state(&self) -> AuthState {
        // Non-blocking read — the RwLock is only held briefly during state
        // updates so this should always succeed. Falls back to undetermined
        // on contention (extremely unlikely).
        match self.state.try_read() {
            Ok(guard) => guard.clone(),
            Err(_) => AuthState::undetermined(),
        }
    }

    fn is_authenticated(&self) -> bool {
        let state = self.current_auth_state();
        state.mode == AuthMode::Anonymous
            || (state.mode == AuthMode::Connected && state.token_scope == Some(TokenScope::Full))
    }

    fn is_connected_mode(&self) -> bool {
        self.current_auth_state().mode == AuthMode::Connected
    }

    fn auth_mode(&self) -> AuthMode {
        self.current_auth_state().mode
    }

    fn token_scope(&self) -> Option<TokenScope> {
        self.current_auth_state().token_scope
    }

    // ─── Initialization ───────────────────────────────────────────────

    async fn initialize(&self) -> Result<()> {
        let saved_mode = self.storage.get_auth_mode()?;
        tracing::info!(tag = "auth", ?saved_mode, "Loaded saved auth mode from storage");

        if saved_mode == AuthMode::Anonymous {
            self.emit(AuthState::anonymous()).await;
            return Ok(());
        }

        let token = self.storage.get_token()?;
        let scope = self.storage.get_token_scope()?;
        tracing::info!(
            tag = "auth",
            has_token = token.is_some(),
            scope = ?scope,
            "Loaded cached credentials from storage"
        );

        if token.is_none() || scope.is_none() {
            tracing::warn!(tag = "auth", "No cached token or scope — emitting Undetermined");
            self.emit(AuthState::undetermined()).await;
            return Ok(());
        }

        let token = token.unwrap();
        let scope = scope.unwrap();

        if scope == TokenScope::Full {
            self.api.set_token(Some(&token));
            match self.refresh_token().await {
                Ok(_) => {
                    tracing::info!(tag = "auth", "Token refresh succeeded");
                }
                Err(e) => {
                    tracing::warn!(tag = "auth", "Token refresh failed: {e}");
                    self.api.set_token(None);
                    self.emit(AuthState::undetermined()).await;
                }
            }
            return Ok(());
        }

        if scope == TokenScope::AwaitingBackupConfirmation {
            self.api.set_token(Some(&token));
            let codes = self.storage.get_backup_codes()?;
            *self.pending_backup_codes.write().await = codes;
            let username = self.storage.get_username()?;
            let email = self.storage.get_email()?;
            self.emit(AuthState {
                mode: AuthMode::Connected,
                token: Some(token),
                token_scope: Some(TokenScope::AwaitingBackupConfirmation),
                username,
                email,
                device_id: None,
            })
            .await;
            return Ok(());
        }

        // Partial token -- validate with server.
        self.api.set_token(Some(&token));
        if self.fetch_account_status().await.is_none() {
            tracing::warn!(tag = "auth", "Partial token validation failed");
            self.api.set_token(None);
            self.storage.clear_all()?;
            self.emit(AuthState::undetermined()).await;
        }

        Ok(())
    }

    // ─── Login flow ───────────────────────────────────────────────────

    async fn login(&self, username: &str, password: &str) -> Result<AuthTokens> {
        let mut body = serde_json::json!({
            "username": username,
            "password": password,
        });

        // Add device proof if available.
        if let Ok(Some(device_id)) = self.storage.get_device_id(username) {
            body["device_id"] = serde_json::json!(device_id);

            // Sign "login:{username}:{timestamp}" with stored Ed25519 identity key.
            if let Ok(Some(identity_hex)) = self.storage.get_identity_key(username) {
                if let Ok(key_bytes) = hex::decode(&identity_hex) {
                    if key_bytes.len() == 32 {
                        let timestamp = chrono::Utc::now().timestamp();
                        let message = format!("login:{username}:{timestamp}");

                        if let Ok(signing_key) = ed25519_dalek::SigningKey::try_from(key_bytes.as_slice()) {
                            use ed25519_dalek::Signer;
                            let signature = signing_key.sign(message.as_bytes());
                            let sig_b64 = base64::engine::general_purpose::STANDARD
                                .encode(signature.to_bytes());

                            body["device_signature"] = serde_json::json!(sig_b64);
                            body["device_timestamp"] = serde_json::json!(timestamp);
                        }
                    }
                }
            }
        }

        let response = self
            .api
            .post("/api/auth/login", Some(body))
            .await?;

        if response.is_stealth_failure() {
            return Err(AppError::Auth("Invalid username or password".to_string()));
        }
        if response.is_rate_limited() {
            return Err(AppError::Auth(
                "Too many attempts. Try again later.".to_string(),
            ));
        }
        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Login failed");
            return Err(AppError::Api {
                message: msg.to_string(),
                status_code: Some(response.status_code),
                body: None,
            });
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in login response".to_string())
        })?;
        let token = data["token"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No token in response".to_string()))?;
        let scope = Self::parse_scope(data["scope"].as_str());
        let tokens = AuthTokens {
            token: token.to_string(),
            scope,
            expires_at: None,
        };

        self.api.set_token(Some(token));
        self.storage.set_token(token)?;
        self.storage.set_token_scope(scope)?;
        self.storage.set_auth_mode(AuthMode::Connected)?;
        self.storage.set_username(username)?;

        if let Some(email) = data["email"].as_str() {
            self.storage.set_email(email)?;
        }

        self.emit(AuthState {
            mode: AuthMode::Connected,
            token: Some(token.to_string()),
            token_scope: Some(scope),
            username: Some(username.to_string()),
            email: data["email"].as_str().map(|s| s.to_string()),
            device_id: None,
        })
        .await;

        Ok(tokens)
    }

    async fn verify_2fa(&self, code: &str, is_backup_code: bool) -> Result<AuthTokens> {
        let mut body = serde_json::json!({
            "code": code,
            "is_backup_code": is_backup_code,
        });

        // Add device proof if available.
        if let Some(ref username) = self.storage.get_username().ok().flatten() {
            if let Ok(Some(device_id)) = self.storage.get_device_id(username) {
                if let Ok(Some(identity_hex)) = self.storage.get_identity_key(username) {
                    if let Ok(key_bytes) = hex::decode(&identity_hex) {
                        if key_bytes.len() == 32 {
                            if let Ok(signing_key) =
                                ed25519_dalek::SigningKey::try_from(key_bytes.as_slice())
                            {
                                // Sign the current token (not a formatted message).
                                if let Ok(Some(token)) = self.storage.get_token() {
                                    use ed25519_dalek::Signer;
                                    let signature = signing_key.sign(token.as_bytes());
                                    let sig_b64 =
                                        base64::engine::general_purpose::STANDARD
                                            .encode(signature.to_bytes());
                                    body["device_id"] = serde_json::json!(device_id);
                                    body["device_signature"] =
                                        serde_json::json!(sig_b64);
                                }
                            }
                        }
                    }
                }
            }
        }

        let response = self
            .api
            .post("/api/auth/2fa/verify", Some(body))
            .await?;

        if response.is_stealth_failure() {
            return Err(AppError::Auth("Invalid verification code".to_string()));
        }
        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Verification failed");
            return Err(AppError::Api {
                message: msg.to_string(),
                status_code: Some(response.status_code),
                body: None,
            });
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in 2FA response".to_string())
        })?;
        let token = data["token"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No token in response".to_string()))?;
        let tokens = AuthTokens {
            token: token.to_string(),
            scope: TokenScope::Full,
            expires_at: None,
        };

        self.api.set_token(Some(token));
        self.storage.set_token(token)?;
        self.storage.set_token_scope(TokenScope::Full)?;

        let mut current = self.state.write().await;
        current.token = Some(token.to_string());
        current.token_scope = Some(TokenScope::Full);
        let updated = current.clone();
        drop(current);
        let _ = self.tx.send(updated);

        Ok(tokens)
    }

    // ─── Registration flow ────────────────────────────────────────────

    async fn register(
        &self,
        username: &str,
        email: &str,
        password: &str,
    ) -> Result<AuthTokens> {
        let response = self
            .api
            .post(
                "/api/auth/register",
                Some(serde_json::json!({
                    "username": username,
                    "email": email,
                    "password": password,
                })),
            )
            .await?;

        if response.is_conflict() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Username or email already exists");
            return Err(AppError::Auth(msg.to_string()));
        }
        if response.is_rate_limited() {
            return Err(AppError::Auth(
                "Too many registration attempts. Try again later.".to_string(),
            ));
        }
        if response.is_validation_error() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Invalid input");
            return Err(AppError::Auth(msg.to_string()));
        }
        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Registration failed");
            return Err(AppError::Api {
                message: msg.to_string(),
                status_code: Some(response.status_code),
                body: None,
            });
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in register response".to_string())
        })?;
        let token = data["token"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No token in response".to_string()))?;
        let tokens = AuthTokens {
            token: token.to_string(),
            scope: TokenScope::EmailVerification,
            expires_at: None,
        };

        self.api.set_token(Some(token));
        self.storage.set_token(token)?;
        self.storage
            .set_token_scope(TokenScope::EmailVerification)?;
        self.storage.set_auth_mode(AuthMode::Connected)?;
        self.storage.set_username(username)?;
        self.storage.set_email(email)?;

        self.emit(AuthState {
            mode: AuthMode::Connected,
            token: Some(token.to_string()),
            token_scope: Some(TokenScope::EmailVerification),
            username: Some(username.to_string()),
            email: Some(email.to_string()),
            device_id: None,
        })
        .await;

        Ok(tokens)
    }

    async fn verify_email(&self, code: &str) -> Result<()> {
        let response = self
            .api
            .post(
                "/api/auth/verify-email",
                Some(serde_json::json!({ "code": code })),
            )
            .await?;

        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Invalid verification code");
            return Err(AppError::Auth(msg.to_string()));
        }

        // Update token if the server returns a new one.
        if let Some(new_token) = response
            .data
            .as_ref()
            .and_then(|d| d["token"].as_str())
        {
            self.api.set_token(Some(new_token));
            self.storage.set_token(new_token)?;
        }

        self.storage.set_token_scope(TokenScope::Setup2fa)?;
        let mut current = self.state.write().await;
        if let Some(ref data) = response.data {
            if let Some(t) = data["token"].as_str() {
                current.token = Some(t.to_string());
            }
        }
        current.token_scope = Some(TokenScope::Setup2fa);
        let updated = current.clone();
        drop(current);
        let _ = self.tx.send(updated);

        Ok(())
    }

    async fn resend_verification(&self) -> Result<()> {
        let response = self
            .api
            .post("/api/auth/resend-verification", None)
            .await?;
        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Could not resend code");
            return Err(AppError::Auth(msg.to_string()));
        }
        Ok(())
    }

    async fn setup_2fa(&self) -> Result<TotpSetupData> {
        let response = self.api.post("/api/auth/2fa/setup", None).await?;

        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("2FA setup failed");
            return Err(AppError::Auth(msg.to_string()));
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in 2FA setup response".to_string())
        })?;
        Ok(TotpSetupData {
            totp_uri: data["totp_uri"]
                .as_str()
                .unwrap_or("")
                .to_string(),
            secret: data["secret"].as_str().unwrap_or("").to_string(),
        })
    }

    async fn confirm_2fa(&self, code: &str) -> Result<BackupCodesData> {
        let response = self
            .api
            .post(
                "/api/auth/2fa/confirm-setup",
                Some(serde_json::json!({ "code": code })),
            )
            .await?;

        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Invalid 2FA code");
            return Err(AppError::Auth(msg.to_string()));
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in 2FA confirm response".to_string())
        })?;

        let token = data["token"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No token in response".to_string()))?;
        let backup_codes: Vec<String> = data["backup_codes"]
            .as_array()
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect()
            })
            .unwrap_or_default();

        *self.pending_backup_codes.write().await = Some(backup_codes.clone());
        self.api.set_token(Some(token));
        self.storage.set_token(token)?;
        self.storage.set_backup_codes(&backup_codes)?;
        self.storage
            .set_token_scope(TokenScope::AwaitingBackupConfirmation)?;

        let mut current = self.state.write().await;
        current.token = Some(token.to_string());
        current.token_scope = Some(TokenScope::AwaitingBackupConfirmation);
        let updated = current.clone();
        drop(current);
        let _ = self.tx.send(updated);

        Ok(BackupCodesData {
            backup_codes,
            tokens: AuthTokens {
                token: token.to_string(),
                scope: TokenScope::AwaitingBackupConfirmation,
                expires_at: None,
            },
        })
    }

    async fn get_backup_codes(&self) -> Result<Option<Vec<String>>> {
        let pending = self.pending_backup_codes.read().await;
        if pending.is_some() {
            return Ok(pending.clone());
        }
        drop(pending);
        self.storage.get_backup_codes()
    }

    async fn acknowledge_backup_codes(&self) -> Result<()> {
        *self.pending_backup_codes.write().await = None;
        self.storage.clear_backup_codes()?;
        self.storage
            .set_token_scope(TokenScope::DeviceRegistration)?;

        let mut current = self.state.write().await;
        current.token_scope = Some(TokenScope::DeviceRegistration);
        let updated = current.clone();
        drop(current);
        let _ = self.tx.send(updated);

        Ok(())
    }

    async fn register_device(
        &self,
        request: DeviceRegistrationRequest,
        identity_key_hex: Option<&str>,
    ) -> Result<AuthTokens> {
        let response = self
            .api
            .post(
                "/api/auth/devices/register",
                Some(serde_json::to_value(&request).map_err(|e| {
                    AppError::Auth(format!("Serialization error: {e}"))
                })?),
            )
            .await?;

        if !response.is_success() {
            let msg = response
                .data
                .as_ref()
                .and_then(|d| d["error"].as_str())
                .unwrap_or("Device registration failed");
            return Err(AppError::Auth(msg.to_string()));
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in device registration response".to_string())
        })?;
        let token = data["token"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No token in response".to_string()))?;
        let device_id = data["device_id"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No device_id in response".to_string()))?;
        let tokens = AuthTokens {
            token: token.to_string(),
            scope: TokenScope::Full,
            expires_at: None,
        };

        self.api.set_token(Some(token));
        self.storage.set_token(token)?;
        self.storage.set_token_scope(TokenScope::Full)?;
        let username = self
            .state
            .read()
            .await
            .username
            .clone()
            .ok_or_else(|| AppError::Auth("No username in state".to_string()))?;
        self.storage.set_device_id(&username, device_id)?;

        // Store identity key for future device proofs.
        if let Some(hex_key) = identity_key_hex {
            let _ = self.storage.set_identity_key(&username, hex_key);
        }

        let mut current = self.state.write().await;
        current.token = Some(token.to_string());
        current.token_scope = Some(TokenScope::Full);
        current.device_id = Some(device_id.to_string());
        let updated = current.clone();
        drop(current);
        let _ = self.tx.send(updated);

        Ok(tokens)
    }

    // ─── Token management ─────────────────────────────────────────────

    async fn refresh_token(&self) -> Result<AuthTokens> {
        let response = self.api.post("/api/auth/refresh", None).await?;

        if !response.is_success() {
            self.storage.clear_all()?;
            self.api.set_token(None);
            self.emit(AuthState::undetermined()).await;
            return Err(AppError::Auth("Session expired".to_string()));
        }

        let data = response.data.as_ref().ok_or_else(|| {
            AppError::Auth("No data in refresh response".to_string())
        })?;
        let token = data["token"]
            .as_str()
            .ok_or_else(|| AppError::Auth("No token in response".to_string()))?;
        let scope = Self::parse_scope(data["scope"].as_str());
        let tokens = AuthTokens {
            token: token.to_string(),
            scope,
            expires_at: None,
        };

        self.api.set_token(Some(token));
        self.storage.set_token(token)?;
        self.storage.set_token_scope(scope)?;

        let username = data["username"]
            .as_str()
            .map(|s| s.to_string())
            .or_else(|| self.storage.get_username().ok().flatten());
        let email = data["email"]
            .as_str()
            .map(|s| s.to_string())
            .or_else(|| self.storage.get_email().ok().flatten());
        let device_id = username
            .as_deref()
            .and_then(|u| self.storage.get_device_id(u).ok().flatten());

        self.emit(AuthState {
            mode: AuthMode::Connected,
            token: Some(token.to_string()),
            token_scope: Some(scope),
            username,
            email,
            device_id,
        })
        .await;

        Ok(tokens)
    }

    async fn logout(&self) -> Result<()> {
        // Best-effort server-side logout.
        let _ = self.api.post("/api/auth/logout", None).await;
        self.api.set_token(None);
        self.storage.clear_all()?;
        self.emit(AuthState::undetermined()).await;
        Ok(())
    }

    // ─── Anonymous mode ───────────────────────────────────────────────

    async fn enter_anonymous_mode(&self) -> Result<()> {
        self.api.set_token(None);
        self.storage.set_auth_mode(AuthMode::Anonymous)?;
        self.emit(AuthState::anonymous()).await;
        Ok(())
    }
}
