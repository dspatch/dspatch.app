// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed one-time prekey store.
//!
//! One-time prekeys are X25519 keypairs used for initial key agreement.
//! Each prekey is used at most once, then deleted.

use std::sync::{Arc, Mutex};

use rusqlite::Connection;

use crate::db::optional_ext::OptionalExt;

use crate::util::error::AppError;
use crate::util::result::Result;

/// A serialised prekey record: `private_key (32) || public_key (32)`.
#[derive(Debug, Clone)]
pub struct PreKeyRecord {
    pub id: u32,
    pub record: Vec<u8>,
}

/// SQLite-backed one-time prekey store.
pub struct SqlitePreKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqlitePreKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }

    /// Stores a prekey record.
    pub fn save_prekey(&self, id: u32, record: &[u8]) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "INSERT OR REPLACE INTO signal_prekeys (id, record) VALUES (?1, ?2)",
            rusqlite::params![id, record],
        )
        .map_err(|e| AppError::Storage(format!("Failed to save prekey: {e}")))?;
        Ok(())
    }

    /// Loads a prekey record by ID.
    pub fn get_prekey(&self, id: u32) -> Result<Option<PreKeyRecord>> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let mut stmt = conn
            .prepare("SELECT id, record FROM signal_prekeys WHERE id = ?1")
            .map_err(|e| AppError::Storage(format!("Failed to prepare query: {e}")))?;

        let result = stmt
            .query_row(rusqlite::params![id], |row| {
                Ok(PreKeyRecord {
                    id: row.get::<_, u32>(0)?,
                    record: row.get(1)?,
                })
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Failed to query prekey: {e}")))?;

        Ok(result)
    }

    /// Checks whether a prekey with the given ID exists.
    pub fn contains_prekey(&self, id: u32) -> Result<bool> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let count: i64 = conn
            .query_row(
                "SELECT COUNT(*) FROM signal_prekeys WHERE id = ?1",
                rusqlite::params![id],
                |row| row.get(0),
            )
            .map_err(|e| AppError::Storage(format!("Failed to check prekey: {e}")))?;
        Ok(count > 0)
    }

    /// Removes a prekey (after it has been used).
    pub fn remove_prekey(&self, id: u32) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "DELETE FROM signal_prekeys WHERE id = ?1",
            rusqlite::params![id],
        )
        .map_err(|e| AppError::Storage(format!("Failed to remove prekey: {e}")))?;
        Ok(())
    }
}
