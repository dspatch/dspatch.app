// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::domain::enums::InquiryStatus;
use crate::util::result::Result;

pub async fn list(json: bool, pending: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.inquiries().await?;
        let all = svc.list_all_inquiries()?;

        let filtered: Vec<_> = if pending {
            all.into_iter()
                .filter(|i| i.inquiry.status == InquiryStatus::Pending)
                .collect()
        } else {
            all
        };

        let fmt = OutputFormatter::new(json);
        let items: Vec<Map<String, Value>> = filtered
            .iter()
            .map(|i| {
                let mut m = Map::new();
                m.insert("id".into(), Value::String(i.inquiry.id.clone()));
                m.insert("workspace".into(), Value::String(i.workspace_name.clone()));
                m.insert("agent".into(), Value::String(i.inquiry.agent_key.clone()));
                m.insert(
                    "status".into(),
                    Value::String(format!("{:?}", i.inquiry.status)),
                );
                m.insert(
                    "priority".into(),
                    Value::String(format!("{:?}", i.inquiry.priority)),
                );
                m.insert(
                    "created".into(),
                    Value::String(i.inquiry.created_at.to_string()),
                );
                m
            })
            .collect();

        fmt.print_list(&items, &["id", "workspace", "agent", "status", "priority", "created"]);
        Ok(())
    })
    .await
}

pub async fn respond(inquiry_id: &str, answer: &str) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.inquiries().await?;
        svc.respond_to_workspace_inquiry(inquiry_id, Some(answer), None)
            .await?;

        println!("Responded to inquiry \"{}\".", inquiry_id);
        Ok(())
    })
    .await
}

pub async fn info(inquiry_id: &str, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.inquiries().await?;
        let inquiry = svc.get_workspace_inquiry(inquiry_id)?
            .ok_or_else(|| {
                crate::util::error::AppError::NotFound(format!("Inquiry \"{}\" not found", inquiry_id))
            })?;

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("id".into(), Value::String(inquiry.id));
        m.insert("runId".into(), Value::String(inquiry.run_id));
        m.insert("agent".into(), Value::String(inquiry.agent_key));
        m.insert("instance".into(), Value::String(inquiry.instance_id));
        m.insert(
            "status".into(),
            Value::String(format!("{:?}", inquiry.status)),
        );
        m.insert(
            "priority".into(),
            Value::String(format!("{:?}", inquiry.priority)),
        );
        m.insert("content".into(), Value::String(inquiry.content_markdown));
        m.insert(
            "response".into(),
            inquiry
                .response_text
                .map(Value::String)
                .unwrap_or_else(|| Value::String("(none)".into())),
        );
        m.insert(
            "created".into(),
            Value::String(inquiry.created_at.to_string()),
        );
        m.insert(
            "respondedAt".into(),
            inquiry
                .responded_at
                .map(|dt| Value::String(dt.to_string()))
                .unwrap_or_else(|| Value::String("(none)".into())),
        );
        fmt.print_item(&m);
        Ok(())
    })
    .await
}
