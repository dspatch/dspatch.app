// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Severity of a session log entry.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LogLevel {
    /// Verbose debugging output.
    Debug,

    /// Informational message.
    Info,

    /// Non-fatal warning.
    Warn,

    /// Error that may require attention.
    Error,
}

impl LogLevel {
    /// Returns the `LogLevel` matching `name`, or `None` if no match.
    pub fn try_from_name(name: &str) -> Option<Self> {
        match name {
            "debug" => Some(Self::Debug),
            "info" => Some(Self::Info),
            "warn" => Some(Self::Warn),
            "error" => Some(Self::Error),
            _ => None,
        }
    }
}
