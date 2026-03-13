// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Aggregates per-table change notifications from `TableChangeTracker` into
//! debounced batches for WebSocket clients.
//!
//! The `InvalidationBroadcaster` subscribes to all known table channels,
//! collects changed table names over a configurable debounce window, then
//! emits a single `Vec<String>` per window containing deduplicated table names.
//!
//! WebSocket connection handlers subscribe to the broadcaster's output channel
//! and convert each batch into a `ServerFrame::Invalidate`.

use std::collections::HashSet;
use std::sync::Arc;

use tokio::sync::broadcast;

use crate::db::reactive::TableChangeTracker;
use crate::db::schema::TABLE_NAMES;

/// Capacity of the outbound broadcast channel. WS handlers that fall behind
/// this many batches receive a `Lagged` error (treated as "re-query everything").
const BROADCAST_CAPACITY: usize = 64;

/// Aggregates table-level change notifications into debounced batches.
///
/// Create one per engine. Call [`start`](Self::start) to spawn the background
/// aggregation task. Distribute [`InvalidationHandle`]s to WebSocket handlers.
pub struct InvalidationBroadcaster {
    tracker: Arc<TableChangeTracker>,
    debounce_ms: u64,
}

/// Handle returned by [`InvalidationBroadcaster::start`].
///
/// Cheap to clone. Use [`subscribe`](Self::subscribe) to get a receiver for
/// batched table invalidation events.
pub struct InvalidationHandle {
    tx: broadcast::Sender<Vec<String>>,
    shutdown_tx: tokio::sync::watch::Sender<bool>,
}

impl InvalidationBroadcaster {
    /// Creates a new broadcaster.
    ///
    /// - `tracker`: the shared `TableChangeTracker` that receives SQLite update_hook events.
    /// - `debounce_ms`: how long (in milliseconds) to collect table names before flushing a batch.
    pub fn new(tracker: Arc<TableChangeTracker>, debounce_ms: u64) -> Self {
        Self {
            tracker,
            debounce_ms,
        }
    }

    /// Spawns the background aggregation task and returns a handle.
    ///
    /// The task subscribes to every table in `TABLE_NAMES`, polls for changes,
    /// and batches them into debounced `Vec<String>` emissions.
    ///
    /// Subscriptions to the tracker are created eagerly (before spawning) so
    /// that notifications sent immediately after `start()` returns are never
    /// lost.
    pub fn start(self) -> InvalidationHandle {
        let (tx, _) = broadcast::channel(BROADCAST_CAPACITY);
        let (shutdown_tx, shutdown_rx) = tokio::sync::watch::channel(false);

        // Subscribe to every known table *before* spawning so we don't miss
        // notifications that arrive between `start()` returning and the task
        // beginning to poll.
        let table_receivers: Vec<(String, broadcast::Receiver<()>)> = TABLE_NAMES
            .iter()
            .map(|&name| {
                let rx = self.tracker.subscribe(&[name]);
                (name.to_string(), rx)
            })
            .collect();

        let tx_clone = tx.clone();
        let debounce_ms = self.debounce_ms;

        tokio::spawn(async move {
            run_aggregation_loop(table_receivers, tx_clone, shutdown_rx, debounce_ms).await;
        });

        InvalidationHandle { tx, shutdown_tx }
    }
}

impl InvalidationHandle {
    /// Returns a receiver that yields `Vec<String>` batches of changed table names.
    pub fn subscribe(&self) -> broadcast::Receiver<Vec<String>> {
        self.tx.subscribe()
    }

    /// Signals the background task to stop.
    pub fn shutdown(&self) {
        let _ = self.shutdown_tx.send(true);
    }
}

/// Core aggregation loop. Collects changes from pre-subscribed table receivers
/// over `debounce_ms` windows and emits deduplicated batches.
async fn run_aggregation_loop(
    mut table_receivers: Vec<(String, broadcast::Receiver<()>)>,
    tx: broadcast::Sender<Vec<String>>,
    mut shutdown_rx: tokio::sync::watch::Receiver<bool>,
    debounce_ms: u64,
) {
    let debounce = std::time::Duration::from_millis(debounce_ms);

    loop {
        // Phase 1: Wait for the first change (or shutdown).
        let first_table = loop {
            // Check shutdown.
            if *shutdown_rx.borrow() {
                return;
            }

            let mut found = None;
            for (name, rx) in &mut table_receivers {
                match rx.try_recv() {
                    Ok(()) | Err(broadcast::error::TryRecvError::Lagged(_)) => {
                        found = Some(name.clone());
                        break;
                    }
                    Err(broadcast::error::TryRecvError::Empty) => {}
                    Err(broadcast::error::TryRecvError::Closed) => return,
                }
            }

            if let Some(table) = found {
                break table;
            }

            // No changes yet — sleep briefly and check again.
            tokio::select! {
                _ = tokio::time::sleep(std::time::Duration::from_millis(5)) => {}
                _ = shutdown_rx.changed() => {
                    if *shutdown_rx.borrow() {
                        return;
                    }
                }
            }
        };

        // Phase 2: Debounce window — collect all changes for `debounce_ms`.
        let mut changed: HashSet<String> = HashSet::new();
        changed.insert(first_table);

        tokio::time::sleep(debounce).await;

        // Drain all pending changes across all tables.
        for (name, rx) in &mut table_receivers {
            loop {
                match rx.try_recv() {
                    Ok(()) | Err(broadcast::error::TryRecvError::Lagged(_)) => {
                        changed.insert(name.clone());
                    }
                    Err(broadcast::error::TryRecvError::Empty) => break,
                    Err(broadcast::error::TryRecvError::Closed) => return,
                }
            }
        }

        // Phase 3: Emit the batch.
        let batch: Vec<String> = changed.into_iter().collect();
        if !batch.is_empty() {
            let _ = tx.send(batch);
        }
    }
}
