// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed identity key store.
//!
//! Stores the local device's Ed25519 identity keypair and the identity public
//! keys of remote peers. Trust levels:
//!   0 = untrusted, 1 = trusted_unverified, 2 = trusted_verified.

use std::sync::{Arc, Mutex};

use ed25519_dalek::{SigningKey, VerifyingKey};
use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

/// Trust level for a remote identity key.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(i32)]
pub enum TrustLevel {
    Untrusted = 0,
    TrustedUnverified = 1,
    TrustedVerified = 2,
}

impl TrustLevel {
    pub fn from_i32(v: i32) -> Self {
        match v {
            1 => Self::TrustedUnverified,
            2 => Self::TrustedVerified,
            _ => Self::Untrusted,
        }
    }
}

/// A stored identity record for a remote peer.
#[derive(Debug, Clone)]
pub struct IdentityRecord {
    pub address: String,
    pub device_id: u32,
    pub identity_key: Vec<u8>,
    pub trust_level: TrustLevel,
}

/// SQLite-backed identity key store.
pub struct SqliteIdentityStore {
    conn: Arc<Mutex<Connection>>,
    local_registration_id: u32,
    signing_key: SigningKey,
}

impl SqliteIdentityStore {
    /// Creates a new identity store.
    ///
    /// `signing_key` is the local device's Ed25519 signing key (contains both
    /// the private scalar and the public verifying key).
    pub fn new(
        conn: Arc<Mutex<Connection>>,
        local_registration_id: u32,
        signing_key: SigningKey,
    ) -> Self {
        Self {
            conn,
            local_registration_id,
            signing_key,
        }
    }

    /// Returns the local registration ID.
    pub fn get_local_registration_id(&self) -> u32 {
        self.local_registration_id
    }

    /// Returns a reference to the local Ed25519 signing key.
    pub fn get_signing_key(&self) -> &SigningKey {
        &self.signing_key
    }

    /// Returns the local Ed25519 verifying (public) key.
    pub fn get_verifying_key(&self) -> VerifyingKey {
        self.signing_key.verifying_key()
    }

    /// Returns the local identity public key bytes (32 bytes).
    pub fn get_identity_public_key_bytes(&self) -> Vec<u8> {
        self.signing_key.verifying_key().to_bytes().to_vec()
    }

    /// Saves a remote peer's identity key.
    pub fn save_identity(
        &self,
        address: &str,
        device_id: u32,
        identity_key: &[u8],
        trust_level: TrustLevel,
    ) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "INSERT OR REPLACE INTO signal_identities (address, device_id, identity_key, trust_level) \
             VALUES (?1, ?2, ?3, ?4)",
            rusqlite::params![address, device_id, identity_key, trust_level as i32],
        )
        .map_err(|e| AppError::Storage(format!("Failed to save identity: {e}")))?;
        Ok(())
    }

    /// Loads a remote peer's identity record.
    pub fn get_identity(&self, address: &str, device_id: u32) -> Result<Option<IdentityRecord>> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let mut stmt = conn
            .prepare(
                "SELECT address, device_id, identity_key, trust_level \
                 FROM signal_identities WHERE address = ?1 AND device_id = ?2",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare query: {e}")))?;

        let result = stmt
            .query_row(rusqlite::params![address, device_id], |row| {
                Ok(IdentityRecord {
                    address: row.get(0)?,
                    device_id: row.get::<_, u32>(1)?,
                    identity_key: row.get(2)?,
                    trust_level: TrustLevel::from_i32(row.get::<_, i32>(3)?),
                })
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Failed to query identity: {e}")))?;

        Ok(result)
    }

    /// Checks whether the given identity key is trusted for the address.
    ///
    /// Returns `true` if no prior identity is stored (trust on first use) or
    /// if the stored key matches the provided one.
    pub fn is_trusted_identity(
        &self,
        address: &str,
        device_id: u32,
        identity_key: &[u8],
    ) -> Result<bool> {
        match self.get_identity(address, device_id)? {
            None => Ok(true), // TOFU: trust on first use
            Some(record) => Ok(record.identity_key == identity_key),
        }
    }
}

/// Extension trait to add `optional()` to rusqlite results.
trait OptionalExt<T> {
    fn optional(self) -> std::result::Result<Option<T>, rusqlite::Error>;
}

impl<T> OptionalExt<T> for std::result::Result<T, rusqlite::Error> {
    fn optional(self) -> std::result::Result<Option<T>, rusqlite::Error> {
        match self {
            Ok(v) => Ok(Some(v)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e),
        }
    }
}
