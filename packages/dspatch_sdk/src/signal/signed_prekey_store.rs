// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed signed prekey store.
//!
//! Signed prekeys are medium-term X25519 keypairs signed with the device's
//! Ed25519 identity key. They are rotated periodically (e.g. weekly).

use std::sync::{Arc, Mutex};

use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

/// A signed prekey record: `private_key (32) || public_key (32) || signature (64)`.
#[derive(Debug, Clone)]
pub struct SignedPreKeyRecord {
    pub id: u32,
    pub record: Vec<u8>,
    pub created_at: String,
}

/// SQLite-backed signed prekey store.
pub struct SqliteSignedPreKeyStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSignedPreKeyStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }

    /// Stores a signed prekey record.
    pub fn save_signed_prekey(
        &self,
        id: u32,
        record: &[u8],
        created_at: &str,
    ) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "INSERT OR REPLACE INTO signal_signed_prekeys (id, record, created_at) \
             VALUES (?1, ?2, ?3)",
            rusqlite::params![id, record, created_at],
        )
        .map_err(|e| AppError::Storage(format!("Failed to save signed prekey: {e}")))?;
        Ok(())
    }

    /// Loads a signed prekey record by ID.
    pub fn get_signed_prekey(&self, id: u32) -> Result<Option<SignedPreKeyRecord>> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let mut stmt = conn
            .prepare(
                "SELECT id, record, created_at FROM signal_signed_prekeys WHERE id = ?1",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare query: {e}")))?;

        let result = stmt
            .query_row(rusqlite::params![id], |row| {
                Ok(SignedPreKeyRecord {
                    id: row.get::<_, u32>(0)?,
                    record: row.get(1)?,
                    created_at: row.get(2)?,
                })
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Failed to query signed prekey: {e}")))?;

        Ok(result)
    }

    /// Removes a signed prekey.
    pub fn remove_signed_prekey(&self, id: u32) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "DELETE FROM signal_signed_prekeys WHERE id = ?1",
            rusqlite::params![id],
        )
        .map_err(|e| AppError::Storage(format!("Failed to remove signed prekey: {e}")))?;
        Ok(())
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
