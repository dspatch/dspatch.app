// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access object for workspaces, workspace runs, and all child tables
//! (agents, messages, activity, logs, usage, files, inquiries, instance
//! results).

use std::pin::Pin;
use std::sync::Arc;

use chrono::NaiveDateTime;
use futures::Stream;

use crate::db::col::col;
use crate::db::optional_ext::OptionalExt;
use crate::db::reactive::watch_query;
use crate::db::Database;
use crate::domain::enums::{AgentState, InquiryPriority, InquiryStatus, LogLevel, LogSource};
use crate::domain::models::{
    AgentActivity, AgentFile, AgentLog, AgentMessage, AgentUsage, InquiryWithWorkspace, Workspace,
    WorkspaceAgent, WorkspaceInquiry, WorkspaceRun,
};
use crate::util::error::AppError;
use crate::util::result::Result;

use super::{format_datetime, parse_datetime};

/// Provides typed CRUD and reactive watch operations on the workspace table
/// hierarchy: workspaces, runs, agents, messages, activity, logs, usage,
/// files, inquiries, and instance results.
pub struct WorkspaceDao {
    db: Arc<Database>,
}

impl WorkspaceDao {
    /// Creates a new DAO backed by the given database.
    pub fn new(db: Arc<Database>) -> Self {
        Self { db }
    }

    /// Returns the underlying database handle.
    pub fn db(&self) -> &Arc<Database> {
        &self.db
    }

    // ── Workspace CRUD ──────────────────────────────────────────────

    /// Watches all workspaces, ordered by `updated_at` descending.
    pub fn watch_workspaces(
        &self,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<Workspace>>> + Send>> {
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspaces"],
            |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, name, project_path, created_at, updated_at FROM workspaces ORDER BY updated_at DESC")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map([], |row| Ok(row_to_workspace(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Watches a single workspace by `id`.
    pub fn watch_workspace(
        &self,
        id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Option<Workspace>>> + Send>> {
        let id = id.to_string();
        let stream = watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspaces"],
            move |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, name, project_path, created_at, updated_at FROM workspaces WHERE id = ?1")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let result = stmt
                    .query_row(rusqlite::params![id], |row| Ok(row_to_workspace(row)))
                    .optional()
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
                match result {
                    Some(r) => Ok(vec![Some(r?)]),
                    None => Ok(vec![None]),
                }
            },
        );
        use futures::StreamExt;
        Box::pin(stream.map(|r| r.map(|v| v.into_iter().next().flatten())))
    }

    /// Returns all workspaces, ordered by `updated_at` descending.
    pub fn get_all_workspaces(&self) -> Result<Vec<Workspace>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, name, project_path, created_at, updated_at FROM workspaces ORDER BY updated_at DESC")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let rows = stmt
            .query_map([], |row| Ok(row_to_workspace(row)))
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
        rows.into_iter().collect::<Result<Vec<_>>>()
    }

    /// Returns the workspace with the given `id`. Errors if not found.
    pub fn get_workspace(&self, id: &str) -> Result<Workspace> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, name, project_path, created_at, updated_at FROM workspaces WHERE id = ?1")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![id], |row| Ok(row_to_workspace(row)))
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => r,
            None => Err(AppError::NotFound(format!("Workspace not found: {id}"))),
        }
    }

    /// Inserts a new workspace.
    pub fn insert_workspace(&self, workspace: &Workspace) -> Result<()> {
        let created_at = format_datetime(&workspace.created_at);
        let updated_at = format_datetime(&workspace.updated_at);
        self.db.execute(
            "INSERT INTO workspaces (id, name, project_path, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5)",
            &[
                &workspace.id as &dyn rusqlite::types::ToSql,
                &workspace.name,
                &workspace.project_path,
                &created_at,
                &updated_at,
            ],
        )?;
        Ok(())
    }

    /// Updates workspace name and/or project_path.
    pub fn update_workspace(
        &self,
        id: &str,
        name: Option<&str>,
        project_path: Option<&str>,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        let name = name.map(|s| s.to_string());
        let project_path = project_path.map(|s| s.to_string());
        maybe_set!(sets, params, idx, name, "name");
        maybe_set!(sets, params, idx, project_path, "project_path");
        if sets.is_empty() {
            return Ok(());
        }

        let now = chrono::Utc::now().naive_utc();
        sets.push(format!("updated_at = ?{idx}"));
        params.push(Box::new(format_datetime(&now)));
        idx += 1;

        let sql = format!(
            "UPDATE workspaces SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        self.db.execute(&sql, &param_refs)?;
        Ok(())
    }

    /// Deletes a workspace and cascades to all runs and child data.
    pub fn delete_workspace(&self, id: &str) -> Result<()> {
        // Find all runs for this workspace.
        let run_ids: Vec<String> = {
            let conn = self.db.conn();
            let mut stmt = conn
                .prepare("SELECT id FROM workspace_runs WHERE workspace_id = ?1")
                .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
            let ids = stmt
                .query_map(rusqlite::params![id], |row| row.get(0))
                .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                .collect::<std::result::Result<Vec<_>, _>>()
                .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
            ids
        };
        for run_id in &run_ids {
            self.delete_workspace_run(run_id)?;
        }
        self.db.execute(
            "DELETE FROM workspaces WHERE id = ?1",
            &[&id as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }

    // ── Workspace Run CRUD ──────────────────────────────────────────

    /// Watches all runs for a workspace, ordered by `started_at` descending.
    pub fn watch_workspace_runs(
        &self,
        workspace_id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<WorkspaceRun>>> + Send>> {
        let workspace_id = workspace_id.to_string();
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_runs"],
            move |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, workspace_id, run_number, status, container_id, server_port, api_key, started_at, stopped_at FROM workspace_runs WHERE workspace_id = ?1 ORDER BY started_at DESC")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params![workspace_id], |row| Ok(row_to_workspace_run(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Gets the active run (starting or running) for a workspace.
    pub fn get_active_run(&self, workspace_id: &str) -> Result<Option<WorkspaceRun>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, workspace_id, run_number, status, container_id, server_port, api_key, started_at, stopped_at FROM workspace_runs WHERE workspace_id = ?1 AND status IN ('starting', 'running')")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![workspace_id], |row| {
                Ok(row_to_workspace_run(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Returns the next run number for a workspace.
    pub fn next_run_number(&self, workspace_id: &str) -> Result<i64> {
        let conn = self.db.conn();
        let max: Option<i64> = conn
            .query_row(
                "SELECT MAX(run_number) FROM workspace_runs WHERE workspace_id = ?1",
                rusqlite::params![workspace_id],
                |row| row.get(0),
            )
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        Ok(max.unwrap_or(0) + 1)
    }

    /// Inserts a new workspace run.
    pub fn insert_workspace_run(&self, run: &WorkspaceRun) -> Result<()> {
        let started_at = format_datetime(&run.started_at);
        let stopped_at = run.stopped_at.as_ref().map(format_datetime);
        self.db.execute(
            "INSERT INTO workspace_runs (id, workspace_id, run_number, status, container_id, server_port, api_key, started_at, stopped_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            &[
                &run.id as &dyn rusqlite::types::ToSql,
                &run.workspace_id,
                &run.run_number as &dyn rusqlite::types::ToSql,
                &run.status,
                &run.container_id as &dyn rusqlite::types::ToSql,
                &run.server_port.map(|p| p as i64) as &dyn rusqlite::types::ToSql,
                &run.api_key as &dyn rusqlite::types::ToSql,
                &started_at,
                &stopped_at as &dyn rusqlite::types::ToSql,
            ],
        )?;
        Ok(())
    }

    /// Updates run status, optionally setting `stopped_at`.
    pub fn update_run_status(
        &self,
        run_id: &str,
        status: &str,
        stopped_at: Option<&NaiveDateTime>,
    ) -> Result<()> {
        match stopped_at {
            Some(dt) => {
                let stopped_str = format_datetime(dt);
                self.db.execute(
                    "UPDATE workspace_runs SET status = ?1, stopped_at = ?2 WHERE id = ?3",
                    &[
                        &status as &dyn rusqlite::types::ToSql,
                        &stopped_str as &dyn rusqlite::types::ToSql,
                        &run_id,
                    ],
                )?;
            }
            None => {
                self.db.execute(
                    "UPDATE workspace_runs SET status = ?1 WHERE id = ?2",
                    &[&status as &dyn rusqlite::types::ToSql, &run_id],
                )?;
            }
        }
        Ok(())
    }

    /// Updates run deployment info (container_id, server_port, api_key).
    pub fn update_run_deployment(
        &self,
        run_id: &str,
        container_id: Option<&str>,
        server_port: Option<u16>,
        api_key: Option<&str>,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        let container_id = container_id.map(|s| s.to_string());
        let api_key = api_key.map(|s| s.to_string());
        maybe_set!(sets, params, idx, container_id, "container_id");
        if let Some(val) = server_port {
            sets.push(format!("server_port = ?{idx}"));
            params.push(Box::new(val as i64));
            idx += 1;
        }
        maybe_set!(sets, params, idx, api_key, "api_key");
        if sets.is_empty() {
            return Ok(());
        }

        let sql = format!(
            "UPDATE workspace_runs SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(run_id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        self.db.execute(&sql, &param_refs)?;
        Ok(())
    }

    /// Deletes a run and all its child data (cascade).
    pub fn delete_workspace_run(&self, run_id: &str) -> Result<()> {
        let p: &[&dyn rusqlite::types::ToSql] = &[&run_id];
        self.db.execute("DELETE FROM workspace_agents WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_messages WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_activity_events WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_logs WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_usage_records WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_files WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM workspace_inquiries WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM instance_results WHERE run_id = ?1", p)?;
        self.db.execute("DELETE FROM workspace_runs WHERE id = ?1", p)?;
        Ok(())
    }

    /// Deletes all non-active runs for a workspace.
    pub fn delete_non_active_runs(&self, workspace_id: &str) -> Result<()> {
        let run_ids: Vec<String> = {
            let conn = self.db.conn();
            let mut stmt = conn
                .prepare("SELECT id FROM workspace_runs WHERE workspace_id = ?1 AND status NOT IN ('starting', 'running')")
                .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
            let ids = stmt
                .query_map(rusqlite::params![workspace_id], |row| row.get(0))
                .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                .collect::<std::result::Result<Vec<_>, _>>()
                .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
            ids
        };
        for run_id in &run_ids {
            self.delete_workspace_run(run_id)?;
        }
        Ok(())
    }

    // ── Workspace Agent CRUD ────────────────────────────────────────

    /// Watches all agents for a run, ordered by agent key.
    pub fn watch_workspace_agents(
        &self,
        run_id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<WorkspaceAgent>>> + Send>> {
        let run_id = run_id.to_string();
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_agents"],
            move |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, run_id, agent_key, instance_id, display_name, chain_json, status, created_at, updated_at FROM workspace_agents WHERE run_id = ?1 ORDER BY agent_key ASC")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params![run_id], |row| Ok(row_to_workspace_agent(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Finds a workspace agent by run and instance ID.
    pub fn find_workspace_agent_by_instance_id(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Result<Option<WorkspaceAgent>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, run_id, agent_key, instance_id, display_name, chain_json, status, created_at, updated_at FROM workspace_agents WHERE run_id = ?1 AND instance_id = ?2")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![run_id, instance_id], |row| {
                Ok(row_to_workspace_agent(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Gets all agents for a run.
    pub fn get_workspace_agents(&self, run_id: &str) -> Result<Vec<WorkspaceAgent>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, run_id, agent_key, instance_id, display_name, chain_json, status, created_at, updated_at FROM workspace_agents WHERE run_id = ?1")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let rows = stmt
            .query_map(rusqlite::params![run_id], |row| {
                Ok(row_to_workspace_agent(row))
            })
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
        rows.into_iter().collect::<Result<Vec<_>>>()
    }

    /// Updates the chain JSON for a workspace agent by `instance_id`.
    pub fn update_agent_chain(&self, instance_id: &str, chain_json: &str) -> Result<()> {
        self.db.execute(
            "UPDATE workspace_agents SET chain_json = ?1 WHERE instance_id = ?2",
            &[
                &chain_json as &dyn rusqlite::types::ToSql,
                &instance_id,
            ],
        )?;
        Ok(())
    }

    /// Inserts a new workspace agent.
    pub fn insert_workspace_agent(&self, agent: &WorkspaceAgent) -> Result<()> {
        let status_str = agent_state_to_db(&agent.status);
        let created_at = format_datetime(&agent.created_at);
        let updated_at = format_datetime(&agent.updated_at);
        self.db.execute(
            "INSERT INTO workspace_agents (id, run_id, agent_key, instance_id, display_name, chain_json, status, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            &[
                &agent.id as &dyn rusqlite::types::ToSql,
                &agent.run_id,
                &agent.agent_key,
                &agent.instance_id,
                &agent.display_name,
                &agent.chain_json,
                &status_str,
                &created_at,
                &updated_at,
            ],
        )?;
        Ok(())
    }

    /// Updates the workspace agent with `id`.
    pub fn update_workspace_agent(
        &self,
        id: &str,
        display_name: Option<&str>,
        status: Option<&AgentState>,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        let display_name = display_name.map(|s| s.to_string());
        maybe_set!(sets, params, idx, display_name, "display_name");
        if let Some(val) = status {
            sets.push(format!("status = ?{idx}"));
            params.push(Box::new(agent_state_to_db(val)));
            idx += 1;
        }
        if sets.is_empty() {
            return Ok(());
        }

        let now = chrono::Utc::now().naive_utc();
        sets.push(format!("updated_at = ?{idx}"));
        params.push(Box::new(format_datetime(&now)));
        idx += 1;

        let sql = format!(
            "UPDATE workspace_agents SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        self.db.execute(&sql, &param_refs)?;
        Ok(())
    }

    /// Updates the status of a workspace agent by `instance_id`.
    pub fn update_agent_status(&self, instance_id: &str, status: &AgentState) -> Result<()> {
        let status_str = agent_state_to_db(status);
        let now = format_datetime(&chrono::Utc::now().naive_utc());
        self.db.execute(
            "UPDATE workspace_agents SET status = ?1, updated_at = ?2 WHERE instance_id = ?3",
            &[
                &status_str as &dyn rusqlite::types::ToSql,
                &now,
                &instance_id,
            ],
        )?;
        Ok(())
    }

    /// Updates the chain_json for a workspace agent by `instance_id`.
    pub fn update_agent_chain_json(&self, instance_id: &str, chain_json: &str) -> Result<()> {
        let now = format_datetime(&chrono::Utc::now().naive_utc());
        self.db.execute(
            "UPDATE workspace_agents SET chain_json = ?1, updated_at = ?2 WHERE instance_id = ?3",
            &[
                &chain_json as &dyn rusqlite::types::ToSql,
                &now,
                &instance_id,
            ],
        )?;
        Ok(())
    }

    /// Deletes a workspace agent row by `instance_id` (without cascading).
    pub fn delete_workspace_agent_by_instance_id(&self, instance_id: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM workspace_agents WHERE instance_id = ?1",
            &[&instance_id as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }

    /// Deletes an agent instance and all its child data.
    pub fn delete_agent_instance(&self, instance_id: &str) -> Result<()> {
        let p: &[&dyn rusqlite::types::ToSql] = &[&instance_id];
        self.db.execute("DELETE FROM agent_messages WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_activity_events WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_logs WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_usage_records WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM agent_files WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM workspace_inquiries WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM instance_results WHERE instance_id = ?1", p)?;
        self.db.execute("DELETE FROM workspace_agents WHERE instance_id = ?1", p)?;
        Ok(())
    }

    // ── Agent Messages ──────────────────────────────────────────────

    /// Inserts a new agent message.
    pub fn insert_agent_message(&self, message: &AgentMessage) -> Result<()> {
        let created_at = format_datetime(&message.created_at);
        self.db.execute(
            "INSERT INTO agent_messages (id, run_id, role, content, model, input_tokens, output_tokens, instance_id, turn_id, sender_name, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            &[
                &message.id as &dyn rusqlite::types::ToSql,
                &message.run_id,
                &message.role,
                &message.content,
                &message.model as &dyn rusqlite::types::ToSql,
                &message.input_tokens as &dyn rusqlite::types::ToSql,
                &message.output_tokens as &dyn rusqlite::types::ToSql,
                &message.instance_id,
                &message.turn_id as &dyn rusqlite::types::ToSql,
                &message.sender_name as &dyn rusqlite::types::ToSql,
                &created_at,
            ],
        )?;
        Ok(())
    }

    /// Updates an agent message by id.
    pub fn update_agent_message(
        &self,
        id: &str,
        content: Option<&str>,
        model: Option<&str>,
        input_tokens: Option<i64>,
        output_tokens: Option<i64>,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        let content = content.map(|s| s.to_string());
        let model = model.map(|s| s.to_string());
        maybe_set!(sets, params, idx, content, "content");
        maybe_set!(sets, params, idx, model, "model");
        if let Some(val) = input_tokens {
            sets.push(format!("input_tokens = ?{idx}"));
            params.push(Box::new(val));
            idx += 1;
        }
        if let Some(val) = output_tokens {
            sets.push(format!("output_tokens = ?{idx}"));
            params.push(Box::new(val));
            idx += 1;
        }
        if sets.is_empty() {
            return Ok(());
        }

        let sql = format!(
            "UPDATE agent_messages SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        let rows_affected = self.db.execute(&sql, &param_refs)?;
        if rows_affected == 0 {
            return Err(AppError::Storage("No matching row to update".into()));
        }
        Ok(())
    }

    /// Appends `delta` to the content of an existing agent message.
    pub fn append_agent_message_content(&self, id: &str, delta: &str) -> Result<()> {
        let rows_affected = self.db.execute(
            "UPDATE agent_messages SET content = content || ?1 WHERE id = ?2",
            &[&delta as &dyn rusqlite::types::ToSql, &id],
        )?;
        if rows_affected == 0 {
            return Err(AppError::Storage("No matching row to append to".into()));
        }
        Ok(())
    }

    /// Watches messages for a specific agent instance in a run.
    pub fn watch_agent_messages(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentMessage>>> + Send>> {
        let run_id = run_id.to_string();
        let instance_id = instance_id.to_string();
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_messages"],
            move |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, run_id, role, content, model, input_tokens, output_tokens, instance_id, turn_id, sender_name, created_at FROM agent_messages WHERE run_id = ?1 AND instance_id = ?2 ORDER BY created_at ASC")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params![run_id, instance_id], |row| Ok(row_to_agent_message(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    // ── Agent Activity ──────────────────────────────────────────────

    /// Inserts a new agent activity event.
    pub fn insert_agent_activity(&self, activity: &AgentActivity) -> Result<()> {
        let timestamp = format_datetime(&activity.timestamp);
        self.db.execute(
            "INSERT INTO agent_activity_events (id, run_id, agent_key, instance_id, turn_id, event_type, data_json, content, timestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            &[
                &activity.id as &dyn rusqlite::types::ToSql,
                &activity.run_id,
                &activity.agent_key,
                &activity.instance_id,
                &activity.turn_id as &dyn rusqlite::types::ToSql,
                &activity.event_type,
                &activity.data_json as &dyn rusqlite::types::ToSql,
                &activity.content as &dyn rusqlite::types::ToSql,
                &timestamp,
            ],
        )?;
        Ok(())
    }

    /// Updates an agent activity by id.
    pub fn update_agent_activity(
        &self,
        id: &str,
        event_type: Option<&str>,
        data_json: Option<&str>,
        content: Option<&str>,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        let event_type = event_type.map(|s| s.to_string());
        let data_json = data_json.map(|s| s.to_string());
        let content = content.map(|s| s.to_string());
        maybe_set!(sets, params, idx, event_type, "event_type");
        maybe_set!(sets, params, idx, data_json, "data_json");
        maybe_set!(sets, params, idx, content, "content");
        if sets.is_empty() {
            return Ok(());
        }

        let sql = format!(
            "UPDATE agent_activity_events SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        let rows_affected = self.db.execute(&sql, &param_refs)?;
        if rows_affected == 0 {
            return Err(AppError::Storage("No matching activity to update".into()));
        }
        Ok(())
    }

    /// Appends `delta` to the content of an existing agent activity.
    pub fn append_agent_activity_content(&self, id: &str, delta: &str) -> Result<()> {
        let rows_affected = self.db.execute(
            "UPDATE agent_activity_events SET content = COALESCE(content, '') || ?1 WHERE id = ?2",
            &[&delta as &dyn rusqlite::types::ToSql, &id],
        )?;
        if rows_affected == 0 {
            return Err(AppError::Storage("No matching activity to append content to".into()));
        }
        Ok(())
    }

    /// Appends JSON `delta` to the data_json of an existing agent activity
    /// using SQLite's `json_patch`.
    pub fn append_agent_activity_data(&self, id: &str, delta_json: &str) -> Result<()> {
        let rows_affected = self.db.execute(
            "UPDATE agent_activity_events SET data_json = json_patch(COALESCE(data_json, '{}'), ?1) WHERE id = ?2",
            &[&delta_json as &dyn rusqlite::types::ToSql, &id],
        )?;
        if rows_affected == 0 {
            return Err(AppError::Storage("No matching activity to append data to".into()));
        }
        Ok(())
    }

    /// Watches activity events for a specific agent instance in a run.
    pub fn watch_agent_activity(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentActivity>>> + Send>> {
        let run_id = run_id.to_string();
        let instance_id = instance_id.to_string();
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_activity_events"],
            move |conn| {
                let mut stmt = conn
                    .prepare("SELECT id, run_id, agent_key, instance_id, turn_id, event_type, data_json, content, timestamp FROM agent_activity_events WHERE run_id = ?1 AND instance_id = ?2 ORDER BY timestamp DESC")
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params![run_id, instance_id], |row| Ok(row_to_agent_activity(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    // ── Agent Logs ──────────────────────────────────────────────────

    /// Inserts a new agent log.
    pub fn insert_agent_log(&self, log: &AgentLog) -> Result<()> {
        let timestamp = format_datetime(&log.timestamp);
        let level_str = log_level_to_db(&log.level);
        let source_str = log_source_to_db(&log.source);
        self.db.execute(
            "INSERT INTO agent_logs (id, run_id, agent_key, instance_id, turn_id, level, message, source, timestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            &[
                &log.id as &dyn rusqlite::types::ToSql,
                &log.run_id,
                &log.agent_key,
                &log.instance_id,
                &log.turn_id as &dyn rusqlite::types::ToSql,
                &level_str,
                &log.message,
                &source_str,
                &timestamp,
            ],
        )?;
        Ok(())
    }

    /// Watches logs for a run, optionally filtered by instance.
    pub fn watch_agent_logs(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentLog>>> + Send>> {
        let run_id = run_id.to_string();
        let instance_id = instance_id.map(|s| s.to_string());
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_logs"],
            move |conn| {
                let (sql, params_vec): (String, Vec<Box<dyn rusqlite::types::ToSql>>) =
                    if let Some(ref iid) = instance_id {
                        (
                            "SELECT id, run_id, agent_key, instance_id, turn_id, level, message, source, timestamp FROM agent_logs WHERE run_id = ?1 AND instance_id = ?2 ORDER BY timestamp ASC".to_string(),
                            vec![Box::new(run_id.clone()) as Box<dyn rusqlite::types::ToSql>, Box::new(iid.clone())],
                        )
                    } else {
                        (
                            "SELECT id, run_id, agent_key, instance_id, turn_id, level, message, source, timestamp FROM agent_logs WHERE run_id = ?1 ORDER BY timestamp ASC".to_string(),
                            vec![Box::new(run_id.clone()) as Box<dyn rusqlite::types::ToSql>],
                        )
                    };
                let param_refs: Vec<&dyn rusqlite::types::ToSql> =
                    params_vec.iter().map(|p| p.as_ref()).collect();
                let mut stmt = conn
                    .prepare(&sql)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params_from_iter(param_refs), |row| Ok(row_to_agent_log(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    // ── Agent Usage ─────────────────────────────────────────────────

    /// Inserts a new agent usage record.
    pub fn insert_agent_usage(&self, usage: &AgentUsage) -> Result<()> {
        let timestamp = format_datetime(&usage.timestamp);
        self.db.execute(
            "INSERT INTO agent_usage_records (id, run_id, agent_key, instance_id, turn_id, model, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, timestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)",
            &[
                &usage.id as &dyn rusqlite::types::ToSql,
                &usage.run_id,
                &usage.agent_key,
                &usage.instance_id,
                &usage.turn_id as &dyn rusqlite::types::ToSql,
                &usage.model,
                &usage.input_tokens as &dyn rusqlite::types::ToSql,
                &usage.output_tokens as &dyn rusqlite::types::ToSql,
                &usage.cache_read_tokens as &dyn rusqlite::types::ToSql,
                &usage.cache_write_tokens as &dyn rusqlite::types::ToSql,
                &usage.cost_usd as &dyn rusqlite::types::ToSql,
                &timestamp,
            ],
        )?;
        Ok(())
    }

    /// Watches usage records for a run, optionally filtered by instance.
    pub fn watch_agent_usage(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentUsage>>> + Send>> {
        let run_id = run_id.to_string();
        let instance_id = instance_id.map(|s| s.to_string());
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_usage_records"],
            move |conn| {
                let (sql, params_vec): (String, Vec<Box<dyn rusqlite::types::ToSql>>) =
                    if let Some(ref iid) = instance_id {
                        (
                            "SELECT id, run_id, agent_key, instance_id, turn_id, model, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, timestamp FROM agent_usage_records WHERE run_id = ?1 AND instance_id = ?2 ORDER BY timestamp DESC".to_string(),
                            vec![Box::new(run_id.clone()) as Box<dyn rusqlite::types::ToSql>, Box::new(iid.clone())],
                        )
                    } else {
                        (
                            "SELECT id, run_id, agent_key, instance_id, turn_id, model, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, timestamp FROM agent_usage_records WHERE run_id = ?1 ORDER BY timestamp DESC".to_string(),
                            vec![Box::new(run_id.clone()) as Box<dyn rusqlite::types::ToSql>],
                        )
                    };
                let param_refs: Vec<&dyn rusqlite::types::ToSql> =
                    params_vec.iter().map(|p| p.as_ref()).collect();
                let mut stmt = conn
                    .prepare(&sql)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params_from_iter(param_refs), |row| Ok(row_to_agent_usage(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    // ── Agent Files ─────────────────────────────────────────────────

    /// Inserts a new agent file operation record.
    pub fn insert_agent_file(&self, file: &AgentFile) -> Result<()> {
        let timestamp = format_datetime(&file.timestamp);
        self.db.execute(
            "INSERT INTO agent_files (id, run_id, agent_key, instance_id, turn_id, file_path, operation, timestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            &[
                &file.id as &dyn rusqlite::types::ToSql,
                &file.run_id,
                &file.agent_key,
                &file.instance_id,
                &file.turn_id as &dyn rusqlite::types::ToSql,
                &file.file_path,
                &file.operation,
                &timestamp,
            ],
        )?;
        Ok(())
    }

    /// Watches file operations for a run, optionally filtered by instance.
    pub fn watch_agent_files(
        &self,
        run_id: &str,
        instance_id: Option<&str>,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentFile>>> + Send>> {
        let run_id = run_id.to_string();
        let instance_id = instance_id.map(|s| s.to_string());
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_files"],
            move |conn| {
                let (sql, params_vec): (String, Vec<Box<dyn rusqlite::types::ToSql>>) =
                    if let Some(ref iid) = instance_id {
                        (
                            "SELECT id, run_id, agent_key, instance_id, turn_id, file_path, operation, timestamp FROM agent_files WHERE run_id = ?1 AND instance_id = ?2 ORDER BY timestamp DESC".to_string(),
                            vec![Box::new(run_id.clone()) as Box<dyn rusqlite::types::ToSql>, Box::new(iid.clone())],
                        )
                    } else {
                        (
                            "SELECT id, run_id, agent_key, instance_id, turn_id, file_path, operation, timestamp FROM agent_files WHERE run_id = ?1 ORDER BY timestamp DESC".to_string(),
                            vec![Box::new(run_id.clone()) as Box<dyn rusqlite::types::ToSql>],
                        )
                    };
                let param_refs: Vec<&dyn rusqlite::types::ToSql> =
                    params_vec.iter().map(|p| p.as_ref()).collect();
                let mut stmt = conn
                    .prepare(&sql)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params_from_iter(param_refs), |row| Ok(row_to_agent_file(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    // ── Workspace Inquiries ─────────────────────────────────────────

    /// Inserts a new workspace inquiry.
    pub fn insert_workspace_inquiry(&self, inquiry: &WorkspaceInquiry) -> Result<()> {
        let status_str = inquiry_status_to_db(&inquiry.status);
        let priority_str = inquiry_priority_to_db(&inquiry.priority);
        let created_at = format_datetime(&inquiry.created_at);
        let responded_at = inquiry.responded_at.as_ref().map(format_datetime);
        self.db.execute(
            "INSERT INTO workspace_inquiries (id, run_id, agent_key, instance_id, status, priority, content_markdown, attachments_json, suggestions_json, response_text, response_suggestion_index, responded_by_agent_key, forwarding_chain_json, created_at, responded_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15)",
            &[
                &inquiry.id as &dyn rusqlite::types::ToSql,
                &inquiry.run_id,
                &inquiry.agent_key,
                &inquiry.instance_id,
                &status_str,
                &priority_str,
                &inquiry.content_markdown,
                &inquiry.attachments_json as &dyn rusqlite::types::ToSql,
                &inquiry.suggestions_json as &dyn rusqlite::types::ToSql,
                &inquiry.response_text as &dyn rusqlite::types::ToSql,
                &inquiry.response_suggestion_index as &dyn rusqlite::types::ToSql,
                &inquiry.responded_by_agent_key as &dyn rusqlite::types::ToSql,
                &inquiry.forwarding_chain_json as &dyn rusqlite::types::ToSql,
                &created_at,
                &responded_at as &dyn rusqlite::types::ToSql,
            ],
        )?;
        Ok(())
    }

    /// Watches all inquiries for a run, most recent first.
    pub fn watch_workspace_inquiries(
        &self,
        run_id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<WorkspaceInquiry>>> + Send>> {
        let run_id = run_id.to_string();
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_inquiries"],
            move |conn| {
                let mut stmt = conn
                    .prepare(INQUIRY_SELECT_SQL_RUN)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map(rusqlite::params![run_id], |row| Ok(row_to_workspace_inquiry(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Returns all inquiries across all workspaces (from the latest run of
    /// each), most recent first. Each result includes the workspace name.
    pub fn get_all_inquiries(&self) -> Result<Vec<InquiryWithWorkspace>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(
                "SELECT i.id, i.run_id, i.agent_key, i.instance_id, i.status, i.priority, i.content_markdown, i.attachments_json, i.suggestions_json, i.response_text, i.response_suggestion_index, i.responded_by_agent_key, i.forwarding_chain_json, i.created_at, i.responded_at, w.name AS workspace_name, r.workspace_id
                 FROM workspace_inquiries i
                 INNER JOIN workspace_runs r ON i.run_id = r.id
                 INNER JOIN workspaces w ON r.workspace_id = w.id
                 WHERE r.id = (
                     SELECT r2.id FROM workspace_runs r2
                     WHERE r2.workspace_id = r.workspace_id
                     ORDER BY r2.run_number DESC
                     LIMIT 1
                 )
                 ORDER BY i.created_at DESC",
            )
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let rows = stmt
            .query_map([], |row| {
                Ok(row_to_inquiry_with_workspace(row))
            })
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
        rows.into_iter().collect::<Result<Vec<_>>>()
    }

    /// Returns a single workspace inquiry by `id`, or `None`.
    pub fn get_workspace_inquiry(&self, id: &str) -> Result<Option<WorkspaceInquiry>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{INQUIRY_SELECT_COLS} FROM workspace_inquiries WHERE id = ?1"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![id], |row| Ok(row_to_workspace_inquiry(row)))
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Watches all inquiries across all workspaces (from the latest run of
    /// each), most recent first. Each result includes the workspace name.
    pub fn watch_all_inquiries(
        &self,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<InquiryWithWorkspace>>> + Send>> {
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_inquiries", "workspace_runs", "workspaces"],
            |conn| {
                let mut stmt = conn
                    .prepare(
                        "SELECT i.id, i.run_id, i.agent_key, i.instance_id, i.status, i.priority, i.content_markdown, i.attachments_json, i.suggestions_json, i.response_text, i.response_suggestion_index, i.responded_by_agent_key, i.forwarding_chain_json, i.created_at, i.responded_at, w.name AS workspace_name, r.workspace_id
                         FROM workspace_inquiries i
                         INNER JOIN workspace_runs r ON i.run_id = r.id
                         INNER JOIN workspaces w ON r.workspace_id = w.id
                         WHERE r.id = (
                             SELECT r2.id FROM workspace_runs r2
                             WHERE r2.workspace_id = r.workspace_id
                             ORDER BY r2.run_number DESC
                             LIMIT 1
                         )
                         ORDER BY i.created_at DESC",
                    )
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map([], |row| {
                        Ok(row_to_inquiry_with_workspace(row))
                    })
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Watches a single workspace inquiry by `id`.
    pub fn watch_workspace_inquiry(
        &self,
        id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Option<WorkspaceInquiry>>> + Send>> {
        let id = id.to_string();
        let stream = watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_inquiries"],
            move |conn| {
                let mut stmt = conn
                    .prepare(&format!("{INQUIRY_SELECT_COLS} FROM workspace_inquiries WHERE id = ?1"))
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let result = stmt
                    .query_row(rusqlite::params![id], |row| Ok(row_to_workspace_inquiry(row)))
                    .optional()
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
                match result {
                    Some(r) => Ok(vec![Some(r?)]),
                    None => Ok(vec![None]),
                }
            },
        );
        use futures::StreamExt;
        Box::pin(stream.map(|r| r.map(|v| v.into_iter().next().flatten())))
    }

    /// Updates a workspace inquiry response.
    pub fn update_workspace_inquiry_response(
        &self,
        id: &str,
        response_text: Option<&str>,
        suggestion_index: Option<i64>,
        status: &InquiryStatus,
    ) -> Result<()> {
        let status_str = inquiry_status_to_db(status);
        let now = format_datetime(&chrono::Utc::now().naive_utc());
        self.db.execute(
            "UPDATE workspace_inquiries SET response_text = ?1, response_suggestion_index = ?2, status = ?3, responded_at = ?4 WHERE id = ?5",
            &[
                &response_text as &dyn rusqlite::types::ToSql,
                &suggestion_index as &dyn rusqlite::types::ToSql,
                &status_str as &dyn rusqlite::types::ToSql,
                &now,
                &id,
            ],
        )?;
        Ok(())
    }

    /// Gets the pending inquiry for a specific agent instance, if any.
    pub fn get_pending_inquiry_for_agent(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Result<Option<WorkspaceInquiry>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{INQUIRY_SELECT_COLS} FROM workspace_inquiries WHERE run_id = ?1 AND instance_id = ?2 AND status = 'pending' ORDER BY created_at DESC LIMIT 1"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![run_id, instance_id], |row| {
                Ok(row_to_workspace_inquiry(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Gets responded inquiries for a specific agent.
    pub fn get_responded_inquiries_for_agent(
        &self,
        run_id: &str,
        instance_id: &str,
    ) -> Result<Vec<WorkspaceInquiry>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{INQUIRY_SELECT_COLS} FROM workspace_inquiries WHERE run_id = ?1 AND instance_id = ?2 AND status = 'responded' ORDER BY created_at ASC"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let rows = stmt
            .query_map(rusqlite::params![run_id, instance_id], |row| {
                Ok(row_to_workspace_inquiry(row))
            })
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
        rows.into_iter().collect::<Result<Vec<_>>>()
    }

    /// Watches the count of pending inquiries from the latest run of each
    /// workspace.
    pub fn watch_pending_inquiry_count(
        &self,
    ) -> Pin<Box<dyn Stream<Item = Result<i64>> + Send>> {
        let stream = watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_inquiries", "workspace_runs"],
            |conn| {
                let count: i64 = conn
                    .query_row(
                        "SELECT COUNT(*) FROM workspace_inquiries i
                         INNER JOIN workspace_runs r ON i.run_id = r.id
                         WHERE i.status = 'pending'
                           AND r.id = (
                               SELECT r2.id FROM workspace_runs r2
                               WHERE r2.workspace_id = r.workspace_id
                               ORDER BY r2.run_number DESC
                               LIMIT 1
                           )",
                        [],
                        |row| row.get(0),
                    )
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
                Ok(vec![count])
            },
        );
        use futures::StreamExt;
        Box::pin(stream.map(|r| r.map(|v| v.into_iter().next().unwrap_or(0))))
    }

    /// Updates just the status of a workspace inquiry.
    pub fn update_workspace_inquiry_status(
        &self,
        id: &str,
        status: &str,
    ) -> Result<()> {
        self.db.execute(
            "UPDATE workspace_inquiries SET status = ?1 WHERE id = ?2",
            &[&status as &dyn rusqlite::types::ToSql, &id],
        )?;
        Ok(())
    }

    /// Updates the forwarding chain JSON for a workspace inquiry.
    pub fn update_workspace_inquiry_forwarding_chain(
        &self,
        id: &str,
        chain_json: &str,
    ) -> Result<()> {
        self.db.execute(
            "UPDATE workspace_inquiries SET forwarding_chain_json = ?1 WHERE id = ?2",
            &[&chain_json as &dyn rusqlite::types::ToSql, &id],
        )?;
        Ok(())
    }

    // ── Turn-scoped queries ─────────────────────────────────────────

    /// Gets all messages for a specific instance and turn.
    pub fn get_messages_for_turn(
        &self,
        instance_id: &str,
        turn_id: &str,
    ) -> Result<Vec<AgentMessage>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, run_id, role, content, model, input_tokens, output_tokens, instance_id, turn_id, sender_name, created_at FROM agent_messages WHERE instance_id = ?1 AND turn_id = ?2 ORDER BY created_at ASC")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let rows = stmt
            .query_map(rusqlite::params![instance_id, turn_id], |row| {
                Ok(row_to_agent_message(row))
            })
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
        rows.into_iter().collect::<Result<Vec<_>>>()
    }

    /// Gets all activity events for a specific instance and turn.
    pub fn get_activities_for_turn(
        &self,
        instance_id: &str,
        turn_id: &str,
    ) -> Result<Vec<AgentActivity>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare("SELECT id, run_id, agent_key, instance_id, turn_id, event_type, data_json, content, timestamp FROM agent_activity_events WHERE instance_id = ?1 AND turn_id = ?2 ORDER BY timestamp ASC")
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let rows = stmt
            .query_map(rusqlite::params![instance_id, turn_id], |row| {
                Ok(row_to_agent_activity(row))
            })
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
            .collect::<std::result::Result<Vec<_>, _>>()
            .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
        rows.into_iter().collect::<Result<Vec<_>>>()
    }

    /// Inserts an instance result record.
    pub fn insert_instance_result(
        &self,
        id: &str,
        run_id: &str,
        agent_key: &str,
        instance_id: &str,
        turn_id: &str,
        request_id: Option<&str>,
    ) -> Result<()> {
        self.db.execute(
            "INSERT INTO instance_results (id, run_id, agent_key, instance_id, turn_id, request_id) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            &[
                &id as &dyn rusqlite::types::ToSql,
                &run_id,
                &agent_key,
                &instance_id,
                &turn_id,
                &request_id as &dyn rusqlite::types::ToSql,
            ],
        )?;
        Ok(())
    }
}

// ── Row-to-model conversion helpers ─────────────────────────────────

fn row_to_workspace(row: &rusqlite::Row<'_>) -> Result<Workspace> {
    let created_at_str: String = col(row, 3, "created_at")?;
    let updated_at_str: String = col(row, 4, "updated_at")?;
    Ok(Workspace {
        id: col(row, 0, "id")?,
        name: col(row, 1, "name")?,
        project_path: col(row, 2, "project_path")?,
        created_at: parse_datetime(&created_at_str)?,
        updated_at: parse_datetime(&updated_at_str)?,
    })
}

fn row_to_workspace_run(row: &rusqlite::Row<'_>) -> Result<WorkspaceRun> {
    let started_at_str: String = col(row, 7, "started_at")?;
    let stopped_at_str: Option<String> = col(row, 8, "stopped_at")?;
    let server_port: Option<i64> = col(row, 5, "server_port")?;
    Ok(WorkspaceRun {
        id: col(row, 0, "id")?,
        workspace_id: col(row, 1, "workspace_id")?,
        run_number: col(row, 2, "run_number")?,
        status: col(row, 3, "status")?,
        container_id: col(row, 4, "container_id")?,
        server_port: server_port.map(|p| p as u16),
        api_key: col(row, 6, "api_key")?,
        started_at: parse_datetime(&started_at_str)?,
        stopped_at: stopped_at_str.as_deref().map(parse_datetime).transpose()?,
    })
}

fn row_to_workspace_agent(row: &rusqlite::Row<'_>) -> Result<WorkspaceAgent> {
    let status_str: String = col(row, 6, "status")?;
    let status = AgentState::from_db(&status_str).unwrap_or(AgentState::Disconnected);
    let created_at_str: String = col(row, 7, "created_at")?;
    let updated_at_str: String = col(row, 8, "updated_at")?;
    Ok(WorkspaceAgent {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        agent_key: col(row, 2, "agent_key")?,
        instance_id: col(row, 3, "instance_id")?,
        display_name: col(row, 4, "display_name")?,
        chain_json: col(row, 5, "chain_json")?,
        status,
        created_at: parse_datetime(&created_at_str)?,
        updated_at: parse_datetime(&updated_at_str)?,
    })
}

fn row_to_agent_message(row: &rusqlite::Row<'_>) -> Result<AgentMessage> {
    let created_at_str: String = col(row, 10, "created_at")?;
    Ok(AgentMessage {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        role: col(row, 2, "role")?,
        content: col(row, 3, "content")?,
        model: col(row, 4, "model")?,
        input_tokens: col(row, 5, "input_tokens")?,
        output_tokens: col(row, 6, "output_tokens")?,
        instance_id: col(row, 7, "instance_id")?,
        turn_id: col(row, 8, "turn_id")?,
        sender_name: col(row, 9, "sender_name")?,
        created_at: parse_datetime(&created_at_str)?,
    })
}

fn row_to_agent_activity(row: &rusqlite::Row<'_>) -> Result<AgentActivity> {
    let timestamp_str: String = col(row, 8, "timestamp")?;
    Ok(AgentActivity {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        agent_key: col(row, 2, "agent_key")?,
        instance_id: col(row, 3, "instance_id")?,
        turn_id: col(row, 4, "turn_id")?,
        event_type: col(row, 5, "event_type")?,
        data_json: col(row, 6, "data_json")?,
        content: col(row, 7, "content")?,
        timestamp: parse_datetime(&timestamp_str)?,
    })
}

fn row_to_agent_log(row: &rusqlite::Row<'_>) -> Result<AgentLog> {
    let level_str: String = col(row, 5, "level")?;
    let source_str: String = col(row, 7, "source")?;
    let timestamp_str: String = col(row, 8, "timestamp")?;
    let level = LogLevel::try_from_name(&level_str)
        .ok_or_else(|| AppError::Storage(format!("Unknown log level: {level_str}")))?;
    let source = match source_str.as_str() {
        "agent" => LogSource::Agent,
        "engine" => LogSource::Engine,
        other => {
            return Err(AppError::Storage(format!("Unknown log source: {other}")))
        }
    };
    Ok(AgentLog {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        agent_key: col(row, 2, "agent_key")?,
        instance_id: col(row, 3, "instance_id")?,
        turn_id: col(row, 4, "turn_id")?,
        level,
        message: col(row, 6, "message")?,
        source,
        timestamp: parse_datetime(&timestamp_str)?,
    })
}

fn row_to_agent_usage(row: &rusqlite::Row<'_>) -> Result<AgentUsage> {
    let timestamp_str: String = col(row, 11, "timestamp")?;
    Ok(AgentUsage {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        agent_key: col(row, 2, "agent_key")?,
        instance_id: col(row, 3, "instance_id")?,
        turn_id: col(row, 4, "turn_id")?,
        model: col(row, 5, "model")?,
        input_tokens: col(row, 6, "input_tokens")?,
        output_tokens: col(row, 7, "output_tokens")?,
        cache_read_tokens: col(row, 8, "cache_read_tokens")?,
        cache_write_tokens: col(row, 9, "cache_write_tokens")?,
        cost_usd: col(row, 10, "cost_usd")?,
        timestamp: parse_datetime(&timestamp_str)?,
    })
}

fn row_to_agent_file(row: &rusqlite::Row<'_>) -> Result<AgentFile> {
    let timestamp_str: String = col(row, 7, "timestamp")?;
    Ok(AgentFile {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        agent_key: col(row, 2, "agent_key")?,
        instance_id: col(row, 3, "instance_id")?,
        turn_id: col(row, 4, "turn_id")?,
        file_path: col(row, 5, "file_path")?,
        operation: col(row, 6, "operation")?,
        timestamp: parse_datetime(&timestamp_str)?,
    })
}

const INQUIRY_SELECT_COLS: &str = "SELECT id, run_id, agent_key, instance_id, status, priority, content_markdown, attachments_json, suggestions_json, response_text, response_suggestion_index, responded_by_agent_key, forwarding_chain_json, created_at, responded_at";

const INQUIRY_SELECT_SQL_RUN: &str = "SELECT id, run_id, agent_key, instance_id, status, priority, content_markdown, attachments_json, suggestions_json, response_text, response_suggestion_index, responded_by_agent_key, forwarding_chain_json, created_at, responded_at FROM workspace_inquiries WHERE run_id = ?1 ORDER BY created_at DESC";

fn row_to_workspace_inquiry(row: &rusqlite::Row<'_>) -> Result<WorkspaceInquiry> {
    let status_str: String = col(row, 4, "status")?;
    let priority_str: String = col(row, 5, "priority")?;
    let created_at_str: String = col(row, 13, "created_at")?;
    let responded_at_str: Option<String> = col(row, 14, "responded_at")?;

    let status = match status_str.as_str() {
        "pending" => InquiryStatus::Pending,
        "responded" => InquiryStatus::Responded,
        "delivered" => InquiryStatus::Delivered,
        "expired" => InquiryStatus::Expired,
        other => return Err(AppError::Storage(format!("Unknown inquiry status: {other}"))),
    };
    let priority = match priority_str.as_str() {
        "normal" => InquiryPriority::Normal,
        "high" => InquiryPriority::High,
        "urgent" => InquiryPriority::Urgent,
        other => return Err(AppError::Storage(format!("Unknown inquiry priority: {other}"))),
    };

    Ok(WorkspaceInquiry {
        id: col(row, 0, "id")?,
        run_id: col(row, 1, "run_id")?,
        agent_key: col(row, 2, "agent_key")?,
        instance_id: col(row, 3, "instance_id")?,
        status,
        priority,
        content_markdown: col(row, 6, "content_markdown")?,
        attachments_json: col(row, 7, "attachments_json")?,
        suggestions_json: col(row, 8, "suggestions_json")?,
        response_text: col(row, 9, "response_text")?,
        response_suggestion_index: col(row, 10, "response_suggestion_index")?,
        responded_by_agent_key: col(row, 11, "responded_by_agent_key")?,
        forwarding_chain_json: col(row, 12, "forwarding_chain_json")?,
        created_at: parse_datetime(&created_at_str)?,
        responded_at: responded_at_str
            .as_deref()
            .map(parse_datetime)
            .transpose()?,
    })
}

fn row_to_inquiry_with_workspace(row: &rusqlite::Row<'_>) -> Result<InquiryWithWorkspace> {
    let inquiry = row_to_workspace_inquiry(row)?;
    let workspace_name: String = col(row, 15, "workspace_name")?;
    let workspace_id: String = col(row, 16, "workspace_id")?;
    Ok(InquiryWithWorkspace {
        inquiry,
        workspace_name,
        workspace_id,
    })
}

// ── Enum conversion helpers ─────────────────────────────────────────

fn agent_state_to_db(state: &AgentState) -> String {
    match state {
        AgentState::Idle => "idle".to_string(),
        AgentState::Generating => "generating".to_string(),
        AgentState::WaitingForAgent => "waitingForAgent".to_string(),
        AgentState::WaitingForInquiry => "waitingForInquiry".to_string(),
        AgentState::Disconnected => "disconnected".to_string(),
        AgentState::Completed => "completed".to_string(),
        AgentState::Failed => "failed".to_string(),
        AgentState::Crashed => "crashed".to_string(),
    }
}

fn inquiry_status_to_db(status: &InquiryStatus) -> String {
    match status {
        InquiryStatus::Pending => "pending".to_string(),
        InquiryStatus::Responded => "responded".to_string(),
        InquiryStatus::Delivered => "delivered".to_string(),
        InquiryStatus::Expired => "expired".to_string(),
    }
}

fn inquiry_priority_to_db(priority: &InquiryPriority) -> String {
    match priority {
        InquiryPriority::Normal => "normal".to_string(),
        InquiryPriority::High => "high".to_string(),
        InquiryPriority::Urgent => "urgent".to_string(),
    }
}

fn log_level_to_db(level: &LogLevel) -> String {
    match level {
        LogLevel::Debug => "debug".to_string(),
        LogLevel::Info => "info".to_string(),
        LogLevel::Warn => "warn".to_string(),
        LogLevel::Error => "error".to_string(),
    }
}

fn log_source_to_db(source: &LogSource) -> String {
    match source {
        LogSource::Agent => "agent".to_string(),
        LogSource::Engine => "engine".to_string(),
    }
}
