// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

pub mod col;
pub mod dao;
pub mod health;
pub mod key_manager;
pub mod manager;
pub mod migrations;
pub mod optional_ext;
pub mod reactive;
pub mod schema;

use std::path::Path;
use std::sync::{Arc, Mutex};

use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

use self::migrations::{create_tables, run_migrations, SCHEMA_VERSION};
use self::reactive::TableChangeTracker;

/// Core database wrapper providing a connection, change tracking, and schema
/// management.
///
/// All access to the underlying SQLite connection is serialised through an
/// `Arc<Mutex<Connection>>` so that the database can be shared across threads
/// and used from async contexts.
#[allow(missing_debug_implementations)]
pub struct Database {
    conn: Arc<Mutex<Connection>>,
    tracker: Arc<TableChangeTracker>,
}

impl Database {
    /// Opens (or creates) a database at `path`.
    ///
    /// If `passphrase` is provided the database is encrypted via SQLCipher's
    /// `PRAGMA key`. Schema creation and migrations are applied automatically.
    pub fn open(path: &Path, passphrase: Option<&str>) -> Result<Self> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                AppError::Storage(format!("Failed to create database directory: {e}"))
            })?;
        }

        #[allow(unused_mut)]
        let mut conn = Connection::open(path).map_err(|e| {
            AppError::Storage(format!("Failed to open database at {}: {e}", path.display()))
        })?;

        if let Some(phrase) = passphrase {
            let escaped = phrase.replace('\'', "''");
            conn.execute_batch(&format!("PRAGMA key = '{escaped}';"))
                .map_err(|e| AppError::Storage(format!("Failed to set encryption key: {e}")))?;
        }

        Self::init(conn)
    }

    /// Creates an in-memory database — useful for tests.
    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()
            .map_err(|e| AppError::Storage(format!("Failed to open in-memory database: {e}")))?;
        Self::init(conn)
    }

    /// Common initialisation: schema creation, migrations, hook installation.
    fn init(mut conn: Connection) -> Result<Self> {
        // Enable WAL mode for better concurrent read performance.
        conn.execute_batch("PRAGMA journal_mode = WAL;")
            .map_err(|e| AppError::Storage(format!("Failed to set WAL mode: {e}")))?;

        // Read stored schema version (SQLite user_version pragma).
        let stored_version: i32 = conn
            .pragma_query_value(None, "user_version", |row| row.get(0))
            .unwrap_or(0);

        if stored_version == 0 {
            // Fresh database — create all tables and set the version.
            create_tables(&conn)?;
            conn.pragma_update(None, "user_version", SCHEMA_VERSION)
                .map_err(|e| AppError::Storage(format!("Failed to set schema version: {e}")))?;
        } else if stored_version < SCHEMA_VERSION {
            run_migrations(&conn, stored_version)?;
            conn.pragma_update(None, "user_version", SCHEMA_VERSION)
                .map_err(|e| AppError::Storage(format!("Failed to set schema version: {e}")))?;
        }

        let tracker = Arc::new(TableChangeTracker::new());
        tracker.install_hook(&mut conn);

        Ok(Self {
            conn: Arc::new(Mutex::new(conn)),
            tracker,
        })
    }

    /// Executes a SQL statement with parameters and returns the number of
    /// affected rows.
    pub fn execute(&self, sql: &str, params: &[&dyn rusqlite::types::ToSql]) -> Result<usize> {
        let conn = self.conn.lock().map_err(|e| {
            AppError::Storage(format!("Failed to acquire database lock: {e}"))
        })?;
        conn.execute(sql, params).map_err(|e| {
            AppError::Storage(format!("SQL execution failed: {e}"))
        })
    }

    /// Returns a guard to the underlying connection for direct use.
    pub fn conn(&self) -> std::sync::MutexGuard<'_, Connection> {
        self.conn.lock().expect("database lock poisoned")
    }

    /// Returns a reference to the change tracker (for building reactive
    /// queries).
    pub fn tracker(&self) -> &Arc<TableChangeTracker> {
        &self.tracker
    }

    /// Returns the shared connection handle (for `watch_query`).
    pub fn conn_arc(&self) -> &Arc<Mutex<Connection>> {
        &self.conn
    }
}
