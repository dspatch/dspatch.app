// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Value object carrying all fields needed to create a new [`Workspace`].
///
/// The workspace name is extracted from the parsed [`config_yaml`] -- callers
/// provide the raw YAML string and the service handles parsing, validation,
/// and persistence.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct CreateWorkspaceRequest {
    /// Filesystem path to the project directory where `dspatch.workspace.yml` will
    /// be written and `.dspatch/templates/` created.
    pub project_path: String,

    /// Raw YAML string representing the workspace configuration
    /// (the contents of `dspatch.workspace.yml`). Parsed and validated by the service.
    pub config_yaml: String,
}
