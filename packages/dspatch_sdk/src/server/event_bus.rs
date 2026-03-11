// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Broadcast event bus for SDK lifecycle events.
//!
//! Services emit events as a fire-and-forget side-channel. Consumers
//! (Flutter app, CLI) subscribe independently via the FRB bridge.
//! The bus never drives application logic — it is purely informational.

use serde::{Deserialize, Serialize};
use tokio::sync::broadcast;

/// Lifecycle events broadcast to SDK consumers.
///
/// All fields are `String` for FRB compatibility. Consumers filter on
/// their side — the bus sends everything to every subscriber.
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

/// Broadcast bus for SDK lifecycle events.
///
/// Fire-and-forget: `emit()` silently drops events if no receivers exist.
/// Multiple consumers can subscribe independently via `subscribe()`.
pub struct SdkEventBus {
    tx: broadcast::Sender<SdkEvent>,
}

impl SdkEventBus {
    /// Creates a new event bus with the given channel capacity.
    ///
    /// 64 is generous for lifecycle events (they are infrequent).
    pub fn new(capacity: usize) -> Self {
        let (tx, _) = broadcast::channel(capacity);
        Self { tx }
    }

    /// Emit an event to all current subscribers. Silent if nobody is listening.
    pub fn emit(&self, event: SdkEvent) {
        let _ = self.tx.send(event);
    }

    /// Create a new subscription. Each subscriber gets its own receiver.
    pub fn subscribe(&self) -> broadcast::Receiver<SdkEvent> {
        self.tx.subscribe()
    }
}
