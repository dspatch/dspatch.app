// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use crate::domain::enums::{InquiryPriority, InquiryStatus};

/// An inquiry raised by an agent within a workspace, requiring user response.
///
/// Workspace inquiries support markdown content, attachments, suggestion chips,
/// and can be responded to by the user or another agent.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceInquiry {
    pub id: String,
    pub run_id: String,
    pub agent_key: String,
    pub instance_id: String,
    pub status: InquiryStatus,
    pub priority: InquiryPriority,
    pub content_markdown: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attachments_json: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub suggestions_json: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub response_text: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub response_suggestion_index: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub responded_by_agent_key: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub forwarding_chain_json: Option<String>,
    pub created_at: NaiveDateTime,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub responded_at: Option<NaiveDateTime>,
}
