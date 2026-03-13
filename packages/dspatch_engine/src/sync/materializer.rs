// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Change materializer — converts `SyncChange` entries from the sync outbox
//! into actual SQL statements executed against the target table.
//!
//! The materializer handles three operations:
//! - **Insert**: `INSERT OR REPLACE INTO {table} ({columns}) VALUES ({values})`
//! - **Update**: Same as insert (INSERT OR REPLACE is idempotent)
//! - **Delete**: `DELETE FROM {table} WHERE id = {row_id}`
//!
//! The `data` field in a `SyncChange` is a JSON object where keys are column
//! names and values are column values. The materializer dynamically constructs
//! parameterised SQL from this JSON.

use rusqlite::types::ToSql;

use super::message::{SyncChange, SyncOp};
use crate::util::error::AppError;
use crate::util::result::Result;

/// Materializes sync changes into actual database rows.
pub struct ChangeMaterializer;

impl ChangeMaterializer {
    /// Applies a single `SyncChange` to the database.
    ///
    /// For Insert and Update, the `change.data` must be a JSON object with
    /// column names as keys. For Delete, only `change.row_id` is needed.
    pub fn apply(conn: &rusqlite::Connection, change: &SyncChange) -> Result<()> {
        match change.operation {
            SyncOp::Insert | SyncOp::Update => Self::upsert(conn, change),
            SyncOp::Delete => Self::delete(conn, change),
        }
    }

    /// Performs an INSERT OR REPLACE (upsert) from the change's JSON data.
    fn upsert(conn: &rusqlite::Connection, change: &SyncChange) -> Result<()> {
        let obj = change
            .data
            .as_object()
            .ok_or_else(|| AppError::Internal("SyncChange data must be a JSON object".into()))?;

        if obj.is_empty() {
            return Err(AppError::Internal("SyncChange data is empty".into()));
        }

        let columns: Vec<&str> = obj.keys().map(|k| k.as_str()).collect();
        let placeholders: Vec<String> = (1..=columns.len()).map(|i| format!("?{i}")).collect();

        // Sanitize table name (only allow alphanumeric + underscore).
        let table = &change.table;
        if !table.chars().all(|c| c.is_alphanumeric() || c == '_') {
            return Err(AppError::Internal(format!("Invalid table name: {table}")));
        }

        let sql = format!(
            "INSERT OR REPLACE INTO {table} ({cols}) VALUES ({vals})",
            table = table,
            cols = columns.join(", "),
            vals = placeholders.join(", "),
        );

        // Convert JSON values to rusqlite params.
        let params: Vec<Box<dyn ToSql>> = obj
            .values()
            .map(|v| -> Box<dyn ToSql> {
                match v {
                    serde_json::Value::Null => Box::new(rusqlite::types::Null),
                    serde_json::Value::Bool(b) => Box::new(*b),
                    serde_json::Value::Number(n) => {
                        if let Some(i) = n.as_i64() {
                            Box::new(i)
                        } else if let Some(f) = n.as_f64() {
                            Box::new(f)
                        } else {
                            Box::new(n.to_string())
                        }
                    }
                    serde_json::Value::String(s) => Box::new(s.clone()),
                    other => Box::new(other.to_string()),
                }
            })
            .collect();

        let param_refs: Vec<&dyn ToSql> = params.iter().map(|p| p.as_ref()).collect();

        conn.execute(&sql, param_refs.as_slice()).map_err(|e| {
            AppError::Storage(format!(
                "Failed to materialize {op:?} into {table}: {e}",
                op = change.operation,
                table = change.table,
            ))
        })?;

        Ok(())
    }

    /// Deletes a row by its `row_id` (assumed to be the `id` column).
    fn delete(conn: &rusqlite::Connection, change: &SyncChange) -> Result<()> {
        let table = &change.table;
        if !table.chars().all(|c| c.is_alphanumeric() || c == '_') {
            return Err(AppError::Internal(format!("Invalid table name: {table}")));
        }

        let sql = format!("DELETE FROM {table} WHERE id = ?1");

        conn.execute(&sql, rusqlite::params![&change.row_id])
            .map_err(|e| {
                AppError::Storage(format!(
                    "Failed to materialize delete from {table}: {e}",
                ))
            })?;

        Ok(())
    }
}
