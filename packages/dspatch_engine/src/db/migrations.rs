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
//!   v16 → add _lamport_ts and _sync_device_id columns to all synced tables for per-row LWW
//!   v17 → rebuild all FK tables with ON DELETE CASCADE (SQLite requires table-rebuild to add CASCADE)

use rusqlite::Connection;

use crate::util::error::AppError;
use crate::util::result::Result;

use super::schema::ALL_TABLES;

/// Current schema version. Must match the Dart SDK's `schemaVersion`.
pub const SCHEMA_VERSION: i32 = 18;

/// Creates all tables from scratch (fresh database, version 0 → current).
pub fn create_tables(conn: &Connection) -> Result<()> {
    for ddl in ALL_TABLES {
        conn.execute_batch(ddl)
            .map_err(|e| AppError::Storage(format!("Failed to create table: {e}")))?;
    }
    Ok(())
}

/// Runs a single migration step inside a transaction, bumping `user_version`
/// only on success.
///
/// If the migration DDL fails the transaction is rolled back automatically
/// (rusqlite drops the `Transaction` without committing) and the stored
/// `user_version` is unchanged, so the step will be retried on the next open.
fn run_migration(conn: &Connection, from_version: i32, to_version: i32) -> Result<()> {
    let tx = conn
        .unchecked_transaction()
        .map_err(|e| AppError::Storage(format!("Failed to begin transaction for v{to_version} migration: {e}")))?;

    match from_version {
        1 => {
            tx.execute_batch("ALTER TABLE agent_messages ADD COLUMN sender_name TEXT;")
                .map_err(|e| AppError::Storage(format!("Migration v2 failed: {e}")))?;
        }
        2 => {
            tx.execute_batch(
                "ALTER TABLE workspace_agents ADD COLUMN chain_json TEXT NOT NULL DEFAULT '[]';",
            )
            .map_err(|e| AppError::Storage(format!("Migration v3 (chain_json) failed: {e}")))?;

            tx.execute_batch("ALTER TABLE agent_templates ADD COLUMN readme TEXT;")
                .map_err(|e| AppError::Storage(format!("Migration v3 (readme) failed: {e}")))?;
        }
        3 => {
            tx.execute_batch("ALTER TABLE agent_messages DROP COLUMN agent_key;")
                .map_err(|e| AppError::Storage(format!("Migration v4 failed: {e}")))?;
        }
        4 => {
            tx.execute_batch("ALTER TABLE agent_messages DROP COLUMN is_partial;")
                .map_err(|e| AppError::Storage(format!("Migration v5 failed: {e}")))?;
        }
        5 => {
            tx.execute_batch("ALTER TABLE agent_activity_events ADD COLUMN content TEXT;")
                .map_err(|e| AppError::Storage(format!("Migration v6 failed: {e}")))?;
        }
        6 => {
            tx.execute_batch(
                "ALTER TABLE agent_templates ADD COLUMN fields_json TEXT NOT NULL DEFAULT '{}';",
            )
            .map_err(|e| AppError::Storage(format!("Migration v7 failed: {e}")))?;
        }
        7 => {
            tx.execute_batch(super::schema::CREATE_SIGNAL_IDENTITIES)
                .map_err(|e| AppError::Storage(format!("Migration v8 (signal_identities) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_SIGNAL_PREKEYS)
                .map_err(|e| AppError::Storage(format!("Migration v8 (signal_prekeys) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_SIGNAL_SIGNED_PREKEYS)
                .map_err(|e| AppError::Storage(format!("Migration v8 (signal_signed_prekeys) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_SIGNAL_SESSIONS)
                .map_err(|e| AppError::Storage(format!("Migration v8 (signal_sessions) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_SIGNAL_SENDER_KEYS)
                .map_err(|e| AppError::Storage(format!("Migration v8 (signal_sender_keys) failed: {e}")))?;
        }
        8 => {
            tx.execute_batch(super::schema::CREATE_SYNC_OUTBOX)
                .map_err(|e| AppError::Storage(format!("Migration v9 (sync_outbox) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_SYNC_CURSORS)
                .map_err(|e| AppError::Storage(format!("Migration v9 (sync_cursors) failed: {e}")))?;
        }
        9 => {
            // Rename old agent_templates (provider definitions) to agent_providers.
            tx.execute_batch("ALTER TABLE agent_templates RENAME TO agent_providers;")
                .map_err(|e| AppError::Storage(format!("Migration v10 (rename agent_templates → agent_providers) failed: {e}")))?;

            // Create new agent_templates table for lightweight config presets.
            tx.execute_batch(super::schema::CREATE_AGENT_TEMPLATES)
                .map_err(|e| AppError::Storage(format!("Migration v10 (create agent_templates) failed: {e}")))?;
        }
        10 => {
            tx.execute_batch(super::schema::CREATE_AGENT_INSTANCE_STATES)
                .map_err(|e| AppError::Storage(format!("Migration v11 (agent_instance_states) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_CONNECTION_STATUS)
                .map_err(|e| AppError::Storage(format!("Migration v11 (agent_connection_status) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_CONTAINER_HEALTH)
                .map_err(|e| AppError::Storage(format!("Migration v11 (container_health) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_WORKSPACE_RUN_STATUS)
                .map_err(|e| AppError::Storage(format!("Migration v11 (workspace_run_status) failed: {e}")))?;
        }
        11 => {
            tx.execute_batch(super::schema::CREATE_SIGNAL_KYBER_PREKEYS)
                .map_err(|e| AppError::Storage(format!("Migration v12 (signal_kyber_prekeys) failed: {e}")))?;
        }
        12 => {
            // Performance indexes on high-query foreign keys and filtered columns.
            tx.execute_batch(
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
        13 => {
            tx.execute_batch(super::schema::CREATE_SYNC_LAMPORT)
                .map_err(|e| AppError::Storage(format!("Migration v14 (sync_lamport) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_SYNC_CONFIG)
                .map_err(|e| AppError::Storage(format!("Migration v14 (sync_config) failed: {e}")))?;
            // Note: triggers are installed at runtime by the sync engine, not in migration.
        }
        14 => {
            tx.execute_batch(super::schema::CREATE_SYNC_TOMBSTONES)
                .map_err(|e| AppError::Storage(format!("Migration v15 (sync_tombstones) failed: {e}")))?;
        }
        15 => {
            let synced_tables = vec![
                "api_keys", "preferences", "agent_providers", "agent_templates",
                "workspace_templates", "workspaces", "workspace_runs", "workspace_agents",
                "agent_messages", "agent_logs", "agent_activity_events", "agent_usage_records",
                "agent_files", "workspace_inquiries", "instance_results",
            ];
            for table in synced_tables {
                // SQLite supports NOT NULL DEFAULT on ALTER TABLE ADD COLUMN.
                tx.execute_batch(&format!(
                    "ALTER TABLE {table} ADD COLUMN _lamport_ts INTEGER NOT NULL DEFAULT 0;\n\
                     ALTER TABLE {table} ADD COLUMN _sync_device_id TEXT NOT NULL DEFAULT '';"
                )).map_err(|e| AppError::Storage(format!("Migration v16 ({table} version columns) failed: {e}")))?;
            }
        }
        16 => {
            // Rebuild all tables that have REFERENCES without ON DELETE CASCADE.
            // SQLite cannot ALTER TABLE to add CASCADE; the only option is table-rebuild.
            // Pattern: RENAME old → _old_, CREATE new (schema SQL now has CASCADE), copy all
            // rows including sync columns, DROP old.

            // --- workspace_runs (REFERENCES workspaces(id)) ---
            tx.execute_batch(
                "ALTER TABLE workspace_runs RENAME TO _old_workspace_runs;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename workspace_runs) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_WORKSPACE_RUNS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create workspace_runs) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO workspace_runs \
                    (id, workspace_id, run_number, status, container_id, server_port, api_key, \
                     started_at, stopped_at, _lamport_ts, _sync_device_id) \
                 SELECT id, workspace_id, run_number, status, container_id, server_port, api_key, \
                        started_at, stopped_at, _lamport_ts, _sync_device_id \
                 FROM _old_workspace_runs; \
                 DROP TABLE _old_workspace_runs;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate workspace_runs) failed: {e}")))?;

            // --- workspace_agents (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE workspace_agents RENAME TO _old_workspace_agents;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename workspace_agents) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_WORKSPACE_AGENTS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create workspace_agents) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO workspace_agents \
                    (id, run_id, agent_key, instance_id, display_name, chain_json, status, \
                     created_at, updated_at, _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, display_name, chain_json, status, \
                        created_at, updated_at, _lamport_ts, _sync_device_id \
                 FROM _old_workspace_agents; \
                 DROP TABLE _old_workspace_agents;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate workspace_agents) failed: {e}")))?;

            // --- agent_messages (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE agent_messages RENAME TO _old_agent_messages;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_messages) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_MESSAGES)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_messages) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_messages \
                    (id, run_id, role, content, model, input_tokens, output_tokens, instance_id, \
                     turn_id, sender_name, created_at, _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, role, content, model, input_tokens, output_tokens, instance_id, \
                        turn_id, sender_name, created_at, _lamport_ts, _sync_device_id \
                 FROM _old_agent_messages; \
                 DROP TABLE _old_agent_messages;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_messages) failed: {e}")))?;

            // --- agent_logs (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE agent_logs RENAME TO _old_agent_logs;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_logs) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_LOGS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_logs) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_logs \
                    (id, run_id, agent_key, instance_id, turn_id, level, message, source, \
                     timestamp, _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, turn_id, level, message, source, \
                        timestamp, _lamport_ts, _sync_device_id \
                 FROM _old_agent_logs; \
                 DROP TABLE _old_agent_logs;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_logs) failed: {e}")))?;

            // --- agent_activity_events (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE agent_activity_events RENAME TO _old_agent_activity_events;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_activity_events) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_ACTIVITY_EVENTS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_activity_events) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_activity_events \
                    (id, run_id, agent_key, instance_id, turn_id, event_type, data_json, content, \
                     timestamp, _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, turn_id, event_type, data_json, content, \
                        timestamp, _lamport_ts, _sync_device_id \
                 FROM _old_agent_activity_events; \
                 DROP TABLE _old_agent_activity_events;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_activity_events) failed: {e}")))?;

            // --- agent_usage_records (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE agent_usage_records RENAME TO _old_agent_usage_records;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_usage_records) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_USAGE_RECORDS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_usage_records) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_usage_records \
                    (id, run_id, agent_key, instance_id, turn_id, model, input_tokens, \
                     output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, \
                     timestamp, _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, turn_id, model, input_tokens, \
                        output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, \
                        timestamp, _lamport_ts, _sync_device_id \
                 FROM _old_agent_usage_records; \
                 DROP TABLE _old_agent_usage_records;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_usage_records) failed: {e}")))?;

            // --- agent_files (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE agent_files RENAME TO _old_agent_files;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_files) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_FILES)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_files) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_files \
                    (id, run_id, agent_key, instance_id, turn_id, file_path, operation, \
                     timestamp, _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, turn_id, file_path, operation, \
                        timestamp, _lamport_ts, _sync_device_id \
                 FROM _old_agent_files; \
                 DROP TABLE _old_agent_files;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_files) failed: {e}")))?;

            // --- workspace_inquiries (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE workspace_inquiries RENAME TO _old_workspace_inquiries;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename workspace_inquiries) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_WORKSPACE_INQUIRIES)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create workspace_inquiries) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO workspace_inquiries \
                    (id, run_id, agent_key, instance_id, status, priority, content_markdown, \
                     attachments_json, suggestions_json, response_text, response_suggestion_index, \
                     responded_by_agent_key, forwarding_chain_json, created_at, responded_at, \
                     _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, status, priority, content_markdown, \
                        attachments_json, suggestions_json, response_text, response_suggestion_index, \
                        responded_by_agent_key, forwarding_chain_json, created_at, responded_at, \
                        _lamport_ts, _sync_device_id \
                 FROM _old_workspace_inquiries; \
                 DROP TABLE _old_workspace_inquiries;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate workspace_inquiries) failed: {e}")))?;

            // --- instance_results (REFERENCES workspace_runs(id)) ---
            tx.execute_batch(
                "ALTER TABLE instance_results RENAME TO _old_instance_results;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename instance_results) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_INSTANCE_RESULTS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create instance_results) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO instance_results \
                    (id, run_id, agent_key, instance_id, turn_id, request_id, created_at, \
                     _lamport_ts, _sync_device_id) \
                 SELECT id, run_id, agent_key, instance_id, turn_id, request_id, created_at, \
                        _lamport_ts, _sync_device_id \
                 FROM _old_instance_results; \
                 DROP TABLE _old_instance_results;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate instance_results) failed: {e}")))?;

            // --- agent_instance_states (REFERENCES workspace_runs(id)) — ephemeral, no sync cols ---
            tx.execute_batch(
                "ALTER TABLE agent_instance_states RENAME TO _old_agent_instance_states;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_instance_states) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_INSTANCE_STATES)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_instance_states) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_instance_states \
                    (instance_id, run_id, agent_key, state, updated_at) \
                 SELECT instance_id, run_id, agent_key, state, updated_at \
                 FROM _old_agent_instance_states; \
                 DROP TABLE _old_agent_instance_states;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_instance_states) failed: {e}")))?;

            // --- agent_connection_status (REFERENCES workspace_runs(id)) — ephemeral, no sync cols ---
            tx.execute_batch(
                "ALTER TABLE agent_connection_status RENAME TO _old_agent_connection_status;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename agent_connection_status) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_AGENT_CONNECTION_STATUS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create agent_connection_status) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO agent_connection_status \
                    (agent_key, run_id, connected, updated_at) \
                 SELECT agent_key, run_id, connected, updated_at \
                 FROM _old_agent_connection_status; \
                 DROP TABLE _old_agent_connection_status;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate agent_connection_status) failed: {e}")))?;

            // --- container_health (REFERENCES workspace_runs(id)) — ephemeral, no sync cols ---
            tx.execute_batch(
                "ALTER TABLE container_health RENAME TO _old_container_health;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename container_health) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_CONTAINER_HEALTH)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create container_health) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO container_health \
                    (run_id, status, error_message, updated_at) \
                 SELECT run_id, status, error_message, updated_at \
                 FROM _old_container_health; \
                 DROP TABLE _old_container_health;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate container_health) failed: {e}")))?;

            // --- workspace_run_status (REFERENCES workspace_runs(id)) — ephemeral, no sync cols ---
            tx.execute_batch(
                "ALTER TABLE workspace_run_status RENAME TO _old_workspace_run_status;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (rename workspace_run_status) failed: {e}")))?;
            tx.execute_batch(super::schema::CREATE_WORKSPACE_RUN_STATUS)
                .map_err(|e| AppError::Storage(format!("Migration v17 (create workspace_run_status) failed: {e}")))?;
            tx.execute_batch(
                "INSERT INTO workspace_run_status \
                    (run_id, status, updated_at) \
                 SELECT run_id, status, updated_at \
                 FROM _old_workspace_run_status; \
                 DROP TABLE _old_workspace_run_status;"
            ).map_err(|e| AppError::Storage(format!("Migration v17 (migrate workspace_run_status) failed: {e}")))?;
        }
        17 => {
            tx.execute_batch(super::schema::CREATE_SYNC_KNOWN_DEVICES)
                .map_err(|e| AppError::Storage(format!("Migration v18 (sync_known_devices) failed: {e}")))?;
        }
        _ => {
            // No migration defined for this step; nothing to do.
        }
    }

    // Bump version inside the transaction — only persists if commit succeeds.
    tx.execute_batch(&format!("PRAGMA user_version = {to_version};"))
        .map_err(|e| AppError::Storage(format!("Failed to bump user_version to {to_version}: {e}")))?;

    tx.commit()
        .map_err(|e| AppError::Storage(format!("Failed to commit v{to_version} migration: {e}")))?;

    Ok(())
}

/// Runs incremental migrations from `from_version` up to `SCHEMA_VERSION`.
///
/// Each migration step is wrapped in its own transaction; `user_version` is
/// bumped inside the transaction so the version only advances when the step
/// fully commits. A crash mid-step leaves the version unchanged, making the
/// step safe to retry on the next open.
///
/// Each step matches the Dart SDK's `MigrationStrategy.onUpgrade`.
pub fn run_migrations(conn: &Connection, from_version: i32) -> Result<()> {
    let mut current = from_version;
    while current < SCHEMA_VERSION {
        // Migration v17 (step 16→17) rebuilds tables to add ON DELETE CASCADE.
        // PRAGMA foreign_keys must be OFF during table-rebuild operations
        // (SQLite checks FKs on INSERT even for data-copy migrations).
        // PRAGMA foreign_keys cannot be changed inside a transaction.
        if current == 16 {
            conn.execute_batch("PRAGMA foreign_keys = OFF;")
                .map_err(|e| AppError::Storage(format!("Failed to disable FK for v17: {e}")))?;
        }

        run_migration(conn, current, current + 1)?;

        if current == 16 {
            conn.execute_batch("PRAGMA foreign_keys = ON;")
                .map_err(|e| AppError::Storage(format!("Failed to re-enable FK after v17: {e}")))?;
        }

        current += 1;
    }
    Ok(())
}
