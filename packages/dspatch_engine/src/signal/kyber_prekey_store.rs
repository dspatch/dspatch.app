// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed Kyber pre-key store implementing `libsignal_protocol::KyberPreKeyStore`.

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

pub struct SqliteKyberPreKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteKyberPreKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }
}

#[async_trait(?Send)]
impl KyberPreKeyStore for SqliteKyberPreKeyStore {
    async fn get_kyber_pre_key(&self, kyber_prekey_id: KyberPreKeyId) -> Result<KyberPreKeyRecord, SignalProtocolError> {
        let id: u32 = kyber_prekey_id.into();
        let conn = self.conn.lock();

        let record_bytes: Vec<u8> = conn
            .query_row("SELECT record FROM signal_kyber_prekeys WHERE id = ?1", rusqlite::params![id], |row| row.get(0))
            .map_err(|_| SignalProtocolError::InvalidKyberPreKeyId)?;

        KyberPreKeyRecord::deserialize(&record_bytes)
    }

    async fn save_kyber_pre_key(&mut self, kyber_prekey_id: KyberPreKeyId, record: &KyberPreKeyRecord) -> Result<(), SignalProtocolError> {
        let id: u32 = kyber_prekey_id.into();
        let record_bytes = record.serialize()?;
        let conn = self.conn.lock();

        conn.execute("INSERT OR REPLACE INTO signal_kyber_prekeys (id, record) VALUES (?1, ?2)", rusqlite::params![id, &record_bytes])
            .map_err(|e| store_err("save_kyber_pre_key", e.to_string()))?;
        Ok(())
    }

    async fn mark_kyber_pre_key_used(&mut self, kyber_prekey_id: KyberPreKeyId, _ec_prekey_id: SignedPreKeyId, _base_key: &PublicKey) -> Result<(), SignalProtocolError> {
        // For one-time Kyber prekeys, delete after use.
        let id: u32 = kyber_prekey_id.into();
        let conn = self.conn.lock();

        conn.execute("DELETE FROM signal_kyber_prekeys WHERE id = ?1", rusqlite::params![id])
            .map_err(|e| store_err("mark_kyber_pre_key_used", e.to_string()))?;
        Ok(())
    }
}
