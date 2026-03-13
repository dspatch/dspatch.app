// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access object for the `agent_templates` table (lightweight config presets).

use std::pin::Pin;
use std::sync::Arc;

use futures::Stream;

use crate::db::optional_ext::OptionalExt;
use crate::db::reactive::watch_query;
use crate::db::Database;
use crate::domain::models::AgentTemplate;
use crate::util::error::AppError;
use crate::util::result::Result;

use super::{format_datetime, parse_datetime};

/// Provides typed CRUD and reactive watch operations on the `agent_templates`
/// table (lightweight config presets, NOT the old agent_providers table).
pub struct AgentTemplateDao {
    db: Arc<Database>,
}

impl AgentTemplateDao {
    /// Creates a new DAO backed by the given database.
    pub fn new(db: Arc<Database>) -> Self {
        Self { db }
    }

    /// Returns a stream of all agent templates, ordered by `updated_at` descending.
    pub fn watch_agent_templates(
        &self,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentTemplate>>> + Send>> {
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_templates"],
            |conn| {
                let mut stmt = conn
                    .prepare(SELECT_ALL_SQL)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map([], |row| Ok(row_to_agent_template(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Returns a stream that emits the agent template with `id`, or `None`.
    pub fn watch_agent_template(
        &self,
        id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Option<AgentTemplate>>> + Send>> {
        let id = id.to_string();
        let stream = watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_templates"],
            move |conn| {
                let mut stmt = conn
                    .prepare(&format!("{SELECT_COLS} FROM agent_templates WHERE id = ?1"))
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let result = stmt
                    .query_row(rusqlite::params![id], |row| {
                        Ok(row_to_agent_template(row))
                    })
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

    /// Returns the agent template with the given `id`. Errors if not found.
    pub fn get_agent_template(&self, id: &str) -> Result<AgentTemplate> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{SELECT_COLS} FROM agent_templates WHERE id = ?1"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![id], |row| {
                Ok(row_to_agent_template(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => r,
            None => Err(AppError::NotFound(format!(
                "Agent template not found: {id}"
            ))),
        }
    }

    /// Returns the agent template with the given `name`, or `None`.
    pub fn get_agent_template_by_name(&self, name: &str) -> Result<Option<AgentTemplate>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{SELECT_COLS} FROM agent_templates WHERE name = ?1"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![name], |row| {
                Ok(row_to_agent_template(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Inserts a new agent template.
    pub fn insert_agent_template(&self, template: &AgentTemplate) -> Result<()> {
        let created_at = format_datetime(&template.created_at);
        let updated_at = format_datetime(&template.updated_at);

        self.db.execute(
            "INSERT INTO agent_templates (id, name, source_uri, file_path, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            &[
                &template.id as &dyn rusqlite::types::ToSql,
                &template.name,
                &template.source_uri,
                &template.file_path,
                &created_at,
                &updated_at,
            ],
        )?;
        Ok(())
    }

    /// Updates the name and source_uri of an existing agent template.
    pub fn update_agent_template(
        &self,
        id: &str,
        name: &str,
        source_uri: &str,
    ) -> Result<()> {
        let now = format_datetime(&chrono::Utc::now().naive_utc());
        self.db.execute(
            "UPDATE agent_templates SET name = ?1, source_uri = ?2, updated_at = ?3 WHERE id = ?4",
            &[
                &name as &dyn rusqlite::types::ToSql,
                &source_uri,
                &now,
                &id,
            ],
        )?;
        Ok(())
    }

    /// Deletes the agent template with the given `id`.
    pub fn delete_agent_template(&self, id: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM agent_templates WHERE id = ?1",
            &[&id as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }
}

const SELECT_COLS: &str =
    "SELECT id, name, source_uri, file_path, created_at, updated_at";

const SELECT_ALL_SQL: &str =
    "SELECT id, name, source_uri, file_path, created_at, updated_at FROM agent_templates ORDER BY updated_at DESC";

fn row_to_agent_template(row: &rusqlite::Row<'_>) -> Result<AgentTemplate> {
    let created_at_str: String = row
        .get(4)
        .map_err(|e| AppError::Storage(format!("Failed to read created_at: {e}")))?;
    let updated_at_str: String = row
        .get(5)
        .map_err(|e| AppError::Storage(format!("Failed to read updated_at: {e}")))?;

    Ok(AgentTemplate {
        id: row
            .get(0)
            .map_err(|e| AppError::Storage(format!("Failed to read id: {e}")))?,
        name: row
            .get(1)
            .map_err(|e| AppError::Storage(format!("Failed to read name: {e}")))?,
        source_uri: row
            .get(2)
            .map_err(|e| AppError::Storage(format!("Failed to read source_uri: {e}")))?,
        file_path: row
            .get(3)
            .map_err(|e| AppError::Storage(format!("Failed to read file_path: {e}")))?,
        created_at: parse_datetime(&created_at_str)?,
        updated_at: parse_datetime(&updated_at_str)?,
    })
}
