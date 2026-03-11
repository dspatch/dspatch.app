// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local inquiry service — wraps WorkspaceDao inquiry methods.

use std::sync::Arc;

use futures::StreamExt;

use crate::db::dao::WorkspaceDao;
use crate::domain::enums::InquiryStatus;
use crate::domain::models::{InquiryWithWorkspace, WorkspaceInquiry};
use crate::domain::services::WatchStream;
use crate::util::result::Result;

/// Callback type for sending an inquiry response to an agent.
///
/// Takes (run_id, instance_id, inquiry_id, response_text, suggestion_index).
pub type SendInquiryResponseFn = Arc<
    dyn Fn(&str, &str, &str, Option<&str>, Option<i32>) -> std::result::Result<bool, String>
        + Send
        + Sync,
>;

/// Local implementation of inquiry service backed by [`WorkspaceDao`].
///
/// For `respond_to_workspace_inquiry`, an optional callback is used to
/// send the response to the agent via the connection layer.
pub struct LocalInquiryService {
    dao: Arc<WorkspaceDao>,
    send_response: Option<SendInquiryResponseFn>,
}

impl LocalInquiryService {
    pub fn new(dao: Arc<WorkspaceDao>) -> Self {
        Self {
            dao,
            send_response: None,
        }
    }

    /// Sets the callback for sending inquiry responses to agents.
    pub fn set_send_response(&mut self, callback: SendInquiryResponseFn) {
        self.send_response = Some(callback);
    }

    /// Watches all inquiries for a run, most recent first.
    pub fn watch_workspace_inquiries(
        &self,
        run_id: &str,
    ) -> WatchStream<Vec<WorkspaceInquiry>> {
        let stream = self.dao.watch_workspace_inquiries(run_id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspace_inquiries error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches inquiries from the latest run of each workspace, most recent first.
    pub fn watch_all_inquiries(&self) -> WatchStream<Vec<InquiryWithWorkspace>> {
        let stream = self.dao.watch_all_inquiries();
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_all_inquiries error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches a single workspace inquiry by `id`.
    pub fn watch_workspace_inquiry(
        &self,
        id: &str,
    ) -> WatchStream<Option<WorkspaceInquiry>> {
        let stream = self.dao.watch_workspace_inquiry(id);
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v),
                Err(e) => {
                    tracing::warn!("watch_workspace_inquiry error: {e}");
                    None
                }
            }
        }))
    }

    /// Watches the count of pending inquiries across all workspaces.
    pub fn watch_all_pending_inquiry_count(&self) -> WatchStream<i32> {
        let stream = self.dao.watch_pending_inquiry_count();
        Box::pin(stream.filter_map(|r| async {
            match r {
                Ok(v) => Some(v as i32),
                Err(e) => {
                    tracing::warn!("watch_pending_inquiry_count error: {e}");
                    None
                }
            }
        }))
    }

    /// Responds to a workspace inquiry. Updates the DB and optionally sends
    /// the response to the agent via the registered callback.
    pub async fn respond_to_workspace_inquiry(
        &self,
        inquiry_id: &str,
        response_text: Option<&str>,
        response_suggestion_index: Option<i32>,
    ) -> Result<()> {
        // 1. Update the inquiry row in the database.
        self.dao.update_workspace_inquiry_response(
            inquiry_id,
            response_text,
            response_suggestion_index.map(|i| i as i64),
            &InquiryStatus::Responded,
        )?;

        // 2. Send response to agent via callback if available.
        if let Some(ref callback) = self.send_response {
            // We need the inquiry to get routing info.
            // Use a fresh watch to get the current state.
            let stream = self.dao.watch_workspace_inquiry(inquiry_id);
            futures::pin_mut!(stream);
            if let Some(Ok(Some(inquiry))) = stream.next().await {
                let sent = callback(
                    &inquiry.run_id,
                    &inquiry.instance_id,
                    inquiry_id,
                    response_text,
                    response_suggestion_index,
                );

                match sent {
                    Ok(true) => {
                        tracing::info!(
                            "Inquiry response for {inquiry_id} delivered"
                        );
                        // Mark as delivered.
                        self.dao.update_workspace_inquiry_response(
                            inquiry_id,
                            None,
                            None,
                            &InquiryStatus::Delivered,
                        )?;
                    }
                    Ok(false) => {
                        tracing::warn!(
                            "Inquiry response for {inquiry_id} could not be delivered (not connected)"
                        );
                    }
                    Err(e) => {
                        tracing::warn!(
                            "Failed to send inquiry response for {inquiry_id}: {e}"
                        );
                    }
                }
            }
        }

        Ok(())
    }
}
