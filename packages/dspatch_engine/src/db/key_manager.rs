// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Per-database encryption key management.
//!
//! Each database (anonymous or per-user) has its own random 256-bit key stored
//! in a platform secret store.  Keys are generated on first use and retrieved
//! on subsequent opens.
//!
//! Ported from `database_key_manager.dart`.

use base64::Engine;
use sha2::{Digest, Sha256};

use crate::util::result::Result;

/// Storage key prefix for database encryption keys.
const ANONYMOUS_KEY_NAME: &str = "dspatch_db_key";

/// Abstraction over platform-specific secret storage (keyring, secure
/// enclave, etc.).
///
/// Implementors must be safe to share across threads.
pub trait SecretStore: Send + Sync {
    /// Reads a secret by key.  Returns `Ok(None)` if the key does not exist.
    fn read(&self, key: &str) -> Result<Option<String>>;

    /// Writes (or overwrites) a secret.
    fn write(&self, key: &str, value: &str) -> Result<()>;

    /// Deletes a secret.  No-op if the key does not exist.
    fn delete(&self, key: &str) -> Result<()>;
}

/// Manages per-database encryption keys backed by a [`SecretStore`].
pub struct DatabaseKeyManager {
    store: Box<dyn SecretStore>,
}

impl DatabaseKeyManager {
    pub fn new(store: Box<dyn SecretStore>) -> Self {
        Self { store }
    }

    /// Returns the storage key name for a given user hash (or anonymous).
    fn storage_key(username_hash: Option<&str>) -> String {
        match username_hash {
            Some(hash) => format!("{ANONYMOUS_KEY_NAME}:{hash}"),
            None => ANONYMOUS_KEY_NAME.to_string(),
        }
    }

    /// Retrieves the encryption key for a database.  If none exists,
    /// generates a random 256-bit key and stores it.
    pub fn get_or_create_key(&self, username_hash: Option<&str>) -> Result<String> {
        let key = Self::storage_key(username_hash);

        if let Some(existing) = self.store.read(&key)? {
            return Ok(existing);
        }

        // Generate 32 random bytes and base64-encode.
        let mut bytes = [0u8; 32];
        rand::Fill::fill(&mut bytes, &mut rand::rng());
        let encoded = base64::engine::general_purpose::STANDARD.encode(bytes);

        self.store.write(&key, &encoded)?;
        Ok(encoded)
    }

    /// Returns the first 16 hex characters of the SHA-256 digest of
    /// `username`.  Used as the per-user database directory name.
    pub fn hash_username(username: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(username.as_bytes());
        let digest = hasher.finalize();
        // Format as lowercase hex, take first 16 chars.
        let hex = format!("{digest:x}");
        hex[..16].to_string()
    }
}

/// A simple in-memory secret store for testing.
pub mod testing {
    use super::*;
    use std::collections::HashMap;
    use std::sync::Mutex;

    /// An in-memory [`SecretStore`] implementation for use in tests.
    pub struct InMemorySecretStore {
        data: Mutex<HashMap<String, String>>,
    }

    impl InMemorySecretStore {
        pub fn new() -> Self {
            Self {
                data: Mutex::new(HashMap::new()),
            }
        }
    }

    impl SecretStore for InMemorySecretStore {
        fn read(&self, key: &str) -> Result<Option<String>> {
            Ok(self.data.lock().unwrap_or_else(|e| e.into_inner()).get(key).cloned())
        }

        fn write(&self, key: &str, value: &str) -> Result<()> {
            self.data
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .insert(key.to_string(), value.to_string());
            Ok(())
        }

        fn delete(&self, key: &str) -> Result<()> {
            self.data.lock().unwrap_or_else(|e| e.into_inner()).remove(key);
            Ok(())
        }
    }
}
