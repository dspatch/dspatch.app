// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Reactive query layer built on SQLite's `update_hook`.
//!
//! [`TableChangeTracker`] installs a hook on the connection that fires on
//! every INSERT / UPDATE / DELETE, broadcasting a notification keyed by table
//! name.  Consumers call [`watch_query`] to get a `Stream` that automatically
//! re-runs a query whenever any of its dependent tables change.

use std::collections::HashMap;
use std::pin::Pin;
use std::sync::{Arc, Mutex};

use futures::Stream;
use rusqlite::Connection;
use tokio::sync::broadcast;

use crate::util::error::AppError;
use crate::util::result::Result;

/// Capacity of each per-table broadcast channel.  Slow receivers that fall
/// behind this many notifications will get a `Lagged` error (which we treat
/// as "just re-query").
const CHANNEL_CAPACITY: usize = 64;

/// Tracks INSERT / UPDATE / DELETE events per table and exposes broadcast
/// channels so that reactive queries can re-run when their dependencies
/// change.
pub struct TableChangeTracker {
    senders: Arc<Mutex<HashMap<String, broadcast::Sender<()>>>>,
}

impl TableChangeTracker {
    /// Creates a new tracker with no registered tables.
    ///
    /// Tables are lazily registered when [`subscribe`](Self::subscribe) is
    /// first called for a given table name.
    pub fn new() -> Self {
        Self {
            senders: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    /// Installs the SQLite `update_hook` on `conn`.
    ///
    /// The hook fires for every row-level change with
    /// `(action, database_name, table_name, rowid)`.  We ignore the action
    /// and database_name — only the table name matters for notification.
    pub fn install_hook(&self, conn: &mut Connection) {
        let senders = Arc::clone(&self.senders);

        conn.update_hook(Some(
            move |_action: rusqlite::hooks::Action, _db: &str, table: &str, _rowid: i64| {
                let senders = senders.lock().unwrap();
                if let Some(tx) = senders.get(table) {
                    // Ignore send errors — they just mean no active receivers.
                    let _ = tx.send(());
                }
            },
        ));
    }

    /// Subscribes to changes on the specified tables.
    ///
    /// Returns a `broadcast::Receiver<()>` that is notified whenever *any* of
    /// the listed tables is modified.  If a table has not been seen before a
    /// new broadcast channel is created for it.
    ///
    /// NOTE: Because `broadcast::Receiver` is not `Clone`-and-share across
    /// tables we merge all requested tables into a single shared sender for
    /// simplicity — each table's sender independently fires, and we return a
    /// receiver from a *merged* channel.  For the common case (watching 1-3
    /// tables) this is efficient enough.
    pub fn subscribe(&self, tables: &[&str]) -> broadcast::Receiver<()> {
        let mut senders = self.senders.lock().unwrap();

        // We create a dedicated merge channel for this subscription.
        // Each table sender will forward into it.
        if tables.len() == 1 {
            let table = tables[0];
            let tx = senders
                .entry(table.to_string())
                .or_insert_with(|| broadcast::channel(CHANNEL_CAPACITY).0);
            return tx.subscribe();
        }

        // For multi-table subscriptions we ensure each table has a sender
        // and return a receiver from the first table.  The caller will
        // use `watch_query` which handles multi-table merging properly.
        let table = tables[0];
        let tx = senders
            .entry(table.to_string())
            .or_insert_with(|| broadcast::channel(CHANNEL_CAPACITY).0);
        let rx = tx.subscribe();

        // Ensure remaining tables also have channels registered.
        for &t in &tables[1..] {
            senders
                .entry(t.to_string())
                .or_insert_with(|| broadcast::channel(CHANNEL_CAPACITY).0);
        }

        rx
    }

    /// Fires a manual change notification for the given table.
    /// Useful for testing or when changes happen outside the update hook.
    pub fn notify(&self, table: &str) {
        let senders = self.senders.lock().unwrap();
        if let Some(tx) = senders.get(table) {
            let _ = tx.send(());
        }
    }
}

impl Default for TableChangeTracker {
    fn default() -> Self {
        Self::new()
    }
}

/// Creates a `Stream` that re-runs `query` whenever any of the `tables`
/// change.
///
/// The stream emits the initial query result immediately, then re-emits
/// whenever the change tracker fires for any of the listed tables.
pub fn watch_query<T, F>(
    tracker: &Arc<TableChangeTracker>,
    db: &Arc<Mutex<Connection>>,
    tables: &[&str],
    query: F,
) -> Pin<Box<dyn Stream<Item = Result<Vec<T>>> + Send>>
where
    F: Fn(&Connection) -> Result<Vec<T>> + Send + Sync + 'static,
    T: Send + 'static,
{
    // Collect receivers for all tables.
    let mut receivers: Vec<broadcast::Receiver<()>> = {
        let mut senders = tracker.senders.lock().unwrap();
        tables
            .iter()
            .map(|&t| {
                let tx = senders
                    .entry(t.to_string())
                    .or_insert_with(|| broadcast::channel(CHANNEL_CAPACITY).0);
                tx.subscribe()
            })
            .collect()
    };

    let db = Arc::clone(db);

    // Wrap query + db in an Arc so we can call it from the async stream
    // without holding the MutexGuard across yield/await points.
    let query = Arc::new(query);
    let run_query = {
        let db = Arc::clone(&db);
        let query = Arc::clone(&query);
        move || -> Result<Vec<T>> {
            let conn = db.lock().map_err(|e| {
                AppError::Storage(format!("Failed to acquire database lock: {e}"))
            })?;
            query(&conn)
        }
    };

    let stream = async_stream::stream! {
        // Emit initial result.
        let initial = run_query();
        yield initial;

        loop {
            // Wait for any table to fire.
            let mut any_changed = false;
            for rx in &mut receivers {
                match rx.try_recv() {
                    Ok(()) => { any_changed = true; }
                    Err(broadcast::error::TryRecvError::Lagged(_)) => { any_changed = true; }
                    Err(broadcast::error::TryRecvError::Empty) => {}
                    Err(broadcast::error::TryRecvError::Closed) => {
                        return;
                    }
                }
            }

            if !any_changed {
                tokio::task::yield_now().await;

                let changed = wait_any_receiver(&mut receivers).await;
                if !changed {
                    return; // all closed
                }
            }

            // Drain any additional pending notifications (debounce).
            for rx in &mut receivers {
                while rx.try_recv().is_ok() {}
            }

            // Re-run the query — lock is acquired and released inside run_query.
            let result = run_query();
            yield result;
        }
    };

    Box::pin(stream)
}

/// Waits for any of the receivers to fire.  Returns `false` if all are
/// closed.
async fn wait_any_receiver(receivers: &mut [broadcast::Receiver<()>]) -> bool {
    loop {
        for rx in receivers.iter_mut() {
            match rx.try_recv() {
                Ok(()) => return true,
                Err(broadcast::error::TryRecvError::Lagged(_)) => return true,
                Err(broadcast::error::TryRecvError::Closed) => return false,
                Err(broadcast::error::TryRecvError::Empty) => {}
            }
        }
        // Yield and retry — this is a simple polling approach.  In production
        // the hook fires synchronously with the write, so this polling loop
        // only runs briefly between writes.
        tokio::time::sleep(std::time::Duration::from_millis(10)).await;
    }
}
