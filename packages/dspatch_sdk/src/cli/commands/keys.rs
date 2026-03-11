// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::io::{self, BufRead};

use futures::StreamExt;
use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn list(json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.api_keys().await?;
        let mut stream = svc.watch_api_keys();
        let keys = stream.next().await.unwrap_or_default();

        let fmt = OutputFormatter::new(json);
        let items: Vec<Map<String, Value>> = keys
            .iter()
            .map(|k| {
                let mut m = Map::new();
                m.insert("id".into(), Value::String(k.id.clone()));
                m.insert("name".into(), Value::String(k.name.clone()));
                m.insert("provider".into(), Value::String(k.provider_label.clone()));
                m.insert(
                    "hint".into(),
                    k.display_hint
                        .as_ref()
                        .map(|s| Value::String(s.clone()))
                        .unwrap_or(Value::Null),
                );
                m.insert("created".into(), Value::String(k.created_at.to_string()));
                m
            })
            .collect();

        fmt.print_list(&items, &["id", "name", "provider", "hint", "created"]);
        Ok(())
    })
    .await
}

pub async fn add(name: &str, provider: &str, key: Option<&str>) -> Result<()> {
    let key_value = match key {
        Some(k) => k.to_string(),
        None => {
            eprintln!("Enter API key: ");
            let mut line = String::new();
            io::stdin()
                .lock()
                .read_line(&mut line)
                .map_err(|e| crate::util::error::AppError::Internal(format!("Failed to read stdin: {e}")))?;
            line.trim().to_string()
        }
    };

    if key_value.is_empty() {
        return Err(crate::util::error::AppError::Validation(
            "API key cannot be empty".into(),
        ));
    }

    let hint = if key_value.len() > 8 {
        let first: String = key_value.chars().take(4).collect();
        let last: String = key_value.chars().rev().take(4).collect::<String>().chars().rev().collect();
        format!("{first}...{last}")
    } else {
        "****".to_string()
    };

    with_sdk(|sdk| async move {
        let encrypted = sdk.crypto().encrypt_string(&key_value, "api_key").await?;

        let svc = sdk.api_keys().await?;
        svc.create_api_key(name, provider, encrypted, Some(&hint))
            .await?;

        println!("API key \"{}\" added.", name);
        Ok(())
    })
    .await
}

pub async fn remove(key_id: &str) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.api_keys().await?;
        svc.delete_api_key(key_id).await?;

        println!("API key \"{}\" removed.", key_id);
        Ok(())
    })
    .await
}
