// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// How an agent template's source code is obtained.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SourceType {
    /// Source resides on the local file system.
    Local,

    /// Source is cloned from a remote Git repository.
    Git,

    /// Source is sourced from the community hub.
    Hub,
}
