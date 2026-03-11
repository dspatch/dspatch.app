// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::{FileChangeEvent, FileEntry};
use crate::util::result::Result;

use super::WatchStream;

/// Browses and watches a workspace's file system.
#[async_trait]
pub trait FileBrowserService: Send + Sync {
    /// Lists immediate children of `directory_path`, sorted by
    /// directories first, then alphabetical.
    async fn list_directory(&self, directory_path: &str) -> Result<Vec<FileEntry>>;

    /// Reads the text content of a file at `file_path`.
    async fn read_file(&self, file_path: &str) -> Result<String>;

    /// Writes `content` to the file at `file_path`.
    async fn write_file(&self, file_path: &str, content: &str) -> Result<()>;

    /// Watches the workspace root for file system changes (recursive).
    ///
    /// Emits [`FileChangeEvent`] for adds, modifications, and removals.
    fn watch_directory(&self, directory_path: &str) -> WatchStream<FileChangeEvent>;

    /// Releases file watchers and any held resources.
    fn dispose(&self);
}
