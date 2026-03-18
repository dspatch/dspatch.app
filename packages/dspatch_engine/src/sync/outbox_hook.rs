// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SQLite trigger-based outbox capture for synced tables.
//!
//! Generates AFTER INSERT/UPDATE/DELETE triggers on each synced table that
//! automatically record changes to `sync_outbox` with full row data.
//! This replaces the previous `update_hook` approach which could not capture
//! row data and conflicted with `TableChangeTracker`.

use crate::util::error::AppError;
use crate::util::result::Result;

use super::table_class::TableClassification;

/// Installs sync outbox triggers on all synced tables.
pub fn install_outbox_triggers(conn: &rusqlite::Connection) -> Result<()> {
    for table in TableClassification::synced_tables() {
        install_triggers_for_table(conn, table)?;
    }
    tracing::info!(
        "Installed sync outbox triggers on {} tables",
        TableClassification::synced_tables().len()
    );
    Ok(())
}

/// Sets the device ID used by triggers for outbox attribution.
pub fn set_sync_device_id(conn: &rusqlite::Connection, device_id: &str) -> Result<()> {
    conn.execute(
        "UPDATE sync_config SET device_id = ?1 WHERE id = 1",
        rusqlite::params![device_id],
    )
    .map_err(|e| AppError::Storage(format!("Failed to set sync device_id: {e}")))?;
    Ok(())
}

/// Initializes the Lamport clock from the current max in the outbox.
pub fn bootstrap_lamport_clock(conn: &rusqlite::Connection) -> Result<()> {
    conn.execute(
        "UPDATE sync_lamport SET ts = COALESCE((SELECT MAX(lamport_ts) FROM sync_outbox), 0) WHERE id = 1",
        [],
    )
    .map_err(|e| AppError::Storage(format!("Failed to bootstrap lamport clock: {e}")))?;
    Ok(())
}

fn install_triggers_for_table(conn: &rusqlite::Connection, table: &str) -> Result<()> {
    let col_info = get_table_column_info(conn, table)?;
    if col_info.is_empty() {
        tracing::warn!("Table {table} has no columns — skipping trigger install");
        return Ok(());
    }

    let pk_col = col_info
        .iter()
        .find(|c| c.is_pk)
        .map(|c| c.name.clone())
        .ok_or_else(|| AppError::Storage(format!("Table {table} has no primary key column")))?;
    let json_expr_new = build_json_object_expr(&col_info, "NEW");
    let json_expr_old_id = format!("json_object('{pk_col}', OLD.{pk_col})");

    // Drop existing triggers (idempotent reinstall).
    conn.execute_batch(&format!(
        "DROP TRIGGER IF EXISTS sync_outbox_insert_{table};\n\
         DROP TRIGGER IF EXISTS sync_outbox_update_{table};\n\
         DROP TRIGGER IF EXISTS sync_outbox_delete_{table};"
    ))
    .map_err(|e| AppError::Storage(format!("Failed to drop triggers for {table}: {e}")))?;

    let uuid_expr = "lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || \
                     substr(hex(randomblob(2)),2) || '-' || \
                     substr('89ab', abs(random()) % 4 + 1, 1) || \
                     substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6)))";

    // AFTER INSERT
    conn.execute_batch(&format!(
        "CREATE TRIGGER sync_outbox_insert_{table} AFTER INSERT ON {table}\n\
         WHEN (SELECT device_id FROM sync_config WHERE id = 1) != 'local'\n\
         BEGIN\n\
           UPDATE sync_lamport SET ts = ts + 1 WHERE id = 1;\n\
           INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id)\n\
           VALUES (\n\
             {uuid_expr},\n\
             '{table}',\n\
             NEW.{pk_col},\n\
             'insert',\n\
             {json_expr_new},\n\
             (SELECT ts FROM sync_lamport WHERE id = 1),\n\
             (SELECT device_id FROM sync_config WHERE id = 1)\n\
           );\n\
         END;"
    ))
    .map_err(|e| AppError::Storage(format!("Failed to create INSERT trigger for {table}: {e}")))?;

    // AFTER UPDATE
    conn.execute_batch(&format!(
        "CREATE TRIGGER sync_outbox_update_{table} AFTER UPDATE ON {table}\n\
         WHEN (SELECT device_id FROM sync_config WHERE id = 1) != 'local'\n\
         BEGIN\n\
           UPDATE sync_lamport SET ts = ts + 1 WHERE id = 1;\n\
           INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id)\n\
           VALUES (\n\
             {uuid_expr},\n\
             '{table}',\n\
             NEW.{pk_col},\n\
             'update',\n\
             {json_expr_new},\n\
             (SELECT ts FROM sync_lamport WHERE id = 1),\n\
             (SELECT device_id FROM sync_config WHERE id = 1)\n\
           );\n\
         END;"
    ))
    .map_err(|e| AppError::Storage(format!("Failed to create UPDATE trigger for {table}: {e}")))?;

    // AFTER DELETE
    conn.execute_batch(&format!(
        "CREATE TRIGGER sync_outbox_delete_{table} AFTER DELETE ON {table}\n\
         WHEN (SELECT device_id FROM sync_config WHERE id = 1) != 'local'\n\
         BEGIN\n\
           UPDATE sync_lamport SET ts = ts + 1 WHERE id = 1;\n\
           INSERT INTO sync_outbox (id, table_name, row_id, operation, data, lamport_ts, device_id)\n\
           VALUES (\n\
             {uuid_expr},\n\
             '{table}',\n\
             OLD.{pk_col},\n\
             'delete',\n\
             {json_expr_old_id},\n\
             (SELECT ts FROM sync_lamport WHERE id = 1),\n\
             (SELECT device_id FROM sync_config WHERE id = 1)\n\
           );\n\
           INSERT OR REPLACE INTO sync_tombstones (table_name, row_id, device_id, lamport_ts)\n\
           VALUES (\n\
             '{table}',\n\
             OLD.{pk_col},\n\
             (SELECT device_id FROM sync_config WHERE id = 1),\n\
             (SELECT ts FROM sync_lamport WHERE id = 1)\n\
           );\n\
         END;"
    ))
    .map_err(|e| AppError::Storage(format!("Failed to create DELETE trigger for {table}: {e}")))?;

    Ok(())
}

struct ColumnInfo {
    name: String,
    col_type: String,
    is_pk: bool,
}

impl ColumnInfo {
    fn is_blob(&self) -> bool {
        self.col_type.eq_ignore_ascii_case("BLOB")
    }
}

fn build_json_object_expr(columns: &[ColumnInfo], prefix: &str) -> String {
    let pairs: Vec<String> = columns
        .iter()
        .map(|col| {
            let name = &col.name;
            if col.is_blob() {
                // BLOB values cannot be stored in JSON; encode as hex string.
                format!("'{name}', hex({prefix}.{name})")
            } else {
                format!("'{name}', {prefix}.{name}")
            }
        })
        .collect();
    format!("json_object({})", pairs.join(", "))
}

/// Returns column metadata from PRAGMA table_info.
fn get_table_column_info(conn: &rusqlite::Connection, table: &str) -> Result<Vec<ColumnInfo>> {
    let mut stmt = conn
        .prepare(&format!("PRAGMA table_info({table})"))
        .map_err(|e| AppError::Storage(format!("PRAGMA table_info failed for {table}: {e}")))?;

    let columns: Vec<ColumnInfo> = stmt
        .query_map([], |row| {
            let name: String = row.get(1)?;
            let col_type: String = row.get(2)?;
            let pk: i32 = row.get(5)?;
            Ok(ColumnInfo {
                name,
                col_type,
                is_pk: pk > 0,
            })
        })
        .map_err(|e| AppError::Storage(format!("Failed to read columns for {table}: {e}")))?
        .filter_map(|r| r.ok())
        .collect();

    Ok(columns)
}
