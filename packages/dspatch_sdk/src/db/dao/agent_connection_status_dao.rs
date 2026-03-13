// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! DAO for the `agent_connection_status` ephemeral table.

use rusqlite::Connection;

use crate::db::optional_ext::OptionalExt;
use crate::util::result::Result;

/// Row model for `agent_connection_status`.
#[derive(Debug, Clone)]
pub struct AgentConnectionStatus {
    pub agent_key: String,
    pub run_id: String,
    pub connected: bool,
    pub updated_at: String,
}

pub struct AgentConnectionStatusDao;

impl AgentConnectionStatusDao {
    pub fn new() -> Self {
        Self
    }

    /// Upserts the connection status for an agent in a run.
    pub fn upsert(
        &self,
        conn: &Connection,
        agent_key: &str,
        run_id: &str,
        connected: bool,
    ) -> Result<()> {
        conn.execute(
            "INSERT INTO agent_connection_status (agent_key, run_id, connected, updated_at)
             VALUES (?1, ?2, ?3, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
             ON CONFLICT(agent_key, run_id) DO UPDATE SET
                connected = excluded.connected,
                updated_at = excluded.updated_at",
            rusqlite::params![agent_key, run_id, connected as i32],
        )
        .map_err(|e| crate::util::error::AppError::Storage(format!("upsert agent_connection_status: {e}")))?;
        Ok(())
    }

    /// Gets the connection status for a specific agent in a run.
    pub fn get(
        &self,
        conn: &Connection,
        agent_key: &str,
        run_id: &str,
    ) -> Result<Option<AgentConnectionStatus>> {
        conn.query_row(
            "SELECT agent_key, run_id, connected, updated_at
             FROM agent_connection_status WHERE agent_key = ?1 AND run_id = ?2",
            rusqlite::params![agent_key, run_id],
            |row| {
                let connected_int: i32 = row.get(2)?;
                Ok(AgentConnectionStatus {
                    agent_key: row.get(0)?,
                    run_id: row.get(1)?,
                    connected: connected_int != 0,
                    updated_at: row.get(3)?,
                })
            },
        )
        .optional()
        .map_err(|e| crate::util::error::AppError::Storage(format!("get agent_connection_status: {e}")))
    }

    /// Disconnects all agents for a given run (used during workspace stop).
    pub fn disconnect_all_for_run(&self, conn: &Connection, run_id: &str) -> Result<()> {
        conn.execute(
            "UPDATE agent_connection_status SET connected = 0,
             updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
             WHERE run_id = ?1",
            [run_id],
        )
        .map_err(|e| crate::util::error::AppError::Storage(format!("disconnect_all agent_connection_status: {e}")))?;
        Ok(())
    }
}
