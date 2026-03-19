// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Sync engine that orchestrates P2P data synchronization.
//!
//! Uses a Lamport clock for causal ordering and a sync outbox to track local
//! changes. Conflict resolution follows a last-writer-wins strategy based on
//! Lamport timestamps. When timestamps are equal, the lexicographically
//! greater device ID wins (deterministic tiebreaker).

use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::Arc;

use crate::db::Database;
use crate::util::error::AppError;
use crate::util::new_id;
use crate::util::result::Result;

use super::materializer::ChangeMaterializer;
use super::message::{SyncChange, SyncMessage, SyncOp};
use super::peer_connection::PeerConnectionManager;

/// Orchestrates the sync process between devices.
///
/// The engine maintains a Lamport clock and outbox of local changes. It can
/// push pending changes to connected peers, apply incoming remote changes
/// (with last-writer-wins conflict resolution), and reconcile state when
/// a peer reconnects.
pub struct SyncEngine {
    db: Arc<Database>,
    peer_manager: Arc<PeerConnectionManager>,
    device_id: String,
    lamport_clock: AtomicI64,
}

impl SyncEngine {
    /// Creates a new sync engine.
    ///
    /// The Lamport clock is initialised from the highest `lamport_ts` in the
    /// outbox, so it picks up where it left off after a restart.
    pub fn new(
        db: Arc<Database>,
        peer_manager: Arc<PeerConnectionManager>,
        device_id: &str,
    ) -> Self {
        // Bootstrap the lamport clock from persisted outbox.
        let initial_lamport = {
            let conn = db.conn();
            conn.query_row(
                "SELECT COALESCE(MAX(lamport_ts), 0) FROM sync_outbox",
                [],
                |row| row.get::<_, i64>(0),
            )
            .unwrap_or(0)
        };

        Self {
            db,
            peer_manager,
            device_id: device_id.to_string(),
            lamport_clock: AtomicI64::new(initial_lamport),
        }
    }

    /// Returns this engine's device ID.
    pub fn device_id(&self) -> &str {
        &self.device_id
    }

    /// Returns the current Lamport timestamp (without incrementing).
    pub fn current_lamport(&self) -> i64 {
        self.lamport_clock.load(Ordering::SeqCst)
    }

    /// Increments and returns the next Lamport timestamp.
    fn next_lamport(&self) -> i64 {
        self.lamport_clock.fetch_add(1, Ordering::SeqCst) + 1
    }

    /// Updates the Lamport clock to be at least `remote_ts` (merge rule).
    fn merge_lamport(&self, remote_ts: i64) {
        loop {
            let current = self.lamport_clock.load(Ordering::SeqCst);
            let new_val = std::cmp::max(current, remote_ts);
            if self
                .lamport_clock
                .compare_exchange(current, new_val, Ordering::SeqCst, Ordering::SeqCst)
                .is_ok()
            {
                break;
            }
        }
    }

    /// Records a local change in the sync outbox.
    ///
    /// This should be called after each local mutation to capture the change
    /// for later sync. The Lamport clock is incremented.
    pub fn record_change(
        &self,
        table: &str,
        row_id: &str,
        op: SyncOp,
        data: serde_json::Value,
    ) -> Result<SyncChange> {
        let lamport = self.next_lamport();
        let id = new_id();
        let created_at = chrono::Utc::now().to_rfc3339();
        let data_str = serde_json::to_string(&data)
            .map_err(|e| AppError::Internal(format!("Failed to serialize change data: {e}")))?;

        self.db.execute(
            "INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id, created_at) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            &[
                &id as &dyn rusqlite::types::ToSql,
                &table,
                &row_id,
                &op.as_str(),
                &data_str,
                &lamport,
                &self.device_id,
                &created_at,
            ],
        )?;

        Ok(SyncChange {
            id,
            table: table.to_string(),
            row_id: row_id.to_string(),
            operation: op,
            data,
            lamport_ts: lamport,
            device_id: self.device_id.clone(),
        })
    }

    /// Returns outbox entries for a table with lamport_ts greater than
    /// `since_lamport`, ordered by lamport_ts ascending.
    pub fn get_outbox_since(
        &self,
        table: &str,
        since_lamport: i64,
    ) -> Result<Vec<SyncChange>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(
                "SELECT id, table_name, row_id, operation, data, lamport_ts, device_id \
                 FROM sync_outbox \
                 WHERE table_name = ?1 AND lamport_ts > ?2 \
                 ORDER BY lamport_ts ASC",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare outbox query: {e}")))?;

        let rows = stmt
            .query_map(
                rusqlite::params![table, since_lamport],
                |row| {
                    Ok((
                        row.get::<_, String>(0)?,
                        row.get::<_, String>(1)?,
                        row.get::<_, String>(2)?,
                        row.get::<_, String>(3)?,
                        row.get::<_, Option<String>>(4)?,
                        row.get::<_, i64>(5)?,
                        row.get::<_, String>(6)?,
                    ))
                },
            )
            .map_err(|e| AppError::Storage(format!("Outbox query failed: {e}")))?;

        let mut changes = Vec::new();
        for row in rows {
            let (id, tbl, row_id, op_str, data_str, lamport_ts, device_id) =
                row.map_err(|e| AppError::Storage(format!("Outbox row read failed: {e}")))?;

            let operation = SyncOp::from_str(&op_str).ok_or_else(|| {
                AppError::Storage(format!("Unknown sync operation: {op_str}"))
            })?;

            let data = match data_str {
                Some(s) => serde_json::from_str(&s).unwrap_or(serde_json::Value::Null),
                None => serde_json::Value::Null,
            };

            changes.push(SyncChange {
                id,
                table: tbl,
                row_id,
                operation,
                data,
                lamport_ts,
                device_id,
            });
        }

        Ok(changes)
    }

    /// Returns all outbox entries ordered by lamport_ts ascending.
    pub fn get_all_outbox(&self) -> Result<Vec<SyncChange>> {
        let conn = self.db.conn();
        let mut stmt = conn
            .prepare(
                "SELECT id, table_name, row_id, operation, data, lamport_ts, device_id \
                 FROM sync_outbox ORDER BY lamport_ts ASC",
            )
            .map_err(|e| AppError::Storage(format!("Failed to prepare outbox query: {e}")))?;

        let rows = stmt
            .query_map([], |row| {
                Ok((
                    row.get::<_, String>(0)?,
                    row.get::<_, String>(1)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, String>(3)?,
                    row.get::<_, Option<String>>(4)?,
                    row.get::<_, i64>(5)?,
                    row.get::<_, String>(6)?,
                ))
            })
            .map_err(|e| AppError::Storage(format!("Outbox query failed: {e}")))?;

        let mut changes = Vec::new();
        for row in rows {
            let (id, tbl, row_id, op_str, data_str, lamport_ts, device_id) =
                row.map_err(|e| AppError::Storage(format!("Outbox row read failed: {e}")))?;

            let operation = SyncOp::from_str(&op_str).ok_or_else(|| {
                AppError::Storage(format!("Unknown sync operation: {op_str}"))
            })?;

            let data = match data_str {
                Some(s) => serde_json::from_str(&s).unwrap_or(serde_json::Value::Null),
                None => serde_json::Value::Null,
            };

            changes.push(SyncChange {
                id,
                table: tbl,
                row_id,
                operation,
                data,
                lamport_ts,
                device_id,
            });
        }

        Ok(changes)
    }

    /// Compacts the outbox by deduplicating entries for the same (table, row_id).
    ///
    /// Rules:
    /// - Multiple changes to the same row -> keep only the latest (highest lamport_ts)
    /// - DELETE after INSERT/UPDATE -> keep only the DELETE
    /// - INSERT after DELETE -> keep only the INSERT (row was recreated)
    pub fn compact_outbox(&self) -> Result<usize> {
        let conn = self.db.conn();

        // Find duplicate (table_name, row_id) groups, keeping only the latest.
        let deleted = conn.execute(
            "DELETE FROM sync_outbox WHERE id NOT IN (
                SELECT id FROM (
                    SELECT id, ROW_NUMBER() OVER (
                        PARTITION BY table_name, row_id
                        ORDER BY lamport_ts DESC
                    ) as rn
                    FROM sync_outbox
                    WHERE device_id = ?1
                ) WHERE rn = 1
            ) AND device_id = ?1",
            rusqlite::params![&self.device_id],
        ).map_err(|e| AppError::Storage(format!("Outbox compaction failed: {e}")))?;

        if deleted > 0 {
            tracing::info!("Compacted {deleted} duplicate outbox entries");
        }

        Ok(deleted)
    }

    /// Sends pending outbox changes to a connected peer.
    ///
    /// Reads the peer's cursor for each table, gathers changes since that
    /// cursor, and sends them in a `SyncMessage::Changes` batch. Returns the
    /// number of changes sent.
    pub async fn sync_to_peer(&self, target_device_id: &str) -> Result<usize> {
        // Compact outbox before sending to avoid duplicate/stale entries.
        self.compact_outbox()?;

        // Collect all tables that have outbox entries.
        let tables: Vec<String> = {
            let conn = self.db.conn();
            let mut stmt = conn
                .prepare("SELECT DISTINCT table_name FROM sync_outbox")
                .map_err(|e| AppError::Storage(format!("Failed to query outbox tables: {e}")))?;
            let rows = stmt
                .query_map([], |row| row.get::<_, String>(0))
                .map_err(|e| AppError::Storage(format!("Outbox tables query failed: {e}")))?;
            rows.filter_map(|r| r.ok()).collect()
        };

        let mut all_changes = Vec::new();
        for table in &tables {
            let cursor = self.get_cursor(target_device_id, table)?;
            let changes = self.get_outbox_since(table, cursor)?;
            all_changes.extend(changes);
        }

        if all_changes.is_empty() {
            return Ok(0);
        }

        let count = all_changes.len();
        let message = SyncMessage::Changes(all_changes);
        self.peer_manager.send_raw(
            target_device_id,
            serde_json::to_vec(&message)
                .map_err(|e| AppError::Internal(format!("Serialize failed: {e}")))?,
        ).await?;

        Ok(count)
    }

    /// Applies incoming changes from a remote peer.
    ///
    /// Uses last-writer-wins conflict resolution: if a local outbox entry
    /// exists for the same (table, row_id), the change with the higher
    /// Lamport timestamp wins. Equal timestamps are resolved by comparing
    /// device IDs lexicographically.
    ///
    /// Returns the number of changes actually applied (not skipped due to
    /// conflict resolution).
    pub fn apply_remote_changes(&self, changes: Vec<SyncChange>) -> Result<usize> {
        let mut applied = 0;

        for change in &changes {
            // Merge the Lamport clock.
            self.merge_lamport(change.lamport_ts);

            // Check for conflict: is there a local outbox entry for the same
            // (table, row_id) with a higher lamport_ts?
            let dominated = {
                let conn = self.db.conn();
                let local_ts: Option<i64> = conn
                    .query_row(
                        "SELECT MAX(lamport_ts) FROM sync_outbox \
                         WHERE table_name = ?1 AND row_id = ?2",
                        rusqlite::params![&change.table, &change.row_id],
                        |row| row.get(0),
                    )
                    .unwrap_or(None);

                match local_ts {
                    Some(ts) if ts > change.lamport_ts => true,
                    Some(ts) if ts == change.lamport_ts => {
                        // Tiebreak: higher device_id wins.
                        self.device_id > change.device_id
                    }
                    _ => false,
                }
            };

            if dominated {
                continue; // Local version wins; skip this remote change.
            }

            // Record the remote change into our outbox (so we can relay it).
            let data_str = serde_json::to_string(&change.data).unwrap_or_default();
            let created_at = chrono::Utc::now().to_rfc3339();

            self.db.execute(
                "INSERT OR REPLACE INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id, created_at) \
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                &[
                    &change.id as &dyn rusqlite::types::ToSql,
                    &change.table,
                    &change.row_id,
                    &change.operation.as_str(),
                    &data_str,
                    &change.lamport_ts,
                    &change.device_id,
                    &created_at,
                ],
            )?;

            // Materialize the change into the actual target table.
            if let Err(e) = ChangeMaterializer::apply(&self.db.conn(), change) {
                tracing::warn!(
                    "Failed to materialize change {} for {}.{}: {e}",
                    change.id,
                    change.table,
                    change.row_id,
                );
            }

            applied += 1;
        }

        // Update cursor for the remote device.
        if let Some(last) = changes.last() {
            self.update_cursor(&last.device_id, &last.table, last.lamport_ts)?;
        }

        Ok(applied)
    }

    /// Marks outbox entries as acknowledged up to the given change ID.
    ///
    /// Acknowledged entries can safely be pruned to keep the outbox lean.
    /// This deletes all entries with a lamport_ts <= the lamport_ts of the
    /// acknowledged entry.
    pub fn acknowledge_up_to(&self, last_id: &str) -> Result<()> {
        let conn = self.db.conn();

        // Find the lamport_ts of the acknowledged entry.
        let lamport_ts: Option<i64> = conn
            .query_row(
                "SELECT lamport_ts FROM sync_outbox WHERE id = ?1",
                rusqlite::params![last_id],
                |row| row.get(0),
            )
            .ok();

        if let Some(ts) = lamport_ts {
            conn.execute(
                "DELETE FROM sync_outbox WHERE lamport_ts <= ?1 AND device_id = ?2",
                rusqlite::params![ts, &self.device_id],
            )
            .map_err(|e| AppError::Storage(format!("Failed to prune outbox: {e}")))?;
        }

        Ok(())
    }

    /// Gets the sync cursor (high water mark) for a peer device and table.
    ///
    /// Returns 0 if no cursor exists yet.
    pub fn get_cursor(&self, device_id: &str, table: &str) -> Result<i64> {
        let conn = self.db.conn();
        let result = conn.query_row(
            "SELECT high_water_mark FROM sync_cursors \
             WHERE device_id = ?1 AND table_name = ?2",
            rusqlite::params![device_id, table],
            |row| row.get::<_, i64>(0),
        );

        match result {
            Ok(hwm) => Ok(hwm),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(0),
            Err(e) => Err(AppError::Storage(format!("Failed to read cursor: {e}"))),
        }
    }

    /// Updates the sync cursor for a peer device and table.
    pub fn update_cursor(
        &self,
        device_id: &str,
        table: &str,
        lamport: i64,
    ) -> Result<()> {
        self.db.execute(
            "INSERT INTO sync_cursors (device_id, table_name, high_water_mark) \
             VALUES (?1, ?2, ?3) \
             ON CONFLICT (device_id, table_name) DO UPDATE SET high_water_mark = ?3",
            &[
                &device_id as &dyn rusqlite::types::ToSql,
                &table,
                &lamport,
            ],
        )?;
        Ok(())
    }

    /// Returns a reference to the peer connection manager.
    pub fn peer_manager(&self) -> &Arc<PeerConnectionManager> {
        &self.peer_manager
    }

    /// Returns a reference to the database.
    pub fn db(&self) -> &Arc<Database> {
        &self.db
    }

    /// Generates a full state snapshot for all synced tables.
    /// Returns chunks of (table, rows, chunk_index, total_chunks) tuples,
    /// each containing up to `chunk_size` rows.
    pub fn generate_full_state(
        &self,
        chunk_size: usize,
    ) -> Result<Vec<(String, Vec<serde_json::Value>, u32, u32)>> {
        use super::table_class::TableClassification;

        let mut chunks = Vec::new();

        for table in TableClassification::synced_tables() {
            let conn = self.db.conn();
            let columns = get_columns(&conn, table)?;
            if columns.is_empty() {
                continue;
            }

            let query = format!("SELECT * FROM {table}");
            let mut stmt = conn.prepare(&query).map_err(|e| {
                AppError::Storage(format!(
                    "Failed to prepare snapshot query for {table}: {e}"
                ))
            })?;

            let col_count = stmt.column_count();
            let col_names: Vec<String> = (0..col_count)
                .map(|i| stmt.column_name(i).unwrap_or("?").to_string())
                .collect();

            let rows: Vec<serde_json::Value> = stmt
                .query_map([], |row| {
                    let mut map = serde_json::Map::new();
                    for (i, name) in col_names.iter().enumerate() {
                        let val: rusqlite::types::Value = row.get_unwrap(i);
                        map.insert(name.clone(), rusqlite_to_json(val));
                    }
                    Ok(serde_json::Value::Object(map))
                })
                .map_err(|e| {
                    AppError::Storage(format!("Snapshot query failed for {table}: {e}"))
                })?
                .filter_map(|r| r.ok())
                .collect();

            if rows.is_empty() {
                continue;
            }

            // Split into chunks.
            let total_chunks = ((rows.len() + chunk_size - 1) / chunk_size) as u32;
            for (i, chunk) in rows.chunks(chunk_size).enumerate() {
                chunks.push((table.to_string(), chunk.to_vec(), i as u32, total_chunks));
            }
        }

        Ok(chunks)
    }

    /// Returns the highest _lamport_ts across all synced tables.
    pub fn max_lamport_ts(&self) -> i64 {
        use super::table_class::TableClassification;
        let conn = self.db.conn();
        let mut max_ts: i64 = 0;
        for table in TableClassification::synced_tables() {
            let ts: i64 = conn.query_row(
                &format!("SELECT COALESCE(MAX(_lamport_ts), 0) FROM {table}"),
                [],
                |row| row.get(0),
            ).unwrap_or(0);
            if ts > max_ts { max_ts = ts; }
        }
        max_ts
    }

    /// Generates delta data for a peer: all rows where _lamport_ts > peer_cursor
    /// OR _lamport_ts = 0 (pre-existing data never synced).
    /// Returns (table_name, rows_json) pairs.
    pub fn generate_delta(&self, peer_cursor: i64) -> Result<Vec<(String, Vec<serde_json::Value>)>> {
        use super::table_class::TableClassification;

        let mut result = Vec::new();

        for table in TableClassification::synced_tables() {
            let conn = self.db.conn();

            // Get rows that are newer than peer's cursor OR never synced (_lamport_ts = 0).
            let query = if peer_cursor == 0 {
                // First sync: send everything.
                format!("SELECT * FROM {table}")
            } else {
                // Delta: only rows changed since peer_cursor or never synced.
                format!("SELECT * FROM {table} WHERE _lamport_ts > {peer_cursor} OR _lamport_ts = 0")
            };

            let mut stmt = conn.prepare(&query)
                .map_err(|e| AppError::Storage(format!("Delta query failed for {table}: {e}")))?;

            let col_count = stmt.column_count();
            let col_names: Vec<String> = (0..col_count)
                .map(|i| stmt.column_name(i).unwrap_or("?").to_string())
                .collect();

            let rows: Vec<serde_json::Value> = stmt.query_map([], |row| {
                let mut map = serde_json::Map::new();
                for (i, name) in col_names.iter().enumerate() {
                    let val: rusqlite::types::Value = row.get_unwrap(i);
                    map.insert(name.clone(), rusqlite_to_json(val));
                }
                Ok(serde_json::Value::Object(map))
            })
            .map_err(|e| AppError::Storage(format!("Delta query failed for {table}: {e}")))?
            .filter_map(|r| r.ok())
            .collect();

            if !rows.is_empty() {
                result.push((table.to_string(), rows));
            }
        }

        Ok(result)
    }

    /// Returns all tombstones as SyncChange delete operations.
    pub fn get_tombstones(&self) -> Result<Vec<SyncChange>> {
        let conn = self.db.conn();
        let mut stmt = conn.prepare(
            "SELECT table_name, row_id, device_id, lamport_ts FROM sync_tombstones"
        ).map_err(|e| AppError::Storage(format!("Failed to query tombstones: {e}")))?;

        let rows = stmt.query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, i64>(3)?,
            ))
        }).map_err(|e| AppError::Storage(format!("Tombstone query failed: {e}")))?;

        let mut changes = Vec::new();
        for row in rows {
            let (table, row_id, device_id, lamport_ts) = row.map_err(|e| AppError::Storage(format!("Tombstone row failed: {e}")))?;
            changes.push(SyncChange {
                id: crate::util::new_id(),
                table: table.clone(),
                row_id: row_id.clone(),
                operation: SyncOp::Delete,
                data: serde_json::json!({"id": row_id}),
                lamport_ts,
                device_id,
            });
        }
        Ok(changes)
    }

    /// Exchanges cursors and syncs missing changes with a peer (reconciliation).
    ///
    /// This is the full reconciliation flow used when a peer reconnects:
    /// 1. Gather our cursors for all known tables.
    /// 2. Send a `CursorExchange` to the peer.
    /// 3. Send all changes the peer is missing based on their cursor.
    pub async fn reconcile(&self, target_device_id: &str) -> Result<()> {
        // Gather all tables that have outbox entries.
        let tables: Vec<String> = {
            let conn = self.db.conn();
            let mut stmt = conn
                .prepare("SELECT DISTINCT table_name FROM sync_outbox")
                .map_err(|e| AppError::Storage(format!("Failed to query tables: {e}")))?;
            let rows = stmt
                .query_map([], |row| row.get::<_, String>(0))
                .map_err(|e| AppError::Storage(format!("Tables query failed: {e}")))?;
            rows.filter_map(|r| r.ok()).collect()
        };

        // Build cursor exchange.
        let mut cursors = std::collections::HashMap::new();
        for table in &tables {
            let cursor = self.get_cursor(target_device_id, table)?;
            cursors.insert(table.clone(), cursor);
        }

        // Send cursor exchange.
        let cursor_msg = SyncMessage::CursorExchange(cursors.clone());
        self.peer_manager.send_raw(
            target_device_id,
            serde_json::to_vec(&cursor_msg)
                .map_err(|e| AppError::Internal(format!("Serialize failed: {e}")))?,
        ).await?;

        // Send all changes the peer is missing.
        let mut all_changes = Vec::new();
        for table in &tables {
            let cursor = cursors.get(table.as_str()).copied().unwrap_or(0);
            let changes = self.get_outbox_since(table, cursor)?;
            all_changes.extend(changes);
        }

        if !all_changes.is_empty() {
            let changes_msg = SyncMessage::Changes(all_changes);
            self.peer_manager.send_raw(
                target_device_id,
                serde_json::to_vec(&changes_msg)
                    .map_err(|e| AppError::Internal(format!("Serialize failed: {e}")))?,
            ).await?;
        }

        Ok(())
    }
}

/// Converts a rusqlite `Value` into a `serde_json::Value`.
fn rusqlite_to_json(val: rusqlite::types::Value) -> serde_json::Value {
    match val {
        rusqlite::types::Value::Null => serde_json::Value::Null,
        rusqlite::types::Value::Integer(i) => serde_json::Value::Number(i.into()),
        rusqlite::types::Value::Real(f) => serde_json::json!(f),
        rusqlite::types::Value::Text(s) => serde_json::Value::String(s),
        rusqlite::types::Value::Blob(b) => serde_json::Value::String(hex::encode(b)),
    }
}

/// Returns the column names for the given table using `PRAGMA table_info`.
fn get_columns(conn: &rusqlite::Connection, table: &str) -> Result<Vec<String>> {
    let mut stmt = conn
        .prepare(&format!("PRAGMA table_info({table})"))
        .map_err(|e| AppError::Storage(format!("PRAGMA failed for {table}: {e}")))?;
    let cols = stmt
        .query_map([], |row| row.get::<_, String>(1))
        .map_err(|e| AppError::Storage(format!("Column query failed for {table}: {e}")))?
        .filter_map(|r| r.ok())
        .collect();
    Ok(cols)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::sync::message::SyncOp;

    /// Helper: build a `SyncEngine` backed by an in-memory database.
    /// The peer manager is constructed with a dummy `SignalService`.
    fn test_engine(device_id: &str) -> SyncEngine {
        let db = Arc::new(Database::open_in_memory().expect("in-memory db"));

        // Build a minimal SignalService for PeerConnectionManager.
        let identity_key_pair =
            libsignal_protocol::IdentityKeyPair::generate(&mut rand::rng());
        let signal = Arc::new(tokio::sync::Mutex::new(
            crate::signal::protocol::SignalService::new(
                db.conn_arc().clone(),
                1,
                identity_key_pair,
            ),
        ));
        let peer_manager = Arc::new(PeerConnectionManager::new(signal));

        SyncEngine::new(db, peer_manager, device_id)
    }

    #[test]
    fn compact_outbox_keeps_latest_per_row() {
        let engine = test_engine("device-A");

        // Insert three changes for the same (table, row_id).
        // record_change auto-increments lamport, so order = 1, 2, 3.
        engine
            .record_change("sessions", "row-1", SyncOp::Insert, serde_json::json!({"v": 1}))
            .unwrap();
        engine
            .record_change("sessions", "row-1", SyncOp::Update, serde_json::json!({"v": 2}))
            .unwrap();
        engine
            .record_change("sessions", "row-1", SyncOp::Update, serde_json::json!({"v": 3}))
            .unwrap();

        // Also insert a change for a different row (should be untouched).
        engine
            .record_change("sessions", "row-2", SyncOp::Insert, serde_json::json!({"v": 1}))
            .unwrap();

        // Before compaction: 4 entries total.
        let all = engine.get_all_outbox().unwrap();
        assert_eq!(all.len(), 4);

        // Compact.
        let deleted = engine.compact_outbox().unwrap();
        assert_eq!(deleted, 2, "should remove 2 duplicates for row-1");

        // After compaction: 2 entries (latest for row-1 + row-2).
        let remaining = engine.get_all_outbox().unwrap();
        assert_eq!(remaining.len(), 2);

        // The surviving row-1 entry should be the latest (lamport_ts=3, v=3).
        let row1 = remaining.iter().find(|c| c.row_id == "row-1").unwrap();
        assert_eq!(row1.lamport_ts, 3);
        assert_eq!(row1.data["v"], 3);
        assert_eq!(row1.operation, SyncOp::Update);

        // row-2 is untouched.
        let row2 = remaining.iter().find(|c| c.row_id == "row-2").unwrap();
        assert_eq!(row2.lamport_ts, 4);
    }

    #[test]
    fn compact_outbox_delete_after_insert_keeps_delete() {
        let engine = test_engine("device-B");

        // INSERT then DELETE for the same row.
        engine
            .record_change("sessions", "row-1", SyncOp::Insert, serde_json::json!({"v": 1}))
            .unwrap();
        engine
            .record_change("sessions", "row-1", SyncOp::Delete, serde_json::Value::Null)
            .unwrap();

        let deleted = engine.compact_outbox().unwrap();
        assert_eq!(deleted, 1);

        let remaining = engine.get_all_outbox().unwrap();
        assert_eq!(remaining.len(), 1);
        assert_eq!(remaining[0].operation, SyncOp::Delete);
    }

    #[test]
    fn compact_outbox_noop_when_no_duplicates() {
        let engine = test_engine("device-C");

        engine
            .record_change("sessions", "row-1", SyncOp::Insert, serde_json::json!({}))
            .unwrap();
        engine
            .record_change("sessions", "row-2", SyncOp::Insert, serde_json::json!({}))
            .unwrap();

        let deleted = engine.compact_outbox().unwrap();
        assert_eq!(deleted, 0);

        assert_eq!(engine.get_all_outbox().unwrap().len(), 2);
    }
}
