// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access object for the `api_keys` table.

use std::pin::Pin;
use std::sync::Arc;

use futures::Stream;

use crate::db::reactive::watch_query;
use crate::db::Database;
use crate::domain::models::ApiKey;
use crate::util::error::AppError;
use crate::util::result::Result;

use super::parse_datetime;

/// Provides typed CRUD and reactive watch operations on the `api_keys` table.
pub struct ApiKeyDao {
    db: Arc<Database>,
}

impl ApiKeyDao {
    /// Creates a new DAO backed by the given database.
    pub fn new(db: Arc<Database>) -> Self {
        Self { db }
    }

    /// Returns a stream of all API keys, ordered by `created_at` descending.
    pub fn watch_api_keys(&self) -> Pin<Box<dyn Stream<Item = Result<Vec<ApiKey>>> + Send>> {
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["api_keys"],
            |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, name, provider_label, encrypted_key, display_hint, created_at FROM api_keys ORDER BY created_at DESC")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map([], |row| {
                        Ok(row_to_api_key(row))
                    })
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Returns the API key with the given `name`, or `None`.
    pub fn get_api_key_by_name(&self, name: &str) -> Result<Option<ApiKey>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, name, provider_label, encrypted_key, display_hint, created_at FROM api_keys WHERE name = ?1")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![name], |row| Ok(row_to_api_key(row)))
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Inserts a new API key.
    pub fn insert_api_key(
        &self,
        id: &str,
        name: &str,
        provider_label: &str,
        encrypted_key: &[u8],
        display_hint: Option<&str>,
    ) -> Result<()> {
        self.db.execute(
            "INSERT INTO api_keys (id, name, provider_label, encrypted_key, display_hint) VALUES (?1, ?2, ?3, ?4, ?5)",
            &[
                &id as &dyn rusqlite::types::ToSql,
                &name,
                &provider_label,
                &encrypted_key,
                &display_hint as &dyn rusqlite::types::ToSql,
            ],
        )?;
        Ok(())
    }

    /// Deletes the API key with the given `id`.
    pub fn delete_api_key(&self, id: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM api_keys WHERE id = ?1",
            &[&id as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }
}

fn row_to_api_key(row: &rusqlite::Row<'_>) -> Result<ApiKey> {
    let created_at_str: String = row
        .get(5)
        .map_err(|e| AppError::Storage(format!("Failed to read created_at: {e}")))?;
    Ok(ApiKey {
        id: row.get(0).map_err(|e| AppError::Storage(format!("Failed to read id: {e}")))?,
        name: row.get(1).map_err(|e| AppError::Storage(format!("Failed to read name: {e}")))?,
        provider_label: row
            .get(2)
            .map_err(|e| AppError::Storage(format!("Failed to read provider_label: {e}")))?,
        encrypted_key: row
            .get(3)
            .map_err(|e| AppError::Storage(format!("Failed to read encrypted_key: {e}")))?,
        display_hint: row
            .get(4)
            .map_err(|e| AppError::Storage(format!("Failed to read display_hint: {e}")))?,
        created_at: parse_datetime(&created_at_str)?,
    })
}

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
