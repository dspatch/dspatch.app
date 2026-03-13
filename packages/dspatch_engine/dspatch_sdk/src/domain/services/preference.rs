// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::util::result::Result;

/// Typed access to user preferences stored as key-value pairs.
///
/// All keys should come from `PreferenceKeys` to prevent typos.
/// Values are stored as strings; callers are responsible for
/// serialization/deserialization of non-string types.
#[async_trait]
pub trait PreferenceService: Send + Sync {
    /// Returns the value for `key`, or `None` if not set.
    async fn get_preference(&self, key: &str) -> Result<Option<String>>;

    /// Sets `key` to `value`, creating or updating the entry.
    async fn set_preference(&self, key: &str, value: &str) -> Result<()>;

    /// Removes the preference for `key`.
    async fn delete_preference(&self, key: &str) -> Result<()>;
}
