// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Data-access objects (DAOs) providing typed operations on top of the
//! raw SQLite database.
//!
//! Each DAO wraps an `Arc<Database>` and exposes domain-level methods
//! that handle SQL, parameter binding, and row-to-model conversion.
//! Reactive `watch_*` methods use [`super::reactive::watch_query`] to
//! return streams that re-emit whenever relevant tables change.

pub mod agent_provider_dao;
pub mod agent_template_dao;
pub mod api_key_dao;
pub mod preference_dao;
pub mod workspace_dao;
pub mod workspace_template_dao;

pub use agent_provider_dao::AgentProviderDao;
pub use agent_template_dao::AgentTemplateDao;
pub use api_key_dao::ApiKeyDao;
pub use preference_dao::PreferenceDao;
pub use workspace_dao::WorkspaceDao;
pub use workspace_template_dao::WorkspaceTemplateDao;

use chrono::NaiveDateTime;

use crate::util::error::AppError;
use crate::util::result::Result;

/// The ISO 8601 format used by SQLite's strftime default expressions.
/// Handles both `%Y-%m-%dT%H:%M:%S.%fZ` and `%Y-%m-%dT%H:%M:%SZ`.
pub(crate) fn parse_datetime(s: &str) -> Result<NaiveDateTime> {
    // Try with fractional seconds first, then without.
    NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.fZ")
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%SZ"))
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f"))
        .or_else(|_| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S"))
        .map_err(|e| AppError::Storage(format!("Failed to parse datetime '{s}': {e}")))
}

/// Formats a `NaiveDateTime` as an ISO 8601 string for SQLite storage.
pub(crate) fn format_datetime(dt: &NaiveDateTime) -> String {
    dt.format("%Y-%m-%dT%H:%M:%S%.3fZ").to_string()
}
