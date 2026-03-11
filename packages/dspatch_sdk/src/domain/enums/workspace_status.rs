// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Lifecycle state of a workspace.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum WorkspaceStatus {
    Idle,
    Starting,
    Running,
    Stopping,
    Failed,
}

impl WorkspaceStatus {
    /// Whether this is a final state.
    pub fn is_terminal(self) -> bool {
        self == Self::Failed
    }

    /// Whether the workspace is actively doing something.
    pub fn is_active(self) -> bool {
        matches!(self, Self::Starting | Self::Running | Self::Stopping)
    }

    /// Returns `true` if transitioning from this state to `next` is valid.
    pub fn can_transition_to(self, next: WorkspaceStatus) -> bool {
        use WorkspaceStatus::*;
        let valid: &[WorkspaceStatus] = match self {
            Idle => &[Starting],
            Starting => &[Running, Failed],
            Running => &[Stopping, Failed],
            Stopping => &[Idle, Failed],
            Failed => &[Idle],
        };
        valid.contains(&next)
    }
}
