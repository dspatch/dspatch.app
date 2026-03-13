// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SDK lifecycle event types.
//!
//! The `SdkEventBus` broadcast mechanism has been removed — events now flow
//! through ephemeral DB tables and table-invalidation streams. This module
//! is retained only for the `SdkEvent` enum, which `frb_generated.rs`
//! references. It will be deleted entirely when the FRB bridge is removed.

use serde::{Deserialize, Serialize};

/// Lifecycle events formerly broadcast to SDK consumers.
///
/// Retained for `frb_generated.rs` compatibility. Will be removed when the
/// FRB bridge is deleted.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SdkEvent {
    // ── Workspace lifecycle ──
    WorkspaceRunStarted {
        workspace_id: String,
        run_id: String,
    },
    WorkspaceRunStopped {
        workspace_id: String,
        run_id: String,
    },
    WorkspaceRunFailed {
        workspace_id: String,
        run_id: String,
    },

    // ── Agent connection ──
    AgentConnected {
        workspace_id: String,
        agent_key: String,
    },
    AgentDisconnected {
        workspace_id: String,
        agent_key: String,
    },

    // ── Instance lifecycle ──
    InstanceCreated {
        workspace_id: String,
        agent_key: String,
        instance_id: String,
    },
    InstanceStateChanged {
        workspace_id: String,
        agent_key: String,
        instance_id: String,
        old_state: String,
        new_state: String,
    },
    InstanceGone {
        workspace_id: String,
        agent_key: String,
        instance_id: String,
    },

    // ── Inquiries ──
    InquiryCreated {
        workspace_id: String,
        agent_key: String,
        inquiry_id: String,
        priority: String,
    },
    InquiryResolved {
        workspace_id: String,
        inquiry_id: String,
    },

    // ── Conversation chains ──
    TurnCompleted {
        workspace_id: String,
        agent_key: String,
        instance_id: String,
        turn_id: String,
    },
    ChainCompleted {
        workspace_id: String,
        request_id: String,
    },
}
