// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A lightweight agent template — a configuration preset that references
/// a provider via `source_uri` and overrides some of its defaults.
///
/// The actual configuration lives in a `dspatch.agent.yml` file at `file_path`.
/// This DB record is just a pointer to that file.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AgentTemplate {
    pub id: String,
    pub name: String,
    /// `dspatch://agent/<author>/<slug>` pointing to the source provider.
    pub source_uri: String,
    /// Absolute path to `dspatch.agent.yml` in appdata.
    pub file_path: String,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
