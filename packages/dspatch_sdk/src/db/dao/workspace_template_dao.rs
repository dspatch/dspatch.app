// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access object for the `workspace_templates` table.

use std::pin::Pin;
use std::sync::Arc;

use futures::Stream;

use crate::db::reactive::watch_query;
use crate::db::Database;
use crate::domain::models::WorkspaceTemplate;
use crate::util::error::AppError;
use crate::util::result::Result;

use super::{format_datetime, parse_datetime};

/// Provides typed CRUD and reactive watch operations on the
/// `workspace_templates` table.
pub struct WorkspaceTemplateDao {
    db: Arc<Database>,
}

impl WorkspaceTemplateDao {
    /// Creates a new DAO backed by the given database.
    pub fn new(db: Arc<Database>) -> Self {
        Self { db }
    }

    /// Returns a stream of all workspace templates, ordered by `updated_at`
    /// descending.
    pub fn watch_workspace_templates(
        &self,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<WorkspaceTemplate>>> + Send>> {
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["workspace_templates"],
            |conn| {
                let mut stmt = conn
                    .prepare(SELECT_ALL_SQL)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map([], |row| Ok(row_to_workspace_template(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Returns the workspace template with the given hub `slug`, or `None`.
    pub fn get_by_hub_slug(&self, slug: &str) -> Result<Option<WorkspaceTemplate>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!(
                "{SELECT_COLS} FROM workspace_templates WHERE hub_slug = ?1"
            ))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![slug], |row| {
                Ok(row_to_workspace_template(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Inserts a new workspace template.
    pub fn insert_workspace_template(&self, template: &WorkspaceTemplate) -> Result<()> {
        let hub_tags_json = serde_json::to_string(&template.hub_tags)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
        let agent_refs_json = serde_json::to_string(&template.agent_refs)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
        let created_at = format_datetime(&template.created_at);
        let updated_at = format_datetime(&template.updated_at);

        self.db.execute(
            "INSERT INTO workspace_templates (id, name, description, hub_slug, hub_author, hub_category, hub_tags_json, hub_version, config_json, agent_refs_json, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)",
            &[
                &template.id as &dyn rusqlite::types::ToSql,
                &template.name,
                &template.description as &dyn rusqlite::types::ToSql,
                &template.hub_slug,
                &template.hub_author,
                &template.hub_category as &dyn rusqlite::types::ToSql,
                &hub_tags_json,
                &template.hub_version as &dyn rusqlite::types::ToSql,
                &template.config_yaml,
                &agent_refs_json,
                &created_at,
                &updated_at,
            ],
        )?;
        Ok(())
    }

    /// Partially updates the workspace template with `id`.
    pub fn update_workspace_template(
        &self,
        id: &str,
        name: Option<&str>,
        description: Option<&str>,
        hub_category: Option<&str>,
        hub_tags: Option<&[String]>,
        hub_version: Option<i64>,
        config_yaml: Option<&str>,
        agent_refs: Option<&[String]>,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        if let Some(val) = name {
            sets.push(format!("name = ?{idx}"));
            params.push(Box::new(val.to_string()));
            idx += 1;
        }
        if let Some(val) = description {
            sets.push(format!("description = ?{idx}"));
            params.push(Box::new(val.to_string()));
            idx += 1;
        }
        if let Some(val) = hub_category {
            sets.push(format!("hub_category = ?{idx}"));
            params.push(Box::new(val.to_string()));
            idx += 1;
        }
        if let Some(tags) = hub_tags {
            let json = serde_json::to_string(tags)
                .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
            sets.push(format!("hub_tags_json = ?{idx}"));
            params.push(Box::new(json));
            idx += 1;
        }
        if let Some(val) = hub_version {
            sets.push(format!("hub_version = ?{idx}"));
            params.push(Box::new(val));
            idx += 1;
        }
        if let Some(val) = config_yaml {
            sets.push(format!("config_json = ?{idx}"));
            params.push(Box::new(val.to_string()));
            idx += 1;
        }
        if let Some(refs) = agent_refs {
            let json = serde_json::to_string(refs)
                .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
            sets.push(format!("agent_refs_json = ?{idx}"));
            params.push(Box::new(json));
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
            "UPDATE workspace_templates SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        self.db.execute(&sql, &param_refs)?;
        Ok(())
    }

    /// Deletes the workspace template with the given `id`.
    pub fn delete_workspace_template(&self, id: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM workspace_templates WHERE id = ?1",
            &[&id as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }
}

const SELECT_COLS: &str = "SELECT id, name, description, hub_slug, hub_author, hub_category, hub_tags_json, hub_version, config_json, agent_refs_json, created_at, updated_at";

const SELECT_ALL_SQL: &str = "SELECT id, name, description, hub_slug, hub_author, hub_category, hub_tags_json, hub_version, config_json, agent_refs_json, created_at, updated_at FROM workspace_templates ORDER BY updated_at DESC";

fn row_to_workspace_template(row: &rusqlite::Row<'_>) -> Result<WorkspaceTemplate> {
    let hub_tags_json: String = row
        .get(6)
        .map_err(|e| AppError::Storage(format!("Failed to read hub_tags_json: {e}")))?;
    let hub_tags: Vec<String> = serde_json::from_str(&hub_tags_json)
        .map_err(|e| AppError::Storage(format!("JSON decode hub_tags failed: {e}")))?;

    let agent_refs_json: String = row
        .get(9)
        .map_err(|e| AppError::Storage(format!("Failed to read agent_refs_json: {e}")))?;
    let agent_refs: Vec<String> = serde_json::from_str(&agent_refs_json)
        .map_err(|e| AppError::Storage(format!("JSON decode agent_refs failed: {e}")))?;

    let created_at_str: String = row
        .get(10)
        .map_err(|e| AppError::Storage(format!("Failed to read created_at: {e}")))?;
    let updated_at_str: String = row
        .get(11)
        .map_err(|e| AppError::Storage(format!("Failed to read updated_at: {e}")))?;

    Ok(WorkspaceTemplate {
        id: row.get(0).map_err(|e| AppError::Storage(format!("Failed to read id: {e}")))?,
        name: row.get(1).map_err(|e| AppError::Storage(format!("Failed to read name: {e}")))?,
        description: row
            .get(2)
            .map_err(|e| AppError::Storage(format!("Failed to read description: {e}")))?,
        hub_slug: row
            .get(3)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_slug: {e}")))?,
        hub_author: row
            .get(4)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_author: {e}")))?,
        hub_category: row
            .get(5)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_category: {e}")))?,
        hub_tags,
        hub_version: row
            .get(7)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_version: {e}")))?,
        config_yaml: row
            .get(8)
            .map_err(|e| AppError::Storage(format!("Failed to read config_json: {e}")))?,
        agent_refs,
        created_at: parse_datetime(&created_at_str)?,
        updated_at: parse_datetime(&updated_at_str)?,
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
