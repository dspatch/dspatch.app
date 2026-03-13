// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed sender key store.
//!
//! Sender keys are used for group messaging (one sender key per
//! (sender_address, device_id, distribution_id) triple). This enables
//! efficient fan-out encryption where the sender encrypts once and all
//! group members can decrypt.

use std::sync::{Arc, Mutex};

use crate::db::optional_ext::OptionalExt;

use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

/// A stored sender key record.
#[derive(Debug, Clone)]
pub struct SenderKeyRecord {
    pub sender_address: String,
    pub device_id: u32,
    pub distribution_id: String,
    pub record: Vec<u8>,
}

/// SQLite-backed sender key store.
pub struct SqliteSenderKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSenderKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }

    /// Stores a sender key record.
    pub fn store_sender_key(
        &self,
        sender_address: &str,
        device_id: u32,
        distribution_id: &str,
        record: &[u8],
    ) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "INSERT OR REPLACE INTO signal_sender_keys \
             (sender_address, device_id, distribution_id, record) \
             VALUES (?1, ?2, ?3, ?4)",
            rusqlite::params![sender_address, device_id, distribution_id, record],
        )
        .map_err(|e| AppError::Storage(format!("Failed to store sender key: {e}")))?;
        Ok(())
    }

    /// Loads a sender key record.
    pub fn load_sender_key(
        &self,
        sender_address: &str,
        device_id: u32,
        distribution_id: &str,
    ) -> Result<Option<SenderKeyRecord>> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let mut stmt = conn
            .prepare(
                "SELECT sender_address, device_id, distribution_id, record \
                 FROM signal_sender_keys \
                 WHERE sender_address = ?1 AND device_id = ?2 AND distribution_id = ?3",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare query: {e}")))?;

        let result = stmt
            .query_row(
                rusqlite::params![sender_address, device_id, distribution_id],
                |row| {
                    Ok(SenderKeyRecord {
                        sender_address: row.get(0)?,
                        device_id: row.get::<_, u32>(1)?,
                        distribution_id: row.get(2)?,
                        record: row.get(3)?,
                    })
                },
            )
            .optional()
            .map_err(|e| AppError::Storage(format!("Failed to query sender key: {e}")))?;

        Ok(result)
    }
}
