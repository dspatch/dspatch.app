// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn run(json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.workspaces().await?;
        let workspaces = svc.list_workspaces()?;

        let fmt = OutputFormatter::new(json);
        let items: Vec<Map<String, Value>> = workspaces
            .iter()
            .map(|w| {
                let mut m = Map::new();
                m.insert("id".into(), Value::String(w.id.clone()));
                m.insert("name".into(), Value::String(w.name.clone()));
                m.insert("path".into(), Value::String(w.project_path.clone()));
                m.insert("created".into(), Value::String(w.created_at.to_string()));
                m
            })
            .collect();

        fmt.print_list(&items, &["id", "name", "path", "created"]);
        Ok(())
    })
    .await
}
