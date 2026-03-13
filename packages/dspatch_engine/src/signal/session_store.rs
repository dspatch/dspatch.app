// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed session store implementing `libsignal_protocol::SessionStore`.

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

fn store_err(method: &'static str, msg: String) -> SignalProtocolError {
    SignalProtocolError::ApplicationCallbackError(method, Box::new(StoreError(msg)))
}

pub struct SqliteSessionStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSessionStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }
}

#[async_trait(?Send)]
impl SessionStore for SqliteSessionStore {
    async fn load_session(&self, address: &ProtocolAddress) -> Result<Option<SessionRecord>, SignalProtocolError> {
        let addr_name = address.name().to_string();
        let device_id: u32 = address.device_id().into();

        let conn = self.conn.lock().map_err(|e| store_err("load_session", e.to_string()))?;

        let record_bytes: Option<Vec<u8>> = conn
            .query_row("SELECT record FROM signal_sessions WHERE address = ?1 AND device_id = ?2", rusqlite::params![&addr_name, device_id], |row| row.get(0))
            .ok();

        match record_bytes {
            None => Ok(None),
            Some(bytes) => {
                let record = SessionRecord::deserialize(&bytes)?;
                Ok(Some(record))
            }
        }
    }

    async fn store_session(&mut self, address: &ProtocolAddress, record: &SessionRecord) -> Result<(), SignalProtocolError> {
        let addr_name = address.name().to_string();
        let device_id: u32 = address.device_id().into();
        let record_bytes = record.serialize()?;

        let conn = self.conn.lock().map_err(|e| store_err("store_session", e.to_string()))?;

        conn.execute("INSERT OR REPLACE INTO signal_sessions (address, device_id, record) VALUES (?1, ?2, ?3)", rusqlite::params![&addr_name, device_id, &record_bytes])
            .map_err(|e| store_err("store_session", e.to_string()))?;
        Ok(())
    }
}
