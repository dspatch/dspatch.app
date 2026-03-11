// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access object for the `agent_providers` table.

use std::collections::HashMap;
use std::pin::Pin;
use std::sync::Arc;

use futures::Stream;

use crate::db::reactive::watch_query;
use crate::db::Database;
use crate::domain::enums::SourceType;
use crate::domain::models::{AgentProvider, UpdateAgentProviderRequest};
use crate::util::error::AppError;
use crate::util::result::Result;

use super::{format_datetime, parse_datetime};

/// Provides typed CRUD and reactive watch operations on the `agent_providers`
/// table.
pub struct AgentProviderDao {
    db: Arc<Database>,
}

impl AgentProviderDao {
    /// Creates a new DAO backed by the given database.
    pub fn new(db: Arc<Database>) -> Self {
        Self { db }
    }

    /// Returns a stream of all agent providers, ordered by `updated_at` descending.
    pub fn watch_agent_providers(
        &self,
    ) -> Pin<Box<dyn Stream<Item = Result<Vec<AgentProvider>>> + Send>> {
        watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_providers"],
            |conn| {
                let mut stmt = conn
                    .prepare(SELECT_ALL_SQL)
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let rows = stmt
                    .query_map([], |row| Ok(row_to_agent_provider(row)))
                    .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?
                    .collect::<std::result::Result<Vec<_>, _>>()
                    .map_err(|e| AppError::Storage(format!("Row mapping failed: {e}")))?;
                rows.into_iter().collect::<Result<Vec<_>>>()
            },
        )
    }

    /// Returns a stream that emits the agent provider with `id`, or `None`.
    pub fn watch_agent_provider(
        &self,
        id: &str,
    ) -> Pin<Box<dyn Stream<Item = Result<Option<AgentProvider>>> + Send>> {
        let id = id.to_string();
        let stream = watch_query(
            self.db.tracker(),
            self.db.conn_arc(),
            &["agent_providers"],
            move |conn| {
                let mut stmt = conn
                    .prepare(&format!("{SELECT_COLS} FROM agent_providers WHERE id = ?1"))
                    .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
                let result = stmt
                    .query_row(rusqlite::params![id], |row| {
                        Ok(row_to_agent_provider(row))
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

    /// Returns the agent provider with the given `id`. Errors if not found.
    pub fn get_agent_provider(&self, id: &str) -> Result<AgentProvider> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{SELECT_COLS} FROM agent_providers WHERE id = ?1"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![id], |row| {
                Ok(row_to_agent_provider(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => r,
            None => Err(AppError::NotFound(format!(
                "Agent provider not found: {id}"
            ))),
        }
    }

    /// Returns the agent provider with the given `name`, or `None`.
    pub fn get_agent_provider_by_name(&self, name: &str) -> Result<Option<AgentProvider>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(&format!("{SELECT_COLS} FROM agent_providers WHERE name = ?1"))
            .map_err(|e| AppError::Storage(format!("Prepare failed: {e}")))?;
        let result = stmt
            .query_row(rusqlite::params![name], |row| {
                Ok(row_to_agent_provider(row))
            })
            .optional()
            .map_err(|e| AppError::Storage(format!("Query failed: {e}")))?;
        match result {
            Some(r) => Ok(Some(r?)),
            None => Ok(None),
        }
    }

    /// Inserts a new agent provider. JSON fields are serialized from the model.
    pub fn insert_agent_provider(&self, template: &AgentProvider) -> Result<()> {
        let required_env_json = serde_json::to_string(&template.required_env)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
        let required_mounts_json = serde_json::to_string(&template.required_mounts)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
        let fields_json = serde_json::to_string(&template.fields)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
        let hub_tags_json = serde_json::to_string(&template.hub_tags)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
        let source_type_str = serde_json::to_value(&template.source_type)
            .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?
            .as_str()
            .unwrap_or("local")
            .to_string();
        let created_at = format_datetime(&template.created_at);
        let updated_at = format_datetime(&template.updated_at);

        self.db.execute(
            "INSERT INTO agent_providers (id, name, source_type, source_path, git_url, git_branch, entry_point, description, readme, required_env_json, required_mounts_json, fields_json, hub_slug, hub_author, hub_category, hub_tags_json, hub_version, hub_repo_url, hub_commit_hash, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18, ?19, ?20, ?21)",
            &[
                &template.id as &dyn rusqlite::types::ToSql,
                &template.name,
                &source_type_str,
                &template.source_path as &dyn rusqlite::types::ToSql,
                &template.git_url as &dyn rusqlite::types::ToSql,
                &template.git_branch as &dyn rusqlite::types::ToSql,
                &template.entry_point,
                &template.description as &dyn rusqlite::types::ToSql,
                &template.readme as &dyn rusqlite::types::ToSql,
                &required_env_json,
                &required_mounts_json,
                &fields_json,
                &template.hub_slug as &dyn rusqlite::types::ToSql,
                &template.hub_author as &dyn rusqlite::types::ToSql,
                &template.hub_category as &dyn rusqlite::types::ToSql,
                &hub_tags_json,
                &template.hub_version as &dyn rusqlite::types::ToSql,
                &template.hub_repo_url as &dyn rusqlite::types::ToSql,
                &template.hub_commit_hash as &dyn rusqlite::types::ToSql,
                &created_at,
                &updated_at,
            ],
        )?;
        Ok(())
    }

    /// Partially updates the agent provider with `id`. Only non-`None` fields
    /// in `update` are applied.
    pub fn update_agent_provider(
        &self,
        id: &str,
        update: &UpdateAgentProviderRequest,
    ) -> Result<()> {
        let mut sets = Vec::new();
        let mut params: Vec<Box<dyn rusqlite::types::ToSql>> = Vec::new();
        let mut idx = 1;

        macro_rules! maybe_set {
            ($field:ident, $col:expr) => {
                if let Some(ref val) = update.$field {
                    sets.push(format!("{} = ?{}", $col, idx));
                    params.push(Box::new(val.clone()));
                    idx += 1;
                }
            };
        }

        macro_rules! maybe_set_json {
            ($field:ident, $col:expr) => {
                if let Some(ref val) = update.$field {
                    let json = serde_json::to_string(val)
                        .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?;
                    sets.push(format!("{} = ?{}", $col, idx));
                    params.push(Box::new(json));
                    idx += 1;
                }
            };
        }

        maybe_set!(name, "name");

        if let Some(ref source_type) = update.source_type {
            let st = serde_json::to_value(source_type)
                .map_err(|e| AppError::Storage(format!("JSON encode failed: {e}")))?
                .as_str()
                .unwrap_or("local")
                .to_string();
            sets.push(format!("source_type = ?{idx}"));
            params.push(Box::new(st));
            idx += 1;
        }

        maybe_set!(source_path, "source_path");
        maybe_set!(git_url, "git_url");
        maybe_set!(git_branch, "git_branch");
        maybe_set!(entry_point, "entry_point");
        maybe_set!(description, "description");
        maybe_set!(readme, "readme");
        maybe_set_json!(required_env, "required_env_json");
        maybe_set_json!(required_mounts, "required_mounts_json");
        maybe_set_json!(fields, "fields_json");
        maybe_set!(hub_slug, "hub_slug");
        maybe_set!(hub_author, "hub_author");
        maybe_set!(hub_category, "hub_category");
        maybe_set_json!(hub_tags, "hub_tags_json");
        maybe_set!(hub_version, "hub_version");
        maybe_set!(hub_repo_url, "hub_repo_url");
        maybe_set!(hub_commit_hash, "hub_commit_hash");

        if sets.is_empty() {
            return Ok(());
        }

        // Always bump updated_at.
        let now = chrono::Utc::now().naive_utc();
        sets.push(format!("updated_at = ?{idx}"));
        params.push(Box::new(format_datetime(&now)));
        idx += 1;

        let sql = format!(
            "UPDATE agent_providers SET {} WHERE id = ?{}",
            sets.join(", "),
            idx
        );
        params.push(Box::new(id.to_string()));

        let param_refs: Vec<&dyn rusqlite::types::ToSql> =
            params.iter().map(|p| p.as_ref()).collect();
        self.db.execute(&sql, &param_refs)?;
        Ok(())
    }

    /// Deletes the agent provider with the given `id`.
    pub fn delete_agent_provider(&self, id: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM agent_providers WHERE id = ?1",
            &[&id as &dyn rusqlite::types::ToSql],
        )?;
        Ok(())
    }
}

const SELECT_COLS: &str = "SELECT id, name, source_type, source_path, git_url, git_branch, entry_point, description, readme, required_env_json, required_mounts_json, fields_json, hub_slug, hub_author, hub_category, hub_tags_json, hub_version, hub_repo_url, hub_commit_hash, created_at, updated_at";

const SELECT_ALL_SQL: &str = "SELECT id, name, source_type, source_path, git_url, git_branch, entry_point, description, readme, required_env_json, required_mounts_json, fields_json, hub_slug, hub_author, hub_category, hub_tags_json, hub_version, hub_repo_url, hub_commit_hash, created_at, updated_at FROM agent_providers ORDER BY updated_at DESC";

fn row_to_agent_provider(row: &rusqlite::Row<'_>) -> Result<AgentProvider> {
    let source_type_str: String = row
        .get(2)
        .map_err(|e| AppError::Storage(format!("Failed to read source_type: {e}")))?;
    let source_type: SourceType = match source_type_str.as_str() {
        "local" => SourceType::Local,
        "git" => SourceType::Git,
        "hub" => SourceType::Hub,
        other => {
            return Err(AppError::Storage(format!(
                "Unknown source_type: {other}"
            )))
        }
    };

    let required_env_json: String = row
        .get(9)
        .map_err(|e| AppError::Storage(format!("Failed to read required_env_json: {e}")))?;
    let required_env: Vec<String> = serde_json::from_str(&required_env_json)
        .map_err(|e| AppError::Storage(format!("JSON decode required_env failed: {e}")))?;

    let required_mounts_json: String = row
        .get(10)
        .map_err(|e| AppError::Storage(format!("Failed to read required_mounts_json: {e}")))?;
    let required_mounts: Vec<String> = serde_json::from_str(&required_mounts_json)
        .map_err(|e| AppError::Storage(format!("JSON decode required_mounts failed: {e}")))?;

    let fields_json: String = row
        .get(11)
        .map_err(|e| AppError::Storage(format!("Failed to read fields_json: {e}")))?;
    let fields: HashMap<String, String> = serde_json::from_str(&fields_json)
        .map_err(|e| AppError::Storage(format!("JSON decode fields failed: {e}")))?;

    let hub_tags_json: String = row
        .get(15)
        .map_err(|e| AppError::Storage(format!("Failed to read hub_tags_json: {e}")))?;
    let hub_tags: Vec<String> = serde_json::from_str(&hub_tags_json)
        .map_err(|e| AppError::Storage(format!("JSON decode hub_tags failed: {e}")))?;

    let created_at_str: String = row
        .get(19)
        .map_err(|e| AppError::Storage(format!("Failed to read created_at: {e}")))?;
    let updated_at_str: String = row
        .get(20)
        .map_err(|e| AppError::Storage(format!("Failed to read updated_at: {e}")))?;

    Ok(AgentProvider {
        id: row.get(0).map_err(|e| AppError::Storage(format!("Failed to read id: {e}")))?,
        name: row.get(1).map_err(|e| AppError::Storage(format!("Failed to read name: {e}")))?,
        source_type,
        source_path: row
            .get(3)
            .map_err(|e| AppError::Storage(format!("Failed to read source_path: {e}")))?,
        git_url: row
            .get(4)
            .map_err(|e| AppError::Storage(format!("Failed to read git_url: {e}")))?,
        git_branch: row
            .get(5)
            .map_err(|e| AppError::Storage(format!("Failed to read git_branch: {e}")))?,
        entry_point: row
            .get(6)
            .map_err(|e| AppError::Storage(format!("Failed to read entry_point: {e}")))?,
        description: row
            .get(7)
            .map_err(|e| AppError::Storage(format!("Failed to read description: {e}")))?,
        readme: row
            .get(8)
            .map_err(|e| AppError::Storage(format!("Failed to read readme: {e}")))?,
        required_env,
        required_mounts,
        fields,
        hub_slug: row
            .get(12)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_slug: {e}")))?,
        hub_author: row
            .get(13)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_author: {e}")))?,
        hub_category: row
            .get(14)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_category: {e}")))?,
        hub_tags,
        hub_version: row
            .get(16)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_version: {e}")))?,
        hub_repo_url: row
            .get(17)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_repo_url: {e}")))?,
        hub_commit_hash: row
            .get(18)
            .map_err(|e| AppError::Storage(format!("Failed to read hub_commit_hash: {e}")))?,
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
