// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! CREATE TABLE statements for all 27 tables in the d:spatch schema.
//!
//! Each constant corresponds to a Drift table class in the Dart SDK.
//! Column types follow the Drift → SQLite mapping:
//!   TextColumn → TEXT, IntColumn → INTEGER, BoolColumn → INTEGER (0/1),
//!   DateTimeColumn → TEXT (ISO 8601), BlobColumn → BLOB, RealColumn → REAL.
//!
//! SQL definitions live in `shared/schema/*.sql` so both the Rust engine
//! and the Dart SDK can consume the same schema.

pub const CREATE_WORKSPACES: &str = include_str!("../../shared/schema/workspaces.sql");
pub const CREATE_WORKSPACE_RUNS: &str = include_str!("../../shared/schema/workspace_runs.sql");
pub const CREATE_WORKSPACE_AGENTS: &str = include_str!("../../shared/schema/workspace_agents.sql");
pub const CREATE_AGENT_MESSAGES: &str = include_str!("../../shared/schema/agent_messages.sql");
pub const CREATE_AGENT_LOGS: &str = include_str!("../../shared/schema/agent_logs.sql");
pub const CREATE_AGENT_ACTIVITY_EVENTS: &str = include_str!("../../shared/schema/agent_activity_events.sql");
pub const CREATE_AGENT_USAGE_RECORDS: &str = include_str!("../../shared/schema/agent_usage_records.sql");
pub const CREATE_AGENT_FILES: &str = include_str!("../../shared/schema/agent_files.sql");
pub const CREATE_WORKSPACE_INQUIRIES: &str = include_str!("../../shared/schema/workspace_inquiries.sql");
pub const CREATE_AGENT_PROVIDERS: &str = include_str!("../../shared/schema/agent_providers.sql");
pub const CREATE_AGENT_TEMPLATES: &str = include_str!("../../shared/schema/agent_templates.sql");
pub const CREATE_API_KEYS: &str = include_str!("../../shared/schema/api_keys.sql");
pub const CREATE_PREFERENCES: &str = include_str!("../../shared/schema/preferences.sql");
pub const CREATE_WORKSPACE_TEMPLATES: &str = include_str!("../../shared/schema/workspace_templates.sql");
pub const CREATE_RECENT_PROJECTS: &str = include_str!("../../shared/schema/recent_projects.sql");
pub const CREATE_INSTANCE_RESULTS: &str = include_str!("../../shared/schema/instance_results.sql");

// ---------------------------------------------------------------------------
// Signal Protocol key stores
// ---------------------------------------------------------------------------

pub const CREATE_SIGNAL_IDENTITIES: &str = include_str!("../../shared/schema/signal_identities.sql");
pub const CREATE_SIGNAL_PREKEYS: &str = include_str!("../../shared/schema/signal_prekeys.sql");
pub const CREATE_SIGNAL_SIGNED_PREKEYS: &str = include_str!("../../shared/schema/signal_signed_prekeys.sql");
pub const CREATE_SIGNAL_SESSIONS: &str = include_str!("../../shared/schema/signal_sessions.sql");
pub const CREATE_SIGNAL_SENDER_KEYS: &str = include_str!("../../shared/schema/signal_sender_keys.sql");
pub const CREATE_SIGNAL_KYBER_PREKEYS: &str = include_str!("../../shared/schema/signal_kyber_prekeys.sql");

// ---------------------------------------------------------------------------
// P2P sync tables
// ---------------------------------------------------------------------------

pub const CREATE_SYNC_OUTBOX: &str = include_str!("../../shared/schema/sync_outbox.sql");
pub const CREATE_SYNC_CURSORS: &str = include_str!("../../shared/schema/sync_cursors.sql");

// ---------------------------------------------------------------------------
// Ephemeral state tables
// ---------------------------------------------------------------------------

pub const CREATE_AGENT_INSTANCE_STATES: &str =
    include_str!("../../shared/schema/agent_instance_states.sql");
pub const CREATE_AGENT_CONNECTION_STATUS: &str =
    include_str!("../../shared/schema/agent_connection_status.sql");
pub const CREATE_CONTAINER_HEALTH: &str =
    include_str!("../../shared/schema/container_health.sql");
pub const CREATE_WORKSPACE_RUN_STATUS: &str =
    include_str!("../../shared/schema/workspace_run_status.sql");

/// All CREATE TABLE statements in dependency order.
pub const ALL_TABLES: &[&str] = &[
    CREATE_WORKSPACES,
    CREATE_WORKSPACE_RUNS,
    CREATE_WORKSPACE_AGENTS,
    CREATE_AGENT_MESSAGES,
    CREATE_AGENT_LOGS,
    CREATE_AGENT_ACTIVITY_EVENTS,
    CREATE_AGENT_USAGE_RECORDS,
    CREATE_AGENT_FILES,
    CREATE_WORKSPACE_INQUIRIES,
    CREATE_AGENT_PROVIDERS,
    CREATE_AGENT_TEMPLATES,
    CREATE_API_KEYS,
    CREATE_PREFERENCES,
    CREATE_WORKSPACE_TEMPLATES,
    CREATE_RECENT_PROJECTS,
    CREATE_INSTANCE_RESULTS,
    CREATE_SIGNAL_IDENTITIES,
    CREATE_SIGNAL_PREKEYS,
    CREATE_SIGNAL_SIGNED_PREKEYS,
    CREATE_SIGNAL_SESSIONS,
    CREATE_SIGNAL_SENDER_KEYS,
    CREATE_SIGNAL_KYBER_PREKEYS,
    CREATE_SYNC_OUTBOX,
    CREATE_SYNC_CURSORS,
    CREATE_AGENT_INSTANCE_STATES,
    CREATE_AGENT_CONNECTION_STATUS,
    CREATE_CONTAINER_HEALTH,
    CREATE_WORKSPACE_RUN_STATUS,
];

/// Table names used by the reactive layer for change tracking.
pub const TABLE_NAMES: &[&str] = &[
    "workspaces",
    "workspace_runs",
    "workspace_agents",
    "agent_messages",
    "agent_logs",
    "agent_activity_events",
    "agent_usage_records",
    "agent_files",
    "workspace_inquiries",
    "agent_providers",
    "agent_templates",
    "api_keys",
    "preferences",
    "workspace_templates",
    "recent_projects",
    "instance_results",
    "signal_identities",
    "signal_prekeys",
    "signal_signed_prekeys",
    "signal_sessions",
    "signal_sender_keys",
    "signal_kyber_prekeys",
    "sync_outbox",
    "sync_cursors",
    "agent_instance_states",
    "agent_connection_status",
    "container_health",
    "workspace_run_status",
];
