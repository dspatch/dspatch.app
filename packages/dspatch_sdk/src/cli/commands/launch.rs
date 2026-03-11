// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::sync::Arc;

use futures::StreamExt;

use crate::cli::with_sdk;
use crate::DspatchSdk;
use crate::util::result::Result;

pub async fn run(workspace_id: &str) -> Result<()> {
    with_sdk(|sdk| {
        let ws_id = workspace_id.to_string();
        async move {
            sdk.start_server(None).await?;
            let svc = sdk.workspaces().await?;
            svc.launch_workspace(&ws_id).await?;

            println!("Workspace \"{}\" launched. Press Ctrl+C to stop.", ws_id);

            // Stay alive: wait for workspace to reach a terminal state or Ctrl+C.
            wait_for_stop(Arc::clone(&sdk), &ws_id).await;

            Ok(())
        }
    })
    .await
}

/// Blocks until the workspace run reaches a terminal state or Ctrl+C is received.
///
/// On Ctrl+C, attempts a graceful stop before returning.
async fn wait_for_stop(sdk: Arc<DspatchSdk>, workspace_id: &str) {
    let svc = match sdk.workspaces().await {
        Ok(s) => s,
        Err(_) => return,
    };

    // Watch the workspace's runs for terminal state.
    let mut run_stream = svc.watch_workspace_runs(workspace_id);

    let ctrl_c = tokio::signal::ctrl_c();
    tokio::pin!(ctrl_c);

    loop {
        tokio::select! {
            _ = &mut ctrl_c => {
                println!("\nStopping workspace...");
                if let Err(e) = svc.stop_workspace(workspace_id).await {
                    eprintln!("Stop failed: {e}");
                }
                return;
            }
            result = run_stream.next() => {
                match result {
                    Some(runs) => {
                        // Skip empty emissions (run may not be created yet).
                        if runs.is_empty() {
                            continue;
                        }
                        // Check if all runs are terminal (no active run left).
                        let has_active = runs.iter().any(|r| {
                            r.status == "running" || r.status == "starting" || r.status == "stopping"
                        });
                        if !has_active {
                            println!("Workspace stopped.");
                            return;
                        }
                    }
                    None => return, // Stream ended.
                }
            }
        }
    }
}
