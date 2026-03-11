// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// How the app is currently operating.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AuthMode {
    /// Not yet determined (app startup).
    Undetermined,

    /// Local-only mode, no server connection.
    Anonymous,

    /// Connected to the d:spatch backend with a user account.
    Connected,
}
