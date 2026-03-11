// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::cmp::Ordering;

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// A single file system entry for the file browser.
///
/// Used as the data contract between the service layer and UI.
/// Does not include children -- tree structure is handled separately.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileEntry {
    /// File or directory name (e.g. "main.py").
    pub name: String,

    /// Absolute path on the host filesystem.
    pub path: String,

    /// Path relative to the workspace root (e.g. "src/main.py").
    pub relative_path: String,

    /// Whether this entry is a directory.
    pub is_directory: bool,

    /// Size in bytes. 0 for directories.
    pub size: u64,

    /// Last modification time.
    pub modified: NaiveDateTime,
}

impl PartialEq for FileEntry {
    fn eq(&self, other: &Self) -> bool {
        self.path == other.path
    }
}

impl Eq for FileEntry {}

impl std::hash::Hash for FileEntry {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.path.hash(state);
    }
}

/// Directories first, then alphabetical by name (case-insensitive).
impl Ord for FileEntry {
    fn cmp(&self, other: &Self) -> Ordering {
        match (self.is_directory, other.is_directory) {
            (true, false) => Ordering::Less,
            (false, true) => Ordering::Greater,
            _ => self.name.to_lowercase().cmp(&other.name.to_lowercase()),
        }
    }
}

impl PartialOrd for FileEntry {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl std::fmt::Display for FileEntry {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "FileEntry({}, dir={})",
            self.relative_path, self.is_directory
        )
    }
}

/// Type of file system change detected by the watcher.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum FileChangeType {
    Added,
    Modified,
    Removed,
}

/// A file system change event.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FileChangeEvent {
    pub path: String,
    #[serde(rename = "type")]
    pub change_type: FileChangeType,
}
