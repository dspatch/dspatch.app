// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Persists authentication tokens and metadata in secure storage.
//!
//! Ported from `data/api/token_storage.dart`.

use crate::db::key_manager::SecretStore;
use crate::domain::enums::{AuthMode, TokenScope};
use crate::util::result::Result;

const KEY_TOKEN: &str = "dspatch_auth_token";
const KEY_TOKEN_SCOPE: &str = "dspatch_token_scope";
const KEY_AUTH_MODE: &str = "dspatch_auth_mode";
const KEY_USERNAME: &str = "dspatch_username";
const KEY_EMAIL: &str = "dspatch_email";
const KEY_BACKUP_CODES: &str = "dspatch_backup_codes";

/// Persists authentication tokens and metadata in secure storage.
pub struct TokenStorage {
    store: Box<dyn SecretStore>,
}

impl TokenStorage {
    pub fn new(store: Box<dyn SecretStore>) -> Self {
        Self { store }
    }

    // ─── Token ────────────────────────────────────────────────────────

    pub fn get_token(&self) -> Result<Option<String>> {
        self.store.read(KEY_TOKEN)
    }

    pub fn set_token(&self, token: &str) -> Result<()> {
        self.store.write(KEY_TOKEN, token)
    }

    pub fn clear_token(&self) -> Result<()> {
        self.store.delete(KEY_TOKEN)
    }

    // ─── Token scope ──────────────────────────────────────────────────

    pub fn get_token_scope(&self) -> Result<Option<TokenScope>> {
        let raw = self.store.read(KEY_TOKEN_SCOPE)?;
        Ok(raw.and_then(|s| match s.as_str() {
            "email_verification" | "EmailVerification" => Some(TokenScope::EmailVerification),
            "partial_2fa" | "Partial2fa" => Some(TokenScope::Partial2fa),
            "setup_2fa" | "Setup2fa" => Some(TokenScope::Setup2fa),
            "awaiting_backup_confirmation" | "AwaitingBackupConfirmation" => {
                Some(TokenScope::AwaitingBackupConfirmation)
            }
            "device_registration" | "DeviceRegistration" => Some(TokenScope::DeviceRegistration),
            "full" | "Full" => Some(TokenScope::Full),
            _ => None,
        }))
    }

    pub fn set_token_scope(&self, scope: TokenScope) -> Result<()> {
        let name = match scope {
            TokenScope::EmailVerification => "email_verification",
            TokenScope::Partial2fa => "partial_2fa",
            TokenScope::Setup2fa => "setup_2fa",
            TokenScope::AwaitingBackupConfirmation => "awaiting_backup_confirmation",
            TokenScope::DeviceRegistration => "device_registration",
            TokenScope::Full => "full",
        };
        self.store.write(KEY_TOKEN_SCOPE, name)
    }

    // ─── Device ID (per-user -- persists across logouts) ──────────────

    fn device_id_key(username: &str) -> String {
        format!("dspatch_device_id:{username}")
    }

    pub fn get_device_id(&self, username: &str) -> Result<Option<String>> {
        self.store.read(&Self::device_id_key(username))
    }

    pub fn set_device_id(&self, username: &str, id: &str) -> Result<()> {
        self.store.write(&Self::device_id_key(username), id)
    }

    // ─── Identity key (per-user -- persists across logouts) ───────────

    fn identity_key_key(username: &str) -> String {
        format!("dspatch_identity_key:{username}")
    }

    pub fn get_identity_key(&self, username: &str) -> Result<Option<String>> {
        self.store.read(&Self::identity_key_key(username))
    }

    pub fn set_identity_key(&self, username: &str, hex_key: &str) -> Result<()> {
        self.store
            .write(&Self::identity_key_key(username), hex_key)
    }

    // ─── Auth mode ────────────────────────────────────────────────────

    pub fn get_auth_mode(&self) -> Result<AuthMode> {
        let raw = self.store.read(KEY_AUTH_MODE)?;
        Ok(match raw.as_deref() {
            Some("anonymous" | "Anonymous") => AuthMode::Anonymous,
            Some("connected" | "Connected") => AuthMode::Connected,
            _ => AuthMode::Undetermined,
        })
    }

    pub fn set_auth_mode(&self, mode: AuthMode) -> Result<()> {
        let name = match mode {
            AuthMode::Undetermined => "undetermined",
            AuthMode::Anonymous => "anonymous",
            AuthMode::Connected => "connected",
        };
        self.store.write(KEY_AUTH_MODE, name)
    }

    // ─── User info ────────────────────────────────────────────────────

    pub fn get_username(&self) -> Result<Option<String>> {
        self.store.read(KEY_USERNAME)
    }

    pub fn set_username(&self, username: &str) -> Result<()> {
        self.store.write(KEY_USERNAME, username)
    }

    pub fn get_email(&self) -> Result<Option<String>> {
        self.store.read(KEY_EMAIL)
    }

    pub fn set_email(&self, email: &str) -> Result<()> {
        self.store.write(KEY_EMAIL, email)
    }

    // ─── Backup codes ─────────────────────────────────────────────────

    pub fn get_backup_codes(&self) -> Result<Option<Vec<String>>> {
        let raw = self.store.read(KEY_BACKUP_CODES)?;
        Ok(raw
            .filter(|s| !s.is_empty())
            .map(|s| s.lines().map(|l| l.to_string()).collect()))
    }

    pub fn set_backup_codes(&self, codes: &[String]) -> Result<()> {
        self.store.write(KEY_BACKUP_CODES, &codes.join("\n"))
    }

    pub fn clear_backup_codes(&self) -> Result<()> {
        self.store.delete(KEY_BACKUP_CODES)
    }

    // ─── Bulk ─────────────────────────────────────────────────────────

    /// Clears session data. Per-user device keys are intentionally preserved
    /// so the user can log back in with device proof.
    pub fn clear_all(&self) -> Result<()> {
        self.store.delete(KEY_TOKEN)?;
        self.store.delete(KEY_TOKEN_SCOPE)?;
        self.store.delete(KEY_AUTH_MODE)?;
        self.store.delete(KEY_USERNAME)?;
        self.store.delete(KEY_EMAIL)?;
        self.store.delete(KEY_BACKUP_CODES)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::key_manager::testing::InMemorySecretStore;

    #[test]
    fn token_save_load_clear_roundtrip() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        // Initially empty.
        assert!(store.get_token().unwrap().is_none());

        // Save and load.
        store.set_token("jwt-abc-123").unwrap();
        assert_eq!(store.get_token().unwrap(), Some("jwt-abc-123".to_string()));

        // Clear.
        store.clear_token().unwrap();
        assert!(store.get_token().unwrap().is_none());
    }

    #[test]
    fn token_scope_roundtrip() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        assert!(store.get_token_scope().unwrap().is_none());

        store.set_token_scope(TokenScope::Full).unwrap();
        assert_eq!(store.get_token_scope().unwrap(), Some(TokenScope::Full));

        store
            .set_token_scope(TokenScope::EmailVerification)
            .unwrap();
        assert_eq!(
            store.get_token_scope().unwrap(),
            Some(TokenScope::EmailVerification)
        );
    }

    #[test]
    fn auth_mode_roundtrip() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        assert_eq!(store.get_auth_mode().unwrap(), AuthMode::Undetermined);

        store.set_auth_mode(AuthMode::Anonymous).unwrap();
        assert_eq!(store.get_auth_mode().unwrap(), AuthMode::Anonymous);

        store.set_auth_mode(AuthMode::Connected).unwrap();
        assert_eq!(store.get_auth_mode().unwrap(), AuthMode::Connected);
    }

    #[test]
    fn device_id_per_user() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        store.set_device_id("alice", "dev-1").unwrap();
        store.set_device_id("bob", "dev-2").unwrap();

        assert_eq!(
            store.get_device_id("alice").unwrap(),
            Some("dev-1".to_string())
        );
        assert_eq!(
            store.get_device_id("bob").unwrap(),
            Some("dev-2".to_string())
        );
        assert!(store.get_device_id("charlie").unwrap().is_none());
    }

    #[test]
    fn backup_codes_roundtrip() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        assert!(store.get_backup_codes().unwrap().is_none());

        let codes = vec!["CODE1".to_string(), "CODE2".to_string(), "CODE3".to_string()];
        store.set_backup_codes(&codes).unwrap();
        assert_eq!(store.get_backup_codes().unwrap(), Some(codes));

        store.clear_backup_codes().unwrap();
        assert!(store.get_backup_codes().unwrap().is_none());
    }

    #[test]
    fn clear_all_preserves_device_ids() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        store.set_token("token").unwrap();
        store.set_token_scope(TokenScope::Full).unwrap();
        store.set_auth_mode(AuthMode::Connected).unwrap();
        store.set_username("alice").unwrap();
        store.set_email("alice@example.com").unwrap();
        store.set_device_id("alice", "dev-1").unwrap();

        store.clear_all().unwrap();

        assert!(store.get_token().unwrap().is_none());
        assert!(store.get_token_scope().unwrap().is_none());
        assert_eq!(store.get_auth_mode().unwrap(), AuthMode::Undetermined);
        assert!(store.get_username().unwrap().is_none());
        assert!(store.get_email().unwrap().is_none());

        // Device ID should be preserved.
        assert_eq!(
            store.get_device_id("alice").unwrap(),
            Some("dev-1".to_string())
        );
    }

    #[test]
    fn user_info_roundtrip() {
        let store = TokenStorage::new(Box::new(InMemorySecretStore::new()));

        store.set_username("alice").unwrap();
        store.set_email("alice@example.com").unwrap();

        assert_eq!(
            store.get_username().unwrap(),
            Some("alice".to_string())
        );
        assert_eq!(
            store.get_email().unwrap(),
            Some("alice@example.com".to_string())
        );
    }
}
