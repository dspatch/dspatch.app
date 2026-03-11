// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn run(workspace_id: &str) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.workspaces().await?;
        svc.stop_workspace(workspace_id).await?;

        println!("Workspace \"{}\" stopped.", workspace_id);
        Ok(())
    })
    .await
}
