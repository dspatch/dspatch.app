// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use futures::StreamExt;
use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::result::Result;

pub async fn run(
    run_id: &str,
    instance_id: &str,
    follow: bool,
    json: bool,
) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.agent_data().await?;
        let mut stream = svc.watch_agent_messages(run_id, instance_id);
        let fmt = OutputFormatter::new(json);

        if follow {
            while let Some(msgs) = stream.next().await {
                let items = messages_to_maps(&msgs);
                print_items_individually(&fmt, &items);
            }
        } else if let Some(msgs) = stream.next().await {
            let items = messages_to_maps(&msgs);
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

fn messages_to_maps(msgs: &[crate::domain::models::AgentMessage]) -> Vec<Map<String, Value>> {
    msgs.iter()
        .map(|msg| {
            let mut m = Map::new();
            m.insert(
                "timestamp".into(),
                Value::String(msg.created_at.to_string()),
            );
            m.insert("role".into(), Value::String(msg.role.clone()));
            m.insert("content".into(), Value::String(msg.content.clone()));
            m.insert(
                "model".into(),
                msg.model
                    .as_ref()
                    .map(|s| Value::String(s.clone()))
                    .unwrap_or(Value::Null),
            );
            m.insert(
                "sender".into(),
                msg.sender_name
                    .as_ref()
                    .map(|s| Value::String(s.clone()))
                    .unwrap_or(Value::Null),
            );
            m
        })
        .collect()
}
