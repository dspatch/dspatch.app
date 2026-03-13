// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed identity key store implementing `libsignal_protocol::IdentityKeyStore`.

use std::sync::{Arc, Mutex};

use async_trait::async_trait;
use libsignal_protocol::*;
use rusqlite::Connection;

/// A simple error type that is `Send + Sync + UnwindSafe` for use with
/// `SignalProtocolError::ApplicationCallbackError`.
#[derive(Debug)]
struct StoreError(String);

impl std::fmt::Display for StoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::error::Error for StoreError {}

pub struct SqliteIdentityStore {
    conn: Arc<Mutex<Connection>>,
    local_registration_id: u32,
    identity_key_pair: IdentityKeyPair,
}

impl SqliteIdentityStore {
    pub fn new(
        conn: Arc<Mutex<Connection>>,
        local_registration_id: u32,
        identity_key_pair: IdentityKeyPair,
    ) -> Self {
        Self { conn, local_registration_id, identity_key_pair }
    }
}

fn store_err(method: &'static str, msg: String) -> SignalProtocolError {
    SignalProtocolError::ApplicationCallbackError(method, Box::new(StoreError(msg)))
}

#[async_trait(?Send)]
impl IdentityKeyStore for SqliteIdentityStore {
    async fn get_identity_key_pair(&self) -> Result<IdentityKeyPair, SignalProtocolError> {
        Ok(self.identity_key_pair)
    }

    async fn get_local_registration_id(&self) -> Result<u32, SignalProtocolError> {
        Ok(self.local_registration_id)
    }

    async fn save_identity(
        &mut self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
    ) -> Result<IdentityChange, SignalProtocolError> {
        let addr_name = address.name().to_string();
        let device_id: u32 = address.device_id().into();
        let key_bytes = identity.serialize().to_vec();

        let conn = self.conn.lock().map_err(|e| store_err("save_identity", e.to_string()))?;

        let existing: Option<Vec<u8>> = conn
            .query_row(
                "SELECT identity_key FROM signal_identities WHERE address = ?1 AND device_id = ?2",
                rusqlite::params![&addr_name, device_id],
                |row| row.get(0),
            )
            .ok();

        let changed = match &existing {
            Some(old_key) => old_key != &key_bytes,
            None => false,
        };

        conn.execute(
            "INSERT OR REPLACE INTO signal_identities (address, device_id, identity_key, trust_level) VALUES (?1, ?2, ?3, ?4)",
            rusqlite::params![&addr_name, device_id, &key_bytes, 1i32],
        ).map_err(|e| store_err("save_identity", e.to_string()))?;

        Ok(IdentityChange::from_changed(changed))
    }

    async fn is_trusted_identity(
        &self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
        _direction: Direction,
    ) -> Result<bool, SignalProtocolError> {
        let addr_name = address.name().to_string();
        let device_id: u32 = address.device_id().into();

        let conn = self.conn.lock().map_err(|e| store_err("is_trusted_identity", e.to_string()))?;

        let existing: Option<Vec<u8>> = conn
            .query_row(
                "SELECT identity_key FROM signal_identities WHERE address = ?1 AND device_id = ?2",
                rusqlite::params![&addr_name, device_id],
                |row| row.get(0),
            )
            .ok();

        match existing {
            None => Ok(true), // TOFU
            Some(stored_key) => Ok(stored_key == identity.serialize().as_ref()),
        }
    }

    async fn get_identity(
        &self,
        address: &ProtocolAddress,
    ) -> Result<Option<IdentityKey>, SignalProtocolError> {
        let addr_name = address.name().to_string();
        let device_id: u32 = address.device_id().into();

        let conn = self.conn.lock().map_err(|e| store_err("get_identity", e.to_string()))?;

        let key_bytes: Option<Vec<u8>> = conn
            .query_row(
                "SELECT identity_key FROM signal_identities WHERE address = ?1 AND device_id = ?2",
                rusqlite::params![&addr_name, device_id],
                |row| row.get(0),
            )
            .ok();

        match key_bytes {
            None => Ok(None),
            Some(bytes) => {
                let key = IdentityKey::decode(&bytes).map_err(|e| store_err("get_identity", e.to_string()))?;
                Ok(Some(key))
            }
        }
    }
}
