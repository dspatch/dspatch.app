// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// Urgency level of an inquiry, affecting notification behavior.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum InquiryPriority {
    /// Standard priority -- displayed in the inquiry list.
    Normal,

    /// Elevated priority -- triggers a push notification.
    High,

    /// Critical priority -- triggers immediate notification and visual alert.
    Urgent,
}
