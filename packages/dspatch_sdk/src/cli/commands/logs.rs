// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use futures::StreamExt;
use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn run(
    run_id: &str,
    follow: bool,
    instance: Option<&str>,
    json: bool,
) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.agent_data().await?;
        let mut stream = svc.watch_agent_logs(run_id, instance);
        let fmt = OutputFormatter::new(json);

        if follow {
            while let Some(logs) = stream.next().await {
                let items = logs_to_maps(&logs);
                print_items_individually(&fmt, &items);
            }
        } else if let Some(logs) = stream.next().await {
            let items = logs_to_maps(&logs);
            print_items_individually(&fmt, &items);
        }
        Ok(())
    })
    .await
}

fn print_items_individually(fmt: &OutputFormatter, items: &[Map<String, Value>]) {
    for (i, item) in items.iter().enumerate() {
        fmt.print_item(item);
        if !fmt.json && i + 1 < items.len() {
            println!();
        }
    }
}

fn logs_to_maps(logs: &[crate::domain::models::AgentLog]) -> Vec<Map<String, Value>> {
    logs.iter()
        .map(|log| {
            let mut m = Map::new();
            m.insert("timestamp".into(), Value::String(log.timestamp.to_string()));
            m.insert("level".into(), Value::String(format!("{:?}", log.level)));
            m.insert("agent".into(), Value::String(log.agent_key.clone()));
            m.insert("instance".into(), Value::String(log.instance_id.clone()));
            m.insert("message".into(), Value::String(log.message.clone()));
            m
        })
        .collect()
}
