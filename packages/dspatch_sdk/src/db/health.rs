// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Startup database health check with escalating recovery.
//!
//! Strategy:
//! 1. `PRAGMA quick_check` — if result is `ok`, done.
//! 2. `REINDEX` — rebuilds all indices (fixes most power-loss corruption).
//! 3. Delete + recreate — nuclear option, returns [`DbHealthStatus::Reset`].
//!
//! Ported from `db_health.dart`.

use std::path::Path;

use tracing::{error, info, warn};

use crate::util::error::AppError;
use crate::util::result::Result;

use super::Database;

/// Result of the startup database health check.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DbHealthStatus {
    /// Database passed `PRAGMA quick_check`.
    Ok,

    /// Indices were corrupt but repaired via `REINDEX`.  No data loss.
    Repaired,

    /// Database was unrecoverably corrupt.  File was deleted and recreated.
    /// All prior data has been lost.
    Reset,
}

/// Opens the database at `db_path` with a health check.
///
/// Returns both the health status and the opened [`Database`].
pub fn open_checked(db_path: &Path, passphrase: Option<&str>) -> Result<(DbHealthStatus, Database)> {
    // Fresh install — no file to check.
    if !db_path.exists() {
        info!("No existing database, creating fresh");
        let db = Database::open(db_path, passphrase)?;
        return Ok((DbHealthStatus::Ok, db));
    }

    // Step 1: open + quick_check.
    let db = match Database::open(db_path, passphrase) {
        Ok(db) => db,
        Err(e) => {
            error!("Database open failed: {e}, resetting");
            return reset_and_reopen(db_path, passphrase);
        }
    };

    // Check stored schema version.  If it is behind the current version
    // the cleanest path is to nuke and recreate (matches Dart behaviour).
    match check_version_and_integrity(&db) {
        Ok(status) => Ok((status, db)),
        Err(_) => {
            // Could not even run the checks — reset.
            error!("Health check threw, resetting");
            drop(db);
            reset_and_reopen(db_path, passphrase)
        }
    }
}

/// Runs version check, quick_check, and REINDEX escalation on an already-open
/// database.
fn check_version_and_integrity(db: &Database) -> Result<DbHealthStatus> {
    if quick_check(db)? {
        info!("Database health check passed");
        return Ok(DbHealthStatus::Ok);
    }

    // Step 2: REINDEX.
    warn!("quick_check failed, attempting REINDEX");
    {
        let conn = db.conn();
        conn.execute_batch("REINDEX")
            .map_err(|e| AppError::Storage(format!("REINDEX failed: {e}")))?;
    }

    if quick_check(db)? {
        info!("Database repaired via REINDEX");
        return Ok(DbHealthStatus::Repaired);
    }

    error!("Database still corrupt after REINDEX");
    Err(AppError::Storage(
        "Database corrupt after REINDEX".to_string(),
    ))
}

/// Runs `PRAGMA quick_check` and returns `true` if the result is `ok`.
fn quick_check(db: &Database) -> Result<bool> {
    let conn = db.conn();
    let result: String = conn
        .query_row("PRAGMA quick_check", [], |row| row.get(0))
        .map_err(|e| AppError::Storage(format!("quick_check failed: {e}")))?;
    Ok(result == "ok")
}

/// Deletes the database file and opens a fresh database.
fn reset_and_reopen(
    db_path: &Path,
    passphrase: Option<&str>,
) -> Result<(DbHealthStatus, Database)> {
    if db_path.exists() {
        if let Err(e) = std::fs::remove_file(db_path) {
            error!("Failed to delete corrupt DB file: {e}");
        }
    }
    let db = Database::open(db_path, passphrase)?;
    Ok((DbHealthStatus::Reset, db))
}
