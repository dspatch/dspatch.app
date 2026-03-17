// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// A key-value environment variable injected into a provider's container.
///
/// When [`is_secret`] is true the value contains an `{{apikey:Name}}` reference
/// that is resolved at container launch time. [`is_enabled`] allows
/// toggling individual variables without deleting them.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct EnvVar {
    pub key: String,
    #[serde(default)]
    pub value: String,
    #[serde(default)]
    pub is_secret: bool,
    #[serde(default = "default_true")]
    pub is_enabled: bool,
}

fn default_true() -> bool {
    true
}
