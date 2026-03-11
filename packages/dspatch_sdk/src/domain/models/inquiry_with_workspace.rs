// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

use super::workspace_inquiry::WorkspaceInquiry;

/// An inquiry paired with its parent workspace's display name and ID.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InquiryWithWorkspace {
    pub inquiry: WorkspaceInquiry,
    pub workspace_name: String,
    pub workspace_id: String,
}
