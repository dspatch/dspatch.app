// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed prekey store implementing `libsignal_protocol::PreKeyStore`.

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

pub struct SqlitePreKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqlitePreKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }
}

#[async_trait(?Send)]
impl PreKeyStore for SqlitePreKeyStore {
    async fn get_pre_key(&self, prekey_id: PreKeyId) -> Result<PreKeyRecord, SignalProtocolError> {
        let id: u32 = prekey_id.into();
        let conn = self.conn.lock();

        let record_bytes: Vec<u8> = conn
            .query_row("SELECT record FROM signal_prekeys WHERE id = ?1", rusqlite::params![id], |row| row.get(0))
            .map_err(|_| SignalProtocolError::InvalidPreKeyId)?;

        PreKeyRecord::deserialize(&record_bytes)
    }

    async fn save_pre_key(&mut self, prekey_id: PreKeyId, record: &PreKeyRecord) -> Result<(), SignalProtocolError> {
        let id: u32 = prekey_id.into();
        let record_bytes = record.serialize()?;
        let conn = self.conn.lock();

        conn.execute("INSERT OR REPLACE INTO signal_prekeys (id, record) VALUES (?1, ?2)", rusqlite::params![id, &record_bytes])
            .map_err(|e| store_err("save_pre_key", e.to_string()))?;
        Ok(())
    }

    async fn remove_pre_key(&mut self, prekey_id: PreKeyId) -> Result<(), SignalProtocolError> {
        let id: u32 = prekey_id.into();
        let conn = self.conn.lock();

        conn.execute("DELETE FROM signal_prekeys WHERE id = ?1", rusqlite::params![id])
            .map_err(|e| store_err("remove_pre_key", e.to_string()))?;
        Ok(())
    }
}
