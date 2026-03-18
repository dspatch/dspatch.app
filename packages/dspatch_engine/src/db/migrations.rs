// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Schema versioning and migration logic.
//!
//! Version history (mirrors Dart SDK `app_database.dart`):
//!   v1 → initial schema (all 15 tables minus later additions)
//!   v2 → add agent_messages.sender_name
//!   v3 → add workspace_agents.chain_json, agent_templates.readme
//!   v4 → drop agent_messages.agent_key
//!   v5 → drop agent_messages.is_partial
//!   v6 → add agent_activity_events.content
//!   v7 → add agent_templates.fields_json
//!   v8 → add Signal Protocol key stores
//!   v9 → add sync_outbox and sync_cursors tables for P2P sync
//!   v10 → rename agent_templates → agent_providers; create new agent_templates for config presets
//!   v11 → add ephemeral state tables (agent_instance_states, agent_connection_status, container_health, workspace_run_status)
//!   v12 → add signal_kyber_prekeys
//!   v13 → add performance indexes on foreign keys and filtered columns
//!   v14 → add sync_lamport and sync_config tables for trigger-based outbox
//!   v15 → add sync_tombstones table for soft deletes

use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

use super::schema::ALL_TABLES;

/// Current schema version. Must match the Dart SDK's `schemaVersion`.
pub const SCHEMA_VERSION: i32 = 15;

/// Creates all tables from scratch (fresh database, version 0 → current).
pub fn create_tables(conn: &Connection) -> Result<()> {
    for ddl in ALL_TABLES {
        conn.execute_batch(ddl)
            .map_err(|e| AppError::Storage(format!("Failed to create table: {e}")))?;
    }
    Ok(())
}

/// Runs incremental migrations from `from_version` up to `SCHEMA_VERSION`.
///
/// Each migration step matches the Dart SDK's `MigrationStrategy.onUpgrade`.
pub fn run_migrations(conn: &Connection, from_version: i32) -> Result<()> {
    if from_version < 2 {
        conn.execute_batch("ALTER TABLE agent_messages ADD COLUMN sender_name TEXT;")
            .map_err(|e| AppError::Storage(format!("Migration v2 failed: {e}")))?;
    }
    if from_version < 3 {
        conn.execute_batch(
            "ALTER TABLE workspace_agents ADD COLUMN chain_json TEXT NOT NULL DEFAULT '[]';",
        )
        .map_err(|e| AppError::Storage(format!("Migration v3 (chain_json) failed: {e}")))?;

        conn.execute_batch("ALTER TABLE agent_templates ADD COLUMN readme TEXT;")
            .map_err(|e| AppError::Storage(format!("Migration v3 (readme) failed: {e}")))?;
    }
    if from_version < 4 {
        conn.execute_batch("ALTER TABLE agent_messages DROP COLUMN agent_key;")
            .map_err(|e| AppError::Storage(format!("Migration v4 failed: {e}")))?;
    }
    if from_version < 5 {
        conn.execute_batch("ALTER TABLE agent_messages DROP COLUMN is_partial;")
            .map_err(|e| AppError::Storage(format!("Migration v5 failed: {e}")))?;
    }
    if from_version < 6 {
        conn.execute_batch("ALTER TABLE agent_activity_events ADD COLUMN content TEXT;")
            .map_err(|e| AppError::Storage(format!("Migration v6 failed: {e}")))?;
    }
    if from_version < 7 {
        conn.execute_batch(
            "ALTER TABLE agent_templates ADD COLUMN fields_json TEXT NOT NULL DEFAULT '{}';",
        )
        .map_err(|e| AppError::Storage(format!("Migration v7 failed: {e}")))?;
    }
    if from_version < 8 {
        conn.execute_batch(super::schema::CREATE_SIGNAL_IDENTITIES)
            .map_err(|e| AppError::Storage(format!("Migration v8 (signal_identities) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_SIGNAL_PREKEYS)
            .map_err(|e| AppError::Storage(format!("Migration v8 (signal_prekeys) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_SIGNAL_SIGNED_PREKEYS)
            .map_err(|e| AppError::Storage(format!("Migration v8 (signal_signed_prekeys) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_SIGNAL_SESSIONS)
            .map_err(|e| AppError::Storage(format!("Migration v8 (signal_sessions) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_SIGNAL_SENDER_KEYS)
            .map_err(|e| AppError::Storage(format!("Migration v8 (signal_sender_keys) failed: {e}")))?;
    }
    if from_version < 9 {
        conn.execute_batch(super::schema::CREATE_SYNC_OUTBOX)
            .map_err(|e| AppError::Storage(format!("Migration v9 (sync_outbox) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_SYNC_CURSORS)
            .map_err(|e| AppError::Storage(format!("Migration v9 (sync_cursors) failed: {e}")))?;
    }
    if from_version < 10 {
        // Rename old agent_templates (provider definitions) to agent_providers.
        conn.execute_batch("ALTER TABLE agent_templates RENAME TO agent_providers;")
            .map_err(|e| AppError::Storage(format!("Migration v10 (rename agent_templates → agent_providers) failed: {e}")))?;

        // Create new agent_templates table for lightweight config presets.
        conn.execute_batch(super::schema::CREATE_AGENT_TEMPLATES)
            .map_err(|e| AppError::Storage(format!("Migration v10 (create agent_templates) failed: {e}")))?;
    }
    if from_version < 11 {
        conn.execute_batch(super::schema::CREATE_AGENT_INSTANCE_STATES)
            .map_err(|e| AppError::Storage(format!("Migration v11 (agent_instance_states) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_AGENT_CONNECTION_STATUS)
            .map_err(|e| AppError::Storage(format!("Migration v11 (agent_connection_status) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_CONTAINER_HEALTH)
            .map_err(|e| AppError::Storage(format!("Migration v11 (container_health) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_WORKSPACE_RUN_STATUS)
            .map_err(|e| AppError::Storage(format!("Migration v11 (workspace_run_status) failed: {e}")))?;
    }
    if from_version < 12 {
        conn.execute_batch(super::schema::CREATE_SIGNAL_KYBER_PREKEYS)
            .map_err(|e| AppError::Storage(format!("Migration v12 (signal_kyber_prekeys) failed: {e}")))?;
    }
    if from_version < 13 {
        // Performance indexes on high-query foreign keys and filtered columns.
        conn.execute_batch(
            "CREATE INDEX IF NOT EXISTS idx_agent_messages_run_instance ON agent_messages(run_id, instance_id);
             CREATE INDEX IF NOT EXISTS idx_agent_activity_events_run_instance ON agent_activity_events(run_id, instance_id);
             CREATE INDEX IF NOT EXISTS idx_agent_logs_run_instance ON agent_logs(run_id, instance_id);
             CREATE INDEX IF NOT EXISTS idx_agent_logs_run_timestamp ON agent_logs(run_id, timestamp);
             CREATE INDEX IF NOT EXISTS idx_agent_usage_records_run_instance ON agent_usage_records(run_id, instance_id);
             CREATE INDEX IF NOT EXISTS idx_workspace_inquiries_run_status ON workspace_inquiries(run_id, status);
             CREATE INDEX IF NOT EXISTS idx_workspace_agents_run ON workspace_agents(run_id);
             CREATE INDEX IF NOT EXISTS idx_workspace_runs_workspace_started ON workspace_runs(workspace_id, started_at DESC);
             CREATE INDEX IF NOT EXISTS idx_agent_files_run_instance ON agent_files(run_id, instance_id);
             CREATE INDEX IF NOT EXISTS idx_instance_results_run ON instance_results(run_id);"
        )
        .map_err(|e| AppError::Storage(format!("Migration v13 (performance indexes) failed: {e}")))?;
    }
    if from_version < 14 {
        conn.execute_batch(super::schema::CREATE_SYNC_LAMPORT)
            .map_err(|e| AppError::Storage(format!("Migration v14 (sync_lamport) failed: {e}")))?;
        conn.execute_batch(super::schema::CREATE_SYNC_CONFIG)
            .map_err(|e| AppError::Storage(format!("Migration v14 (sync_config) failed: {e}")))?;
        // Note: triggers are installed at runtime by the sync engine, not in migration.
    }
    if from_version < 15 {
        conn.execute_batch(super::schema::CREATE_SYNC_TOMBSTONES)
            .map_err(|e| AppError::Storage(format!("Migration v15 (sync_tombstones) failed: {e}")))?;
    }

    Ok(())
}
