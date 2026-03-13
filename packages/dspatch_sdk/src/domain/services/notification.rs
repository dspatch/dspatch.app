// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::util::result::Result;

/// Manages local OS notifications and user notification preferences.
#[async_trait]
pub trait NotificationService: Send + Sync {
    /// Initializes the notification system (requests permissions, etc.).
    async fn initialize(&self) -> Result<()>;

    /// Shows a local OS notification with the given `title` and `body`.
    async fn show_local(&self, title: &str, body: &str) -> Result<()>;

    /// Enables or disables notifications for the given event `key`.
    async fn update_preference(&self, key: &str, enabled: bool) -> Result<()>;
}
