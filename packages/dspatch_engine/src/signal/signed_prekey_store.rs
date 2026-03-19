// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed signed prekey store implementing `libsignal_protocol::SignedPreKeyStore`.

use std::sync::Arc;

use parking_lot::Mutex;
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

fn store_err(method: &'static str, msg: String) -> SignalProtocolError {
    SignalProtocolError::ApplicationCallbackError(method, Box::new(StoreError(msg)))
}

pub struct SqliteSignedPreKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSignedPreKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }
}

#[async_trait(?Send)]
impl SignedPreKeyStore for SqliteSignedPreKeyStore {
    async fn get_signed_pre_key(&self, signed_prekey_id: SignedPreKeyId) -> Result<SignedPreKeyRecord, SignalProtocolError> {
        let id: u32 = signed_prekey_id.into();
        let conn = self.conn.lock();

        let record_bytes: Vec<u8> = conn
            .query_row("SELECT record FROM signal_signed_prekeys WHERE id = ?1", rusqlite::params![id], |row| row.get(0))
            .map_err(|_| SignalProtocolError::InvalidSignedPreKeyId)?;

        SignedPreKeyRecord::deserialize(&record_bytes)
    }

    async fn save_signed_pre_key(&mut self, signed_prekey_id: SignedPreKeyId, record: &SignedPreKeyRecord) -> Result<(), SignalProtocolError> {
        let id: u32 = signed_prekey_id.into();
        let record_bytes = record.serialize()?;
        let created_at = chrono::Utc::now().to_rfc3339();
        let conn = self.conn.lock();

        conn.execute("INSERT OR REPLACE INTO signal_signed_prekeys (id, record, created_at) VALUES (?1, ?2, ?3)", rusqlite::params![id, &record_bytes, &created_at])
            .map_err(|e| store_err("save_signed_pre_key", e.to_string()))?;
        Ok(())
    }
}
