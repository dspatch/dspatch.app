// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite update hook that auto-records mutations to synced tables into the
//! sync outbox. Uses `TableClassification` to filter: only synced tables
//! produce outbox entries.
//!
//! This hook is installed on the database connection and fires on every
//! INSERT, UPDATE, or DELETE. It is the bridge between DAO writes and the
//! sync engine — DAOs don't need to know about sync at all.

use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::Arc;

use super::table_class::TableClassification;

/// Installs an SQLite `update_hook` that records changes to synced tables
/// into the `sync_outbox` table.
pub struct OutboxHook {
    device_id: String,
    lamport_clock: Arc<AtomicI64>,
}

impl OutboxHook {
    /// Creates a new outbox hook for the given device.
    pub fn new(device_id: String) -> Self {
        Self {
            device_id,
            lamport_clock: Arc::new(AtomicI64::new(0)),
        }
    }

    /// Initializes the Lamport clock from the current max in the outbox.
    /// Call after the database is ready.
    pub fn bootstrap_clock(&self, conn: &rusqlite::Connection) {
        let max_ts: i64 = conn
            .query_row(
                "SELECT COALESCE(MAX(lamport_ts), 0) FROM sync_outbox",
                [],
                |row| row.get(0),
            )
            .unwrap_or(0);
        self.lamport_clock.store(max_ts, Ordering::SeqCst);
    }

    /// Installs the update hook on a connection.
    ///
    /// **Warning:** SQLite only supports one `update_hook` per connection. If
    /// `TableChangeTracker` also uses `update_hook`, they must be combined
    /// into a single hook that dispatches to both. See the integration note
    /// in the task description.
    pub fn install(&self, conn: &rusqlite::Connection) {
        let device_id = self.device_id.clone();
        let clock = Arc::clone(&self.lamport_clock);

        conn.update_hook(Some(
            move |action: rusqlite::hooks::Action, _db: &str, table: &str, rowid: i64| {
                // Skip non-synced tables.
                if !TableClassification::is_synced(table) {
                    return;
                }

                // Skip writes to sync infrastructure tables to avoid recursion.
                if table == "sync_outbox" || table == "sync_cursors" {
                    return;
                }

                let op = match action {
                    rusqlite::hooks::Action::SQLITE_INSERT => "insert",
                    rusqlite::hooks::Action::SQLITE_UPDATE => "update",
                    rusqlite::hooks::Action::SQLITE_DELETE => "delete",
                    _ => return,
                };

                let lamport = clock.fetch_add(1, Ordering::SeqCst) + 1;
                let id = uuid::Uuid::new_v4().to_string();
                let created_at = chrono::Utc::now().to_rfc3339();

                let row_id_str = rowid.to_string();

                PENDING_CHANGES.with(|pending| {
                    pending.borrow_mut().push(PendingChange {
                        id,
                        table: table.to_string(),
                        row_id: row_id_str,
                        operation: op.to_string(),
                        lamport_ts: lamport,
                        device_id: device_id.clone(),
                        created_at,
                    });
                });
            },
        ));
    }

    /// Flushes any pending changes recorded by the update hook into the
    /// `sync_outbox` table. Call after each DAO write completes.
    pub fn flush_pending(conn: &rusqlite::Connection) {
        let changes: Vec<PendingChange> = PENDING_CHANGES.with(|pending| {
            pending.borrow_mut().drain(..).collect()
        });

        for change in changes {
            let _ = conn.execute(
                "INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id, created_at) \
                 VALUES (?1, ?2, ?3, ?4, NULL, ?5, ?6, ?7)",
                rusqlite::params![
                    &change.id,
                    &change.table,
                    &change.row_id,
                    &change.operation,
                    change.lamport_ts,
                    &change.device_id,
                    &change.created_at,
                ],
            );
        }
    }
}

/// A change captured by the update hook, waiting to be flushed.
#[derive(Debug)]
struct PendingChange {
    id: String,
    table: String,
    row_id: String,
    operation: String,
    lamport_ts: i64,
    device_id: String,
    created_at: String,
}

thread_local! {
    static PENDING_CHANGES: std::cell::RefCell<Vec<PendingChange>> =
        std::cell::RefCell::new(Vec::new());
}
