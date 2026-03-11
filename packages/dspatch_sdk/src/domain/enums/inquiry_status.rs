// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Whether an inquiry has been answered by the user.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum InquiryStatus {
    /// Awaiting user response.
    Pending,

    /// User has submitted a response.
    Responded,

    /// Response was delivered to the agent via WebSocket.
    /// Reconnect replay skips inquiries in this state.
    Delivered,

    /// The 72-hour window elapsed without a response.
    Expired,
}
