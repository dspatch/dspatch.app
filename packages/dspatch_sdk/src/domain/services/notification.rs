// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use async_trait::async_trait;

use crate::util::result::Result;

use super::WatchStream;

/// Manages local OS notifications and user notification preferences.
#[async_trait]
pub trait NotificationService: Send + Sync {
    /// Initializes the notification system (requests permissions, etc.).
    async fn initialize(&self) -> Result<()>;

    /// Shows a local OS notification with the given `title` and `body`.
    async fn show_local(&self, title: &str, body: &str) -> Result<()>;

    /// Watches notification preferences as a map of event key to enabled.
    /// Keys: "new_inquiry", "high_priority_inquiry", "session_completed", etc.
    fn watch_preferences(&self) -> WatchStream<HashMap<String, bool>>;

    /// Enables or disables notifications for the given event `key`.
    async fn update_preference(&self, key: &str, enabled: bool) -> Result<()>;
}
