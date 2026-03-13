// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Database lifecycle manager.
//!
//! Resolves the correct database path based on authentication state and
//! coordinates opening with health checks and encryption key management.
//!
//! Ported from `database_manager.dart`.

use std::path::{Path, PathBuf};

use crate::util::result::Result;

use super::health::{self, DbHealthStatus};
use super::key_manager::DatabaseKeyManager;
use super::Database;

/// Represents the current state of the database lifecycle.
pub enum DatabaseState {
    /// The database is currently being opened or checked.
    Loading,

    /// The database is open and ready for use.
    Ready {
        database: Database,
        health_status: DbHealthStatus,
    },

    /// An anonymous database exists and can be migrated to a per-user
    /// database.
    MigrationAvailable {
        anonymous_db_path: PathBuf,
        user_db_path: PathBuf,
    },
}

impl std::fmt::Debug for DatabaseState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Loading => write!(f, "DatabaseState::Loading"),
            Self::Ready { health_status, .. } => f
                .debug_struct("DatabaseState::Ready")
                .field("health_status", health_status)
                .finish(),
            Self::MigrationAvailable {
                anonymous_db_path,
                user_db_path,
            } => f
                .debug_struct("DatabaseState::MigrationAvailable")
                .field("anonymous_db_path", anonymous_db_path)
                .field("user_db_path", user_db_path)
                .finish(),
        }
    }
}

/// Manages the database lifecycle based on authentication state.
///
/// Opens the correct database (anonymous or per-user) depending on the
/// current auth state.  When a user signs in and an anonymous database exists,
/// offers migration to the per-user database.
pub struct DatabaseManager {
    key_manager: DatabaseKeyManager,
    base_path: PathBuf,
}

impl DatabaseManager {
    pub fn new(key_manager: DatabaseKeyManager, base_path: PathBuf) -> Self {
        Self {
            key_manager,
            base_path,
        }
    }

    /// Resolves the database file path for a given auth state.
    ///
    /// - Anonymous / undetermined: `<base_path>/dspatch/dspatch.db`
    /// - Connected with username:  `<base_path>/dspatch/<hash>/dspatch.db`
    pub fn resolve_database_path(base_path: &Path, username: Option<&str>) -> PathBuf {
        match username {
            Some(name) => {
                let hash = DatabaseKeyManager::hash_username(name);
                base_path.join("dspatch").join(hash).join("dspatch.db")
            }
            None => base_path.join("dspatch").join("dspatch.db"),
        }
    }

    /// Returns `true` if migration should be offered: an anonymous DB exists
    /// but no user DB yet.
    pub fn should_offer_migration(anonymous_db_path: &Path, user_db_path: &Path) -> bool {
        anonymous_db_path.exists() && !user_db_path.exists()
    }

    /// Opens the appropriate database for the given authentication state.
    ///
    /// If `username` is `Some` and an anonymous database exists without a
    /// per-user database, returns `DatabaseState::MigrationAvailable` instead
    /// of opening.
    pub fn open_database(&self, username: Option<&str>) -> Result<DatabaseState> {
        let db_path = Self::resolve_database_path(&self.base_path, username);

        // For connected users, check if migration is available.
        if let Some(name) = username {
            let anon_path = Self::resolve_database_path(&self.base_path, None);

            if Self::should_offer_migration(&anon_path, &db_path) {
                return Ok(DatabaseState::MigrationAvailable {
                    anonymous_db_path: anon_path,
                    user_db_path: db_path,
                });
            }

            // Resolve encryption key for this user.
            let hash = DatabaseKeyManager::hash_username(name);
            let passphrase = self.key_manager.get_or_create_key(Some(&hash))?;

            let (status, database) = health::open_checked(&db_path, Some(&passphrase))?;
            return Ok(DatabaseState::Ready {
                database,
                health_status: status,
            });
        }

        // Anonymous — use anonymous key.
        let passphrase = self.key_manager.get_or_create_key(None)?;
        let (status, database) = health::open_checked(&db_path, Some(&passphrase))?;
        Ok(DatabaseState::Ready {
            database,
            health_status: status,
        })
    }

    /// Opens (or creates) the per-user database directly, bypassing the
    /// anonymous-DB migration check. Used by `skip_migration()`.
    pub fn open_user_database(&self, username: &str) -> Result<DatabaseState> {
        let db_path = Self::resolve_database_path(&self.base_path, Some(username));

        // Ensure the per-user directory exists.
        if let Some(parent) = db_path.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                crate::util::error::AppError::Internal(format!(
                    "Failed to create per-user DB directory: {e}"
                ))
            })?;
        }

        let hash = DatabaseKeyManager::hash_username(username);
        let passphrase = self.key_manager.get_or_create_key(Some(&hash))?;
        let (status, database) = health::open_checked(&db_path, Some(&passphrase))?;
        Ok(DatabaseState::Ready {
            database,
            health_status: status,
        })
    }
}

impl std::fmt::Debug for DatabaseManager {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("DatabaseManager")
            .field("base_path", &self.base_path)
            .finish()
    }
}
