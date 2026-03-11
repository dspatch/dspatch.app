// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! CREATE TABLE statements for all 15 tables in the d:spatch schema.
//!
//! Each constant corresponds to a Drift table class in the Dart SDK.
//! Column types follow the Drift → SQLite mapping:
//!   TextColumn → TEXT, IntColumn → INTEGER, BoolColumn → INTEGER (0/1),
//!   DateTimeColumn → TEXT (ISO 8601), BlobColumn → BLOB, RealColumn → REAL.

pub const CREATE_WORKSPACES: &str = "\
CREATE TABLE IF NOT EXISTS workspaces (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    project_path TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_WORKSPACE_RUNS: &str = "\
CREATE TABLE IF NOT EXISTS workspace_runs (
    id TEXT NOT NULL PRIMARY KEY,
    workspace_id TEXT NOT NULL REFERENCES workspaces(id),
    run_number INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'starting',
    container_id TEXT,
    server_port INTEGER,
    api_key TEXT,
    started_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    stopped_at TEXT
);";

pub const CREATE_WORKSPACE_AGENTS: &str = "\
CREATE TABLE IF NOT EXISTS workspace_agents (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    chain_json TEXT NOT NULL DEFAULT '[]',
    status TEXT NOT NULL DEFAULT 'disconnected',
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_AGENT_MESSAGES: &str = "\
CREATE TABLE IF NOT EXISTS agent_messages (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    model TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    sender_name TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_AGENT_LOGS: &str = "\
CREATE TABLE IF NOT EXISTS agent_logs (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    level TEXT NOT NULL,
    message TEXT NOT NULL,
    source TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_AGENT_ACTIVITY_EVENTS: &str = "\
CREATE TABLE IF NOT EXISTS agent_activity_events (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    event_type TEXT NOT NULL,
    data_json TEXT,
    content TEXT,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_AGENT_USAGE_RECORDS: &str = "\
CREATE TABLE IF NOT EXISTS agent_usage_records (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    model TEXT NOT NULL,
    input_tokens INTEGER NOT NULL,
    output_tokens INTEGER NOT NULL,
    cache_read_tokens INTEGER NOT NULL,
    cache_write_tokens INTEGER NOT NULL,
    cost_usd REAL NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_AGENT_FILES: &str = "\
CREATE TABLE IF NOT EXISTS agent_files (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT,
    file_path TEXT NOT NULL,
    operation TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_WORKSPACE_INQUIRIES: &str = "\
CREATE TABLE IF NOT EXISTS workspace_inquiries (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    content_markdown TEXT NOT NULL,
    attachments_json TEXT,
    suggestions_json TEXT,
    response_text TEXT,
    response_suggestion_index INTEGER,
    responded_by_agent_key TEXT,
    forwarding_chain_json TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    responded_at TEXT
);";

pub const CREATE_AGENT_PROVIDERS: &str = "\
CREATE TABLE IF NOT EXISTS agent_providers (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    source_type TEXT NOT NULL,
    source_path TEXT,
    git_url TEXT,
    git_branch TEXT,
    entry_point TEXT NOT NULL,
    description TEXT,
    readme TEXT,
    required_env_json TEXT NOT NULL DEFAULT '[]',
    required_mounts_json TEXT NOT NULL DEFAULT '[]',
    fields_json TEXT NOT NULL DEFAULT '{}',
    hub_slug TEXT,
    hub_author TEXT,
    hub_category TEXT,
    hub_tags_json TEXT NOT NULL DEFAULT '[]',
    hub_version INTEGER,
    hub_repo_url TEXT,
    hub_commit_hash TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_AGENT_TEMPLATES: &str = "\
CREATE TABLE IF NOT EXISTS agent_templates (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    source_uri TEXT NOT NULL,
    file_path TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S.000Z', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S.000Z', 'now'))
);";

pub const CREATE_API_KEYS: &str = "\
CREATE TABLE IF NOT EXISTS api_keys (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    provider_label TEXT NOT NULL,
    encrypted_key BLOB NOT NULL,
    display_hint TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_PREFERENCES: &str = "\
CREATE TABLE IF NOT EXISTS preferences (
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL
);";

pub const CREATE_WORKSPACE_TEMPLATES: &str = "\
CREATE TABLE IF NOT EXISTS workspace_templates (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    hub_slug TEXT NOT NULL,
    hub_author TEXT NOT NULL,
    hub_category TEXT,
    hub_tags_json TEXT NOT NULL DEFAULT '[]',
    hub_version INTEGER NOT NULL,
    config_json TEXT NOT NULL,
    agent_refs_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_RECENT_PROJECTS: &str = "\
CREATE TABLE IF NOT EXISTS recent_projects (
    id TEXT NOT NULL PRIMARY KEY,
    path TEXT NOT NULL,
    name TEXT NOT NULL,
    is_git_repo INTEGER NOT NULL DEFAULT 0,
    last_used_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_INSTANCE_RESULTS: &str = "\
CREATE TABLE IF NOT EXISTS instance_results (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    turn_id TEXT NOT NULL,
    request_id TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

// ---------------------------------------------------------------------------
// Signal Protocol key stores
// ---------------------------------------------------------------------------

pub const CREATE_SIGNAL_IDENTITIES: &str = "\
CREATE TABLE IF NOT EXISTS signal_identities (
    address TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    identity_key BLOB NOT NULL,
    trust_level INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (address, device_id)
);";

pub const CREATE_SIGNAL_PREKEYS: &str = "\
CREATE TABLE IF NOT EXISTS signal_prekeys (
    id INTEGER PRIMARY KEY,
    record BLOB NOT NULL
);";

pub const CREATE_SIGNAL_SIGNED_PREKEYS: &str = "\
CREATE TABLE IF NOT EXISTS signal_signed_prekeys (
    id INTEGER PRIMARY KEY,
    record BLOB NOT NULL,
    created_at TEXT NOT NULL
);";

pub const CREATE_SIGNAL_SESSIONS: &str = "\
CREATE TABLE IF NOT EXISTS signal_sessions (
    address TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    record BLOB NOT NULL,
    PRIMARY KEY (address, device_id)
);";

pub const CREATE_SIGNAL_SENDER_KEYS: &str = "\
CREATE TABLE IF NOT EXISTS signal_sender_keys (
    sender_address TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    distribution_id TEXT NOT NULL,
    record BLOB NOT NULL,
    PRIMARY KEY (sender_address, device_id, distribution_id)
);";

// ---------------------------------------------------------------------------
// P2P sync tables
// ---------------------------------------------------------------------------

pub const CREATE_SYNC_OUTBOX: &str = "\
CREATE TABLE IF NOT EXISTS sync_outbox (
    id TEXT NOT NULL PRIMARY KEY,
    table_name TEXT NOT NULL,
    row_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    data TEXT,
    lamport_ts INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);";

pub const CREATE_SYNC_CURSORS: &str = "\
CREATE TABLE IF NOT EXISTS sync_cursors (
    device_id TEXT NOT NULL,
    table_name TEXT NOT NULL,
    high_water_mark INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (device_id, table_name)
);";

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
    CREATE_SYNC_OUTBOX,
    CREATE_SYNC_CURSORS,
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
    "sync_outbox",
    "sync_cursors",
];
