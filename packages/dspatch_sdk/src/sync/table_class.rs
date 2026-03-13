// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Table classification for the sync engine.
//!
//! Defines which tables are synced across devices and what conflict resolution
//! strategy they use. Tables not listed here are device-local and never synced.

/// Sync strategy for a table.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncStrategy {
    /// Account-level data. Any device can write. Last-writer-wins by Lamport
    /// timestamp with device-ID tiebreaking.
    AccountLww,
    /// Workspace-owned data. Only the device running the workspace writes.
    /// Other devices receive append-only replicas. LWW for status fields
    /// (e.g. inquiry status).
    WorkspaceOwned,
}

/// Static table classification lookup.
pub struct TableClassification;

impl TableClassification {
    /// Returns the sync strategy for a table, or `None` if the table is
    /// device-local (never synced).
    pub fn for_table(table: &str) -> Option<SyncStrategy> {
        match table {
            // Account-level LWW — any device can write
            "api_keys" | "preferences" | "agent_providers" | "agent_templates"
            | "workspace_templates" => Some(SyncStrategy::AccountLww),

            // Workspace-owned — device running the workspace is authoritative
            "workspaces" | "workspace_runs" | "workspace_agents" | "agent_messages"
            | "agent_logs" | "agent_activity_events" | "agent_usage_records"
            | "agent_files" | "workspace_inquiries" | "instance_results" => {
                Some(SyncStrategy::WorkspaceOwned)
            }

            // Device-local tables (crypto, sync infra, UI state) — never synced
            _ => None,
        }
    }

    /// Returns all table names that participate in sync (15 total).
    pub fn synced_tables() -> Vec<&'static str> {
        vec![
            // Account-level
            "api_keys",
            "preferences",
            "agent_providers",
            "agent_templates",
            "workspace_templates",
            // Workspace-owned
            "workspaces",
            "workspace_runs",
            "workspace_agents",
            "agent_messages",
            "agent_logs",
            "agent_activity_events",
            "agent_usage_records",
            "agent_files",
            "workspace_inquiries",
            "instance_results",
        ]
    }

    /// Returns `true` if the given table should be synced.
    pub fn is_synced(table: &str) -> bool {
        Self::for_table(table).is_some()
    }
}
