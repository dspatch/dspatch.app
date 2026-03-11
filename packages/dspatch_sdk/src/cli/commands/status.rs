// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn run(workspace_id: &str, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.workspaces().await?;
        let workspace = svc.get_workspace(workspace_id).await?;

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("id".into(), Value::String(workspace.id));
        m.insert("name".into(), Value::String(workspace.name));
        m.insert("path".into(), Value::String(workspace.project_path));
        m.insert(
            "created".into(),
            Value::String(workspace.created_at.to_string()),
        );
        fmt.print_item(&m);
        Ok(())
    })
    .await
}
