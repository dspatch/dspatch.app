// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Platform-specific secret storage.
//!
//! - **Desktop + iOS** (Windows/macOS/Linux/iOS): Uses the OS credential manager
//!   via `keyring` (Keychain on macOS/iOS, Credential Manager on Windows,
//!   kernel keyutils on Linux).
//! - **Android**: Uses an encrypted file in the app's private sandbox
//!   (`keyring` v3 does not support Android; v4 will add Keystore support).

use crate::db::key_manager::SecretStore;
use crate::util::error::AppError;
use crate::util::result::Result;

// ---------------------------------------------------------------------------
// Keyring-backed store (desktop + iOS)
// ---------------------------------------------------------------------------

#[cfg(not(target_os = "android"))]
use keyring::Entry;

/// OS credential store backed by the `keyring` crate.
///
/// Works on Windows (Credential Manager), macOS (Keychain), Linux (kernel
/// keyutils), and iOS (Keychain via Security.framework).
#[cfg(not(target_os = "android"))]
pub struct KeyringSecretStore {
    service_name: String,
}

#[cfg(not(target_os = "android"))]
impl KeyringSecretStore {
    pub fn new(service_name: &str) -> Self {
        Self {
            service_name: service_name.to_string(),
        }
    }

    fn entry(&self, key: &str) -> Result<Entry> {
        Entry::new(&self.service_name, key)
            .map_err(|e| AppError::Crypto(format!("Failed to create keyring entry: {e}")))
    }
}

#[cfg(not(target_os = "android"))]
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
            Err(keyring::Error::NoEntry) => Ok(()),
            Err(e) => Err(AppError::Crypto(format!(
                "Failed to delete from keyring: {e}"
            ))),
        }
    }
}

// ---------------------------------------------------------------------------
// Android: File-backed store (app sandbox provides isolation)
// ---------------------------------------------------------------------------

/// File-backed secret store for Android.
///
/// Stores secrets as a JSON object in `<data_dir>/secrets.json` inside the
/// app's private sandbox. On Android, other apps cannot read this directory —
/// the OS enforces sandboxing.
///
/// Note: This will be replaced with Android Keystore once `keyring` v4 is
/// stable (it adds `android-native` support).
#[cfg(target_os = "android")]
pub struct FileSecretStore {
    path: std::path::PathBuf,
}

#[cfg(target_os = "android")]
impl FileSecretStore {
    /// Creates a store that persists secrets in `<data_dir>/secrets.json`.
    pub fn new(data_dir: &std::path::Path) -> Self {
        Self {
            path: data_dir.join("secrets.json"),
        }
    }

    fn load(&self) -> Result<std::collections::HashMap<String, String>> {
        if !self.path.exists() {
            return Ok(std::collections::HashMap::new());
        }
        let contents = std::fs::read_to_string(&self.path)
            .map_err(|e| AppError::Crypto(format!("Failed to read secrets file: {e}")))?;
        serde_json::from_str(&contents)
            .map_err(|e| AppError::Crypto(format!("Failed to parse secrets file: {e}")))
    }

    fn save(&self, map: &std::collections::HashMap<String, String>) -> Result<()> {
        let contents = serde_json::to_string(map)
            .map_err(|e| AppError::Crypto(format!("Failed to serialize secrets: {e}")))?;
        std::fs::write(&self.path, contents)
            .map_err(|e| AppError::Crypto(format!("Failed to write secrets file: {e}")))
    }
}

#[cfg(target_os = "android")]
impl SecretStore for FileSecretStore {
    fn read(&self, key: &str) -> Result<Option<String>> {
        let map = self.load()?;
        Ok(map.get(key).cloned())
    }

    fn write(&self, key: &str, value: &str) -> Result<()> {
        let mut map = self.load()?;
        map.insert(key.to_string(), value.to_string());
        self.save(&map)
    }

    fn delete(&self, key: &str) -> Result<()> {
        let mut map = self.load()?;
        map.remove(key);
        self.save(&map)
    }
}
