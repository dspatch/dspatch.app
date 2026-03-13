// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! DAO for the `agent_instance_states` ephemeral table.

use rusqlite::Connection;

use crate::db::optional_ext::OptionalExt;
use crate::util::result::Result;

/// Row model for `agent_instance_states`.
#[derive(Debug, Clone)]
pub struct AgentInstanceState {
    pub instance_id: String,
    pub run_id: String,
    pub agent_key: String,
    pub state: String,
    pub updated_at: String,
}

pub struct AgentInstanceStateDao;

impl AgentInstanceStateDao {
    pub fn new() -> Self {
        Self
    }

    /// Upserts an agent instance state. Inserts if the instance_id doesn't exist,
    /// updates the state and updated_at if it does.
    pub fn upsert(
        &self,
        conn: &Connection,
        instance_id: &str,
        run_id: &str,
        agent_key: &str,
        state: &str,
    ) -> Result<()> {
        conn.execute(
            "INSERT INTO agent_instance_states (instance_id, run_id, agent_key, state, updated_at)
             VALUES (?1, ?2, ?3, ?4, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
             ON CONFLICT(instance_id) DO UPDATE SET
                state = excluded.state,
                updated_at = excluded.updated_at",
            rusqlite::params![instance_id, run_id, agent_key, state],
        )
        .map_err(|e| crate::util::error::AppError::Storage(format!("upsert agent_instance_states: {e}")))?;
        Ok(())
    }

    /// Gets the state for a specific instance.
    pub fn get(&self, conn: &Connection, instance_id: &str) -> Result<Option<AgentInstanceState>> {
        conn.query_row(
            "SELECT instance_id, run_id, agent_key, state, updated_at
             FROM agent_instance_states WHERE instance_id = ?1",
            [instance_id],
            |row| {
                Ok(AgentInstanceState {
                    instance_id: row.get(0)?,
                    run_id: row.get(1)?,
                    agent_key: row.get(2)?,
                    state: row.get(3)?,
                    updated_at: row.get(4)?,
                })
            },
        )
        .optional()
        .map_err(|e| crate::util::error::AppError::Storage(format!("get agent_instance_states: {e}")))
    }

    /// Deletes all instance states for a given run (used during workspace stop/cleanup).
    pub fn delete_for_run(&self, conn: &Connection, run_id: &str) -> Result<()> {
        conn.execute(
            "DELETE FROM agent_instance_states WHERE run_id = ?1",
            [run_id],
        )
        .map_err(|e| crate::util::error::AppError::Storage(format!("delete agent_instance_states: {e}")))?;
        Ok(())
    }
}
