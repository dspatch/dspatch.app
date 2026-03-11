// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local preference service — wraps PreferenceDao directly.

use std::sync::Arc;

use futures::StreamExt;

use crate::db::dao::PreferenceDao;
use crate::domain::services::WatchStream;
use crate::util::result::Result;

/// Local preference service backed by [`PreferenceDao`].
///
/// Provides typed access to user preferences stored as key-value pairs
/// in SQLite.
pub struct LocalPreferenceService {
    dao: Arc<PreferenceDao>,
}

impl LocalPreferenceService {
    pub fn new(dao: Arc<PreferenceDao>) -> Self {
        Self { dao }
    }

    /// Returns the value for `key`, or `None` if not set.
    pub async fn get_preference(&self, key: &str) -> Result<Option<String>> {
        self.dao.get_preference(key)
    }

    /// Sets `key` to `value`, creating or updating the entry.
    pub async fn set_preference(&self, key: &str, value: &str) -> Result<()> {
        self.dao.set_preference(key, value)
    }

    /// Watches the value for `key`, emitting `None` when unset.
    ///
    /// The DAO stream emits `Result<Option<String>>`; we unwrap errors
    /// by logging and skipping.
    pub fn watch_preference(&self, key: &str) -> WatchStream<Option<String>> {
        let stream = self.dao.watch_preference(key);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_preference error: {e}");
                    None
                }
            }
        }))
    }

    /// Removes the preference for `key`.
    pub async fn delete_preference(&self, key: &str) -> Result<()> {
        self.dao.delete_preference(key)
    }
}
