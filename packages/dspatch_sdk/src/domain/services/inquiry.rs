// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::util::result::Result;

/// Inquiry lifecycle management across workspaces.
#[async_trait]
pub trait InquiryService: Send + Sync {
    /// Responds to a workspace inquiry. Sends the response to the originating
    /// agent via WebSocket and updates the inquiry row in the database.
    async fn respond_to_workspace_inquiry(
        &self,
        inquiry_id: &str,
        response_text: Option<&str>,
        response_suggestion_index: Option<i32>,
    ) -> Result<()>;
}
