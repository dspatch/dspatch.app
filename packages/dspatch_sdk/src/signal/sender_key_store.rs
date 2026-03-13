// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed sender key store implementing `libsignal_protocol::SenderKeyStore`.

use std::sync::{Arc, Mutex};
use async_trait::async_trait;
use libsignal_protocol::*;
use rusqlite::Connection;
use uuid::Uuid;

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

pub struct SqliteSenderKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSenderKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }
}

#[async_trait(?Send)]
impl SenderKeyStore for SqliteSenderKeyStore {
    async fn store_sender_key(&mut self, sender: &ProtocolAddress, distribution_id: Uuid, record: &SenderKeyRecord) -> Result<(), SignalProtocolError> {
        let addr = sender.name().to_string();
        let device_id: u32 = sender.device_id().into();
        let dist_id = distribution_id.to_string();
        let record_bytes = record.serialize()?;

        let conn = self.conn.lock().map_err(|e| store_err("store_sender_key", e.to_string()))?;

        conn.execute("INSERT OR REPLACE INTO signal_sender_keys (sender_address, device_id, distribution_id, record) VALUES (?1, ?2, ?3, ?4)", rusqlite::params![&addr, device_id, &dist_id, &record_bytes])
            .map_err(|e| store_err("store_sender_key", e.to_string()))?;
        Ok(())
    }

    async fn load_sender_key(&mut self, sender: &ProtocolAddress, distribution_id: Uuid) -> Result<Option<SenderKeyRecord>, SignalProtocolError> {
        let addr = sender.name().to_string();
        let device_id: u32 = sender.device_id().into();
        let dist_id = distribution_id.to_string();

        let conn = self.conn.lock().map_err(|e| store_err("load_sender_key", e.to_string()))?;

        let record_bytes: Option<Vec<u8>> = conn
            .query_row("SELECT record FROM signal_sender_keys WHERE sender_address = ?1 AND device_id = ?2 AND distribution_id = ?3", rusqlite::params![&addr, device_id, &dist_id], |row| row.get(0))
            .ok();

        match record_bytes {
            None => Ok(None),
            Some(bytes) => {
                let record = SenderKeyRecord::deserialize(&bytes)?;
                Ok(Some(record))
            }
        }
    }
}
