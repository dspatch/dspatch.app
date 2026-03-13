// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Sync message types for the P2P sync protocol.
//!
//! These types define the wire format for sync messages exchanged between
//! devices over encrypted channels.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

/// The type of mutation that was performed on a row.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SyncOp {
    Insert,
    Update,
    Delete,
}

impl SyncOp {
    /// Returns the SQL-friendly string representation.
    pub fn as_str(&self) -> &'static str {
        match self {
            SyncOp::Insert => "insert",
            SyncOp::Update => "update",
            SyncOp::Delete => "delete",
        }
    }

    /// Parses from the stored string representation.
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "insert" => Some(SyncOp::Insert),
            "update" => Some(SyncOp::Update),
            "delete" => Some(SyncOp::Delete),
            _ => None,
        }
    }
}

/// A single change to be synced between devices.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncChange {
    /// Unique identifier for this change entry.
    pub id: String,
    /// The table that was modified.
    pub table: String,
    /// The primary key of the affected row.
    pub row_id: String,
    /// The type of operation performed.
    pub operation: SyncOp,
    /// JSON representation of the row data (None for deletes).
    pub data: serde_json::Value,
    /// Lamport timestamp for causal ordering.
    pub lamport_ts: i64,
    /// The device that originated this change.
    pub device_id: String,
}

/// A command to be executed on the device owning a workspace.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteCommand {
    /// Unique ID for correlating the result.
    pub command_id: String,
    /// The command method name (e.g. "send_user_input", "stop_workspace").
    pub method: String,
    /// JSON parameters for the command.
    pub params: serde_json::Value,
}

/// The result of executing a remote command.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommandResult {
    /// The command ID this result is for.
    pub command_id: String,
    /// Whether the command succeeded.
    pub success: bool,
    /// Error message if the command failed.
    pub error: Option<String>,
}

/// Messages exchanged between peers during sync.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SyncMessage {
    /// Batch of changes to apply.
    Changes(Vec<SyncChange>),
    /// Acknowledgement of received changes up to a given ID.
    Ack { last_id: String },
    /// Exchange cursors for reconciliation (table name → high water mark).
    CursorExchange(HashMap<String, i64>),
    /// Request missing changes since a given lamport timestamp.
    RequestChanges {
        table: String,
        since_lamport: i64,
    },
    /// A command to be forwarded to the owning device.
    Command(RemoteCommand),
    /// The result of a remotely executed command.
    CommandResult(CommandResult),
}
