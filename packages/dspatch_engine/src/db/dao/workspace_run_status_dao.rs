// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! DAO for the `workspace_run_status` ephemeral table.

use rusqlite::Connection;

use crate::db::optional_ext::OptionalExt;
use crate::util::result::Result;

/// Row model for `workspace_run_status`.
#[derive(Debug, Clone)]
pub struct WorkspaceRunStatus {
    pub run_id: String,
    pub status: String,
    pub updated_at: String,
}

pub struct WorkspaceRunStatusDao;

impl WorkspaceRunStatusDao {
    pub fn new() -> Self {
        Self
    }

    /// Upserts the run status for a workspace run.
    pub fn upsert(
        &self,
        conn: &Connection,
        run_id: &str,
        status: &str,
    ) -> Result<()> {
        conn.execute(
            "INSERT INTO workspace_run_status (run_id, status, updated_at)
             VALUES (?1, ?2, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
             ON CONFLICT(run_id) DO UPDATE SET
                status = excluded.status,
                updated_at = excluded.updated_at",
            rusqlite::params![run_id, status],
        )
        .map_err(|e| crate::util::error::AppError::Storage(format!("upsert workspace_run_status: {e}")))?;
        Ok(())
    }

    /// Gets the run status for a workspace run.
    pub fn get(&self, conn: &Connection, run_id: &str) -> Result<Option<WorkspaceRunStatus>> {
        conn.query_row(
            "SELECT run_id, status, updated_at
             FROM workspace_run_status WHERE run_id = ?1",
            [run_id],
            |row| {
                Ok(WorkspaceRunStatus {
                    run_id: row.get(0)?,
                    status: row.get(1)?,
                    updated_at: row.get(2)?,
                })
            },
        )
        .optional()
        .map_err(|e| crate::util::error::AppError::Storage(format!("get workspace_run_status: {e}")))
    }
}
