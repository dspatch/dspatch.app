// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Platform-specific secret storage using the OS credential manager.
//!
//! Uses the `keyring` crate which delegates to:
//! - **Windows**: Credential Manager
//! - **macOS**: Keychain
//! - **Linux**: Secret Service (via D-Bus)
//!
//! Ported from `core/crypto/secure_storage_fallback.dart`.

use keyring::Entry;

use crate::db::key_manager::SecretStore;
use crate::util::error::AppError;
use crate::util::result::Result;

/// OS credential store backed by the `keyring` crate.
///
/// Each secret is stored under `(service_name, key)` in the platform
/// credential manager.
pub struct KeyringSecretStore {
    service_name: String,
}

impl KeyringSecretStore {
    /// Creates a new store scoped to the given service name.
    ///
    /// The service name is typically `"dspatch"` or `"dspatch-dev"`.
    pub fn new(service_name: &str) -> Self {
        Self {
            service_name: service_name.to_string(),
        }
    }

    /// Helper to build a keyring [`Entry`] for the given key.
    fn entry(&self, key: &str) -> Result<Entry> {
        Entry::new(&self.service_name, key)
            .map_err(|e| AppError::Crypto(format!("Failed to create keyring entry: {e}")))
    }
}

impl SecretStore for KeyringSecretStore {
    fn read(&self, key: &str) -> Result<Option<String>> {
        let entry = self.entry(key)?;
        match entry.get_password() {
            Ok(value) => Ok(Some(value)),
            Err(keyring::Error::NoEntry) => Ok(None),
            Err(e) => Err(AppError::Crypto(format!(
                "Failed to read from keyring: {e}"
            ))),
        }
    }

    fn write(&self, key: &str, value: &str) -> Result<()> {
        let entry = self.entry(key)?;
        entry
            .set_password(value)
            .map_err(|e| AppError::Crypto(format!("Failed to write to keyring: {e}")))
    }

    fn delete(&self, key: &str) -> Result<()> {
        let entry = self.entry(key)?;
        match entry.delete_credential() {
            Ok(()) => Ok(()),
            Err(keyring::Error::NoEntry) => Ok(()), // No-op if not found
            Err(e) => Err(AppError::Crypto(format!(
                "Failed to delete from keyring: {e}"
            ))),
        }
    }
}
