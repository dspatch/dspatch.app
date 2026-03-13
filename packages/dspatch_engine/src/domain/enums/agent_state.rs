// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Lifecycle state of an agent instance.
///
/// The four wire-protocol states (`idle`, `generating`, `waiting_for_agent`,
/// `waiting_for_inquiry`) are the canonical vocabulary shared with the Python
/// SDK.  The remaining values (`disconnected`, `completed`, `failed`,
/// `crashed`) are app-only lifecycle markers that never travel on the wire.
///
/// This is the **single source of truth** for agent state across the entire
/// app -- there is no separate "AgentStatus" type.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AgentState {
    // -- Wire-protocol states (shared with Python SDK) --

    /// No active turn; instance is ready to accept new input.
    Idle,

    /// Agent function is running; a turn is active.
    Generating,

    /// Blocked on a `talk_to` response from another agent.
    WaitingForAgent,

    /// Blocked on an inquiry response.
    WaitingForInquiry,

    // -- App-only lifecycle states --

    /// No WebSocket connection -- agent assumed down.
    Disconnected,

    /// Agent finished successfully (terminal).
    Completed,

    /// Agent terminated with an error (terminal).
    Failed,

    /// Agent process exited unexpectedly; may be restarted.
    Crashed,
}

impl AgentState {
    /// Whether this is a final state that cannot transition further.
    pub fn is_terminal(self) -> bool {
        matches!(self, Self::Completed | Self::Failed)
    }

    /// Whether the agent is doing work or waiting on something.
    pub fn is_active(self) -> bool {
        self == Self::Generating || self.is_waiting()
    }

    /// Whether the agent is blocked waiting for external input.
    pub fn is_waiting(self) -> bool {
        matches!(
            self,
            Self::Idle | Self::WaitingForInquiry | Self::WaitingForAgent
        )
    }

    /// Returns `true` if transitioning from this state to `next` is valid.
    pub fn can_transition_to(self, next: AgentState) -> bool {
        use AgentState::*;
        let valid: &[AgentState] = match self {
            Disconnected => &[Generating, Idle, WaitingForInquiry, WaitingForAgent],
            Idle => &[Generating, Completed, Failed, Crashed, Disconnected],
            Generating => &[
                Idle,
                WaitingForInquiry,
                WaitingForAgent,
                Completed,
                Failed,
                Crashed,
                Disconnected,
            ],
            WaitingForInquiry => &[Generating, Completed, Failed, Crashed, Disconnected],
            WaitingForAgent => &[Generating, Completed, Failed, Crashed, Disconnected],
            Crashed => &[Disconnected, Generating],
            // Terminal states have no valid transitions.
            Completed | Failed => &[],
        };
        valid.contains(&next)
    }

    /// Serialize to a wire-protocol string.  Covers all variants so that
    /// `from_wire(s.to_wire()) == Some(s)` holds for wire states, and app-only
    /// states produce a recognisable lowercase name.
    pub fn to_wire(self) -> &'static str {
        match self {
            Self::Idle => "idle",
            Self::Generating => "generating",
            Self::WaitingForAgent => "waiting_for_agent",
            Self::WaitingForInquiry => "waiting_for_inquiry",
            Self::Disconnected => "disconnected",
            Self::Completed => "completed",
            Self::Failed => "failed",
            Self::Crashed => "crashed",
        }
    }

    /// Parse a wire-protocol string (`idle`, `generating`, `waiting_for_agent`,
    /// `waiting_for_inquiry`).  Returns `None` for unknown values.
    pub fn from_wire(value: &str) -> Option<Self> {
        match value {
            "idle" => Some(Self::Idle),
            "generating" => Some(Self::Generating),
            "waiting_for_agent" => Some(Self::WaitingForAgent),
            "waiting_for_inquiry" => Some(Self::WaitingForInquiry),
            _ => None,
        }
    }

    /// Parse a value stored in the local DB.  Handles both current enum names
    /// and legacy `AgentStatus` names (`running`, `waitingForInput`).
    pub fn from_db(value: &str) -> Option<Self> {
        match value {
            // Legacy AgentStatus names
            "running" => Some(Self::Generating),
            "waitingForInput" => Some(Self::Idle),
            // Current enum names (camelCase as stored by Dart)
            "idle" => Some(Self::Idle),
            "generating" => Some(Self::Generating),
            "waitingForAgent" => Some(Self::WaitingForAgent),
            "waitingForInquiry" => Some(Self::WaitingForInquiry),
            "disconnected" => Some(Self::Disconnected),
            "completed" => Some(Self::Completed),
            "failed" => Some(Self::Failed),
            "crashed" => Some(Self::Crashed),
            _ => None,
        }
    }
}
