// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite-backed session store.
//!
//! Sessions hold the ratchet state for an ongoing encrypted conversation
//! with a specific (address, device_id) peer. The session record is a
//! serialised blob containing chain keys, message keys, and ratchet state.

use std::sync::{Arc, Mutex};

use crate::db::optional_ext::OptionalExt;

use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

/// A stored session record.
#[derive(Debug, Clone)]
pub struct SessionRecord {
    pub address: String,
    pub device_id: u32,
    pub record: Vec<u8>,
}

/// SQLite-backed session store.
pub struct SqliteSessionStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSessionStore {
    pub fn new(conn: Arc<Mutex<Connection>>) -> Self {
        Self { conn }
    }

    /// Stores (or replaces) a session record for the given peer.
    pub fn store_session(
        &self,
        address: &str,
        device_id: u32,
        record: &[u8],
    ) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "INSERT OR REPLACE INTO signal_sessions (address, device_id, record) \
             VALUES (?1, ?2, ?3)",
            rusqlite::params![address, device_id, record],
        )
        .map_err(|e| AppError::Storage(format!("Failed to store session: {e}")))?;
        Ok(())
    }

    /// Loads a session record for the given peer.
    pub fn load_session(
        &self,
        address: &str,
        device_id: u32,
    ) -> Result<Option<SessionRecord>> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let mut stmt = conn
            .prepare(
                "SELECT address, device_id, record FROM signal_sessions \
                 WHERE address = ?1 AND device_id = ?2",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare query: {e}")))?;

        let result = stmt
            .query_row(rusqlite::params![address, device_id], |row| {
                Ok(SessionRecord {
                    address: row.get(0)?,
                    device_id: row.get::<_, u32>(1)?,
                    record: row.get(2)?,
                })
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Failed to query session: {e}")))?;

        Ok(result)
    }

    /// Checks whether a session exists for the given peer.
    pub fn contains_session(&self, address: &str, device_id: u32) -> Result<bool> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let count: i64 = conn
            .query_row(
                "SELECT COUNT(*) FROM signal_sessions WHERE address = ?1 AND device_id = ?2",
                rusqlite::params![address, device_id],
                |row| row.get(0),
            )
            .map_err(|e| AppError::Storage(format!("Failed to check session: {e}")))?;
        Ok(count > 0)
    }

    /// Deletes a session for the given peer.
    pub fn delete_session(&self, address: &str, device_id: u32) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(
            "DELETE FROM signal_sessions WHERE address = ?1 AND device_id = ?2",
            rusqlite::params![address, device_id],
        )
        .map_err(|e| AppError::Storage(format!("Failed to delete session: {e}")))?;
        Ok(())
    }

    /// Returns all device IDs with sessions for the given address (excluding
    /// device ID 1, which is the primary device by convention).
    pub fn get_sub_device_sessions(&self, address: &str) -> Result<Vec<u32>> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        let mut stmt = conn
            .prepare(
                "SELECT device_id FROM signal_sessions \
                 WHERE address = ?1 AND device_id != 1",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare query: {e}")))?;

        let rows = stmt
            .query_map(rusqlite::params![address], |row| row.get::<_, u32>(0))
            .map_err(|e| AppError::Storage(format!("Failed to query sub-device sessions: {e}")))?;

        let mut ids = Vec::new();
        for row in rows {
            ids.push(
                row.map_err(|e| {
                    AppError::Storage(format!("Failed to read device_id: {e}"))
                })?,
            );
        }
        Ok(ids)
    }
}
