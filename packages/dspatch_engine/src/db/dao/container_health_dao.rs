// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! DAO for the `container_health` ephemeral table.

use rusqlite::Connection;

use crate::db::optional_ext::OptionalExt;
use crate::util::result::Result;

/// Row model for `container_health`.
#[derive(Debug, Clone)]
pub struct ContainerHealth {
    pub run_id: String,
    pub status: String,
    pub error_message: Option<String>,
    pub updated_at: String,
}

pub struct ContainerHealthDao;

impl ContainerHealthDao {
    pub fn new() -> Self {
        Self
    }

    /// Upserts the container health status for a run.
    pub fn upsert(
        &self,
        conn: &Connection,
        run_id: &str,
        status: &str,
        error_message: Option<&str>,
    ) -> Result<()> {
        conn.execute(
            "INSERT INTO container_health (run_id, status, error_message, updated_at)
             VALUES (?1, ?2, ?3, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
             ON CONFLICT(run_id) DO UPDATE SET
                status = excluded.status,
                error_message = excluded.error_message,
                updated_at = excluded.updated_at",
            rusqlite::params![run_id, status, error_message],
        )
        .map_err(|e| crate::util::error::AppError::Storage(format!("upsert container_health: {e}")))?;
        Ok(())
    }

    /// Gets the container health for a run.
    pub fn get(&self, conn: &Connection, run_id: &str) -> Result<Option<ContainerHealth>> {
        conn.query_row(
            "SELECT run_id, status, error_message, updated_at
             FROM container_health WHERE run_id = ?1",
            [run_id],
            |row| {
                Ok(ContainerHealth {
                    run_id: row.get(0)?,
                    status: row.get(1)?,
                    error_message: row.get(2)?,
                    updated_at: row.get(3)?,
                })
            },
        )
        .optional()
        .map_err(|e| crate::util::error::AppError::Storage(format!("get container_health: {e}")))
    }
}
