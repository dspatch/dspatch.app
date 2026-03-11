// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use futures::StreamExt;
use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn status(json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let docker = sdk.docker_service();
        let st = docker.detect_status().await?;

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("installed".into(), Value::Bool(st.is_installed));
        m.insert("running".into(), Value::Bool(st.is_running));
        m.insert("sysbox".into(), Value::Bool(st.has_sysbox));
        m.insert("nvidiaRuntime".into(), Value::Bool(st.has_nvidia_runtime));
        m.insert("runtimeImage".into(), Value::Bool(st.has_runtime_image));
        m.insert(
            "imageSize".into(),
            st.runtime_image_size
                .map(Value::String)
                .unwrap_or(Value::Null),
        );
        m.insert(
            "version".into(),
            st.docker_version
                .map(Value::String)
                .unwrap_or(Value::Null),
        );
        fmt.print_item(&m);
        Ok(())
    })
    .await
}

pub async fn build_runtime() -> Result<()> {
    with_sdk(|sdk| async move {
        println!("Building runtime image...");
        let docker = sdk.docker_service();
        let mut stream = docker.build_runtime_image();
        while let Some(line) = stream.next().await {
            println!("{}", line);
        }
        println!("Runtime image built successfully.");
        Ok(())
    })
    .await
}

pub async fn containers(json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let docker = sdk.docker_service();
        let containers = docker.list_containers().await?;

        let fmt = OutputFormatter::new(json);
        let items: Vec<Map<String, Value>> = containers
            .iter()
            .map(|c| {
                let mut m = Map::new();
                let id_display = if c.id.len() > 12 {
                    &c.id[..12]
                } else {
                    &c.id
                };
                m.insert("id".into(), Value::String(id_display.to_string()));
                m.insert(
                    "name".into(),
                    Value::String(
                        c.names
                            .first()
                            .map(|n| n.trim_start_matches('/').to_string())
                            .unwrap_or_else(|| "(unnamed)".to_string()),
                    ),
                );
                m.insert("image".into(), Value::String(c.image.clone()));
                m.insert("state".into(), Value::String(c.state.clone()));
                m.insert("status".into(), Value::String(c.status.clone()));
                m
            })
            .collect();

        fmt.print_list(&items, &["id", "name", "image", "state", "status"]);
        Ok(())
    })
    .await
}

pub async fn cleanup() -> Result<()> {
    with_sdk(|sdk| async move {
        let docker = sdk.docker_service();
        let orphaned = docker.clean_orphaned().await?;
        let stopped = docker.delete_stopped_containers().await?;

        println!(
            "Cleaned up: {} orphaned, {} stopped containers.",
            orphaned, stopped
        );
        Ok(())
    })
    .await
}
