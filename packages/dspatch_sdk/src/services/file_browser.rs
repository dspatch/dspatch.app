// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local file browser service — uses std::fs and the `notify` crate.

use std::path::Path;
use std::sync::Arc;

use tokio::sync::Mutex;

use crate::domain::models::{FileChangeEvent, FileChangeType, FileEntry};
use crate::domain::services::WatchStream;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Local file browser service that reads the host filesystem directly.
///
/// All paths are resolved relative to [`root_path`] (the workspace project dir).
/// Uses the `notify` crate for file system watching.
pub struct LocalFileBrowserService {
    root_path: String,
    _watcher: Arc<Mutex<Option<notify::RecommendedWatcher>>>,
}

impl LocalFileBrowserService {
    pub fn new(root_path: String) -> Self {
        Self {
            root_path,
            _watcher: Arc::new(Mutex::new(None)),
        }
    }

    /// Lists immediate children of `directory_path`, sorted by
    /// directories first, then alphabetical.
    pub async fn list_directory(&self, directory_path: &str) -> Result<Vec<FileEntry>> {
        let dir = Path::new(directory_path);
        if !dir.exists() {
            return Ok(Vec::new());
        }

        let root_path = self.root_path.clone();
        let dir_path = directory_path.to_string();

        // Use blocking task since std::fs is synchronous.
        tokio::task::spawn_blocking(move || {
            let dir = Path::new(&dir_path);
            let root = Path::new(&root_path);
            let mut entries = Vec::new();

            let read_dir = std::fs::read_dir(dir).map_err(|e| {
                AppError::Storage(format!("Failed to read directory: {e}"))
            })?;

            for entry in read_dir {
                let entry = entry.map_err(|e| {
                    AppError::Storage(format!("Failed to read entry: {e}"))
                })?;

                let name = entry.file_name().to_string_lossy().to_string();
                // Skip hidden files (starting with .)
                if name.starts_with('.') {
                    continue;
                }

                let path = entry.path();
                let metadata = entry.metadata().map_err(|e| {
                    AppError::Storage(format!("Failed to stat {}: {e}", path.display()))
                })?;

                let is_directory = metadata.is_dir();
                let size = if is_directory { 0 } else { metadata.len() };

                let modified = metadata
                    .modified()
                    .ok()
                    .and_then(|t| {
                        let duration = t
                            .duration_since(std::time::UNIX_EPOCH)
                            .ok()?;
                        chrono::DateTime::from_timestamp(
                            duration.as_secs() as i64,
                            duration.subsec_nanos(),
                        )
                        .map(|dt| dt.naive_utc())
                    })
                    .unwrap_or_else(|| chrono::Utc::now().naive_utc());

                let relative_path = path
                    .strip_prefix(root)
                    .unwrap_or(&path)
                    .to_string_lossy()
                    .replace('\\', "/");

                entries.push(FileEntry {
                    name,
                    path: path.to_string_lossy().to_string(),
                    relative_path,
                    is_directory,
                    size,
                    modified,
                });
            }

            entries.sort();
            Ok(entries)
        })
        .await
        .map_err(|e| AppError::Storage(format!("Task join error: {e}")))?
    }

    /// Reads the text content of a file at `file_path`.
    pub async fn read_file(&self, file_path: &str) -> Result<String> {
        tokio::fs::read_to_string(file_path)
            .await
            .map_err(|e| AppError::Storage(format!("Failed to read file: {e}")))
    }

    /// Writes `content` to the file at `file_path`.
    pub async fn write_file(&self, file_path: &str, content: &str) -> Result<()> {
        tokio::fs::write(file_path, content)
            .await
            .map_err(|e| AppError::Storage(format!("Failed to write file: {e}")))
    }

    /// Watches the directory for file system changes (recursive).
    ///
    /// Uses the `notify` crate to watch for adds, modifications, and removals.
    pub fn watch_directory(&self, directory_path: &str) -> WatchStream<FileChangeEvent> {
        use notify::{Event, EventKind, RecursiveMode, Watcher};

        let (tx, mut rx) = tokio::sync::mpsc::channel(256);
        let dir_path = directory_path.to_string();
        let watcher_slot = self._watcher.clone();

        // Spawn a task that sets up the notify watcher.
        tokio::spawn(async move {
            let tx_clone = tx.clone();
            let watcher_result = notify::recommended_watcher(
                move |result: std::result::Result<Event, notify::Error>| {
                    if let Ok(event) = result {
                        let change_type = match event.kind {
                            EventKind::Create(_) => Some(FileChangeType::Added),
                            EventKind::Modify(_) => Some(FileChangeType::Modified),
                            EventKind::Remove(_) => Some(FileChangeType::Removed),
                            _ => None,
                        };
                        if let Some(ct) = change_type {
                            for path in &event.paths {
                                let evt = FileChangeEvent {
                                    path: path.to_string_lossy().to_string(),
                                    change_type: ct,
                                };
                                let _ = tx_clone.blocking_send(evt);
                            }
                        }
                    }
                },
            );

            match watcher_result {
                Ok(mut watcher) => {
                    if let Err(e) =
                        watcher.watch(Path::new(&dir_path), RecursiveMode::Recursive)
                    {
                        tracing::warn!("Failed to watch directory: {e}");
                        return;
                    }
                    // Store the watcher so it stays alive.
                    *watcher_slot.lock().await = Some(watcher);
                }
                Err(e) => {
                    tracing::warn!("Failed to create file watcher: {e}");
                }
            }
        });

        let stream = async_stream::stream! {
            while let Some(event) = rx.recv().await {
                yield event;
            }
        };

        Box::pin(stream)
    }

    /// Releases file watchers and any held resources.
    pub fn dispose(&self) {
        let watcher = self._watcher.clone();
        tokio::spawn(async move {
            *watcher.lock().await = None;
        });
    }
}
