// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use async_trait::async_trait;

use crate::domain::models::{InquiryWithWorkspace, WorkspaceInquiry};
use crate::util::result::Result;

use super::WatchStream;

/// Inquiry lifecycle management across workspaces.
#[async_trait]
pub trait InquiryService: Send + Sync {
    /// Watches all inquiries for a run, most recent first.
    fn watch_workspace_inquiries(&self, run_id: &str) -> WatchStream<Vec<WorkspaceInquiry>>;

    /// Watches inquiries from the latest run of each workspace, most recent first.
    fn watch_all_inquiries(&self) -> WatchStream<Vec<InquiryWithWorkspace>>;

    /// Watches a single workspace inquiry by `id`.
    /// Emits `None` when the inquiry doesn't exist.
    fn watch_workspace_inquiry(&self, id: &str) -> WatchStream<Option<WorkspaceInquiry>>;

    /// Watches the count of pending inquiries across all workspaces.
    fn watch_all_pending_inquiry_count(&self) -> WatchStream<i32>;

    /// Responds to a workspace inquiry. Sends the response to the originating
    /// agent via WebSocket and updates the inquiry row in the database.
    async fn respond_to_workspace_inquiry(
        &self,
        inquiry_id: &str,
        response_text: Option<&str>,
        response_suggestion_index: Option<i32>,
    ) -> Result<()>;
}
