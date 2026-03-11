// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::path::Path;

use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::domain::models::CreateWorkspaceRequest;
use crate::util::error::AppError;
use crate::util::result::Result;

pub async fn create(path: Option<&str>, json: bool) -> Result<()> {
    let dir = path
        .map(|s| s.to_string())
        .unwrap_or_else(|| {
            std::env::current_dir()
                .map(|p| p.to_string_lossy().into_owned())
                .unwrap_or_else(|_| ".".to_string())
        });

    let config_path = Path::new(&dir).join("dspatch.workspace.yml");
    if !config_path.exists() {
        eprintln!(
            "Error: dspatch.workspace.yml not found in \"{}\".\nRun \"dspatch init\" to create one.",
            dir
        );
        return Err(AppError::Validation(format!(
            "dspatch.workspace.yml not found in \"{}\"",
            dir
        )));
    }
    let config_yaml = std::fs::read_to_string(&config_path).map_err(|e| {
        AppError::Storage(format!(
            "Failed to read {}: {}",
            config_path.display(),
            e
        ))
    })?;

    with_sdk(|sdk| async move {
        let svc = sdk.workspaces().await?;
        let request = CreateWorkspaceRequest {
            project_path: dir,
            config_yaml,
        };
        let workspace = svc.create_workspace(request).await?;

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

pub async fn delete(workspace_id: &str) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.workspaces().await?;
        svc.delete_workspace(workspace_id).await?;

        println!("Workspace \"{}\" deleted.", workspace_id);
        Ok(())
    })
    .await
}

pub async fn info(workspace_id: &str, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.workspaces().await?;
        let w = svc.get_workspace(workspace_id).await?;

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("id".into(), Value::String(w.id));
        m.insert("name".into(), Value::String(w.name));
        m.insert("path".into(), Value::String(w.project_path));
        m.insert(
            "created".into(),
            Value::String(w.created_at.to_string()),
        );
        m.insert(
            "updated".into(),
            Value::String(w.updated_at.to_string()),
        );
        fmt.print_item(&m);
        Ok(())
    })
    .await
}
