// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access object for the key-value `preferences` table.

use std::pin::Pin;
use std::sync::Arc;

use futures::Stream;

use crate::db::optional_ext::OptionalExt;
use crate::db::reactive::watch_query;
use crate::db::Database;
use crate::util::result::Result;

/// Provides typed CRUD and reactive watch operations on the `preferences`
/// table.
pub struct PreferenceDao {
    db: Arc<Database>,
}

impl PreferenceDao {
    /// Creates a new DAO backed by the given database.
    pub fn new(db: Arc<Database>) -> Self {
        Self { db }
    }

    /// Returns the value for `key`, or `None` if no such preference exists.
    pub fn get_preference(&self, key: &str) -> Result<Option<String>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT value FROM preferences WHERE key = ?1")
            .map_err(|e| crate::util::error::AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![key], |row| row.get::<_, String>(0))
            .optional()
            .map_err(|e| crate::util::error::AppError::Storage(format!("Query failed: {e}")))?;
        Ok(result)
    }

    /// Inserts or replaces the preference `key` with `value`.
    pub fn set_preference(&self, key: &str, value: &str) -> Result<()> {
        self.db.execute(
            "INSERT OR REPLACE INTO preferences (key, value) VALUES (?1, ?2)",
            &[&key as &dyn rusqlite::types::ToSql, &value],
        )?;
        Ok(())
    }

    /// Returns a stream that emits the current value for `key` whenever the
    /// `preferences` table changes.
    pub fn watch_preference(
        &self,
        key: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Option<String>>> + Send>> {
        let key = key.to_string();
        let stream = watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["preferences"],
            move |conn| {
                let mut stmt = conn
                    .prepare("SELECT value FROM preferences WHERE key = ?1")
                    .map_err(|e| {
                        crate::util::error::AppError::Storage(format!("Prepare failed: {e}"))
                    })?;
                let result = stmt
                    .query_row(rusqlite::params![key], |row| row.get::<_, String>(0))
                    .optional()
                    .map_err(|e| {
                        crate::util::error::AppError::Storage(format!("Query failed: {e}"))
                    })?;
                // watch_query expects Vec<T>, so we wrap in a Vec and unwrap later.
                Ok(vec![result])
            },
        );

        // Map Vec<Option<String>> -> Option<String> by taking the first element.
        use futures::StreamExt;
        Box::pin(stream.map(|r| r.map(|v| v.into_iter().next().flatten())))
    }

    /// Deletes the preference with the given `key`.
    pub fn delete_preference(&self, key: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM preferences WHERE key = ?1",
            &[&key as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }
}
