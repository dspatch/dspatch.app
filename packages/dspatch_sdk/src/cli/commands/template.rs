// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::util::error::AppError;
use crate::util::result::Result;

pub async fn list(json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.templates().await?;
        let templates = svc.list_agent_templates()?;

        let fmt = OutputFormatter::new(json);
        let items: Vec<Map<String, Value>> = templates
            .iter()
            .map(|t| {
                let mut m = Map::new();
                m.insert("id".into(), Value::String(t.id.clone()));
                m.insert("name".into(), Value::String(t.name.clone()));
                m.insert("sourceUri".into(), Value::String(t.source_uri.clone()));
                m.insert("filePath".into(), Value::String(t.file_path.clone()));
                m
            })
            .collect();

        fmt.print_list(&items, &["id", "name", "sourceUri", "filePath"]);
        Ok(())
    })
    .await
}

pub async fn info(id_or_name: &str, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.templates().await?;

        // Try lookup by ID first, then by name.
        let t = match svc.get_agent_template(id_or_name).await {
            Ok(t) => t,
            Err(_) => match svc.get_agent_template_by_name(id_or_name).await? {
                Some(t) => t,
                None => {
                    return Err(AppError::NotFound(format!(
                        "Template not found: {}",
                        id_or_name
                    )));
                }
            },
        };

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("id".into(), Value::String(t.id));
        m.insert("name".into(), Value::String(t.name));
        m.insert("sourceUri".into(), Value::String(t.source_uri));
        m.insert("filePath".into(), Value::String(t.file_path.clone()));
        m.insert(
            "created".into(),
            Value::String(t.created_at.to_string()),
        );
        m.insert(
            "updated".into(),
            Value::String(t.updated_at.to_string()),
        );
        fmt.print_item(&m);

        // Print file contents if the file exists.
        let path = std::path::Path::new(&t.file_path);
        if path.exists() {
            println!("\n--- {} ---", t.file_path);
            match std::fs::read_to_string(path) {
                Ok(contents) => print!("{}", contents),
                Err(e) => println!("(could not read file: {})", e),
            }
        } else {
            println!("\n(config file not found: {})", t.file_path);
        }

        Ok(())
    })
    .await
}

pub async fn create(provider_name_or_uri: &str, name: Option<&str>, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let source_uri = if provider_name_or_uri.starts_with("dspatch://agent/") {
            provider_name_or_uri.to_string()
        } else {
            // Look up the provider by name and construct the URI from hub fields.
            let provider_svc = sdk.providers().await?;
            let provider = match provider_svc
                .get_agent_provider_by_name(provider_name_or_uri)
                .await?
            {
                Some(p) => p,
                None => {
                    return Err(AppError::NotFound(format!(
                        "Provider not found: {}",
                        provider_name_or_uri
                    )));
                }
            };

            let hub_author = provider.hub_author.ok_or_else(|| {
                AppError::Validation(
                    "Provider has no hub_author. Only hub providers can be templated (for now)."
                        .into(),
                )
            })?;
            let hub_slug = provider.hub_slug.ok_or_else(|| {
                AppError::Validation(
                    "Provider has no hub_slug. Only hub providers can be templated (for now)."
                        .into(),
                )
            })?;

            format!("dspatch://agent/{}/{}", hub_author, hub_slug)
        };

        let template_name = name.unwrap_or(provider_name_or_uri);

        let template_svc = sdk.templates().await?;
        let t = template_svc
            .create_agent_template(template_name, &source_uri)
            .await?;

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("id".into(), Value::String(t.id));
        m.insert("name".into(), Value::String(t.name));
        m.insert("sourceUri".into(), Value::String(t.source_uri));
        m.insert("filePath".into(), Value::String(t.file_path));
        m.insert(
            "created".into(),
            Value::String(t.created_at.to_string()),
        );

        if json {
            fmt.print_item(&m);
        } else {
            println!("Template created successfully!\n");
            println!("  ID:          {}", m["id"]);
            println!("  Name:        {}", m["name"]);
            println!("  Source URI:   {}", m["sourceUri"]);
            println!("  File Path:   {}", m["filePath"]);
            println!("  Created:     {}", m["created"]);
        }

        Ok(())
    })
    .await
}

pub async fn remove(id: &str, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.templates().await?;
        svc.delete_agent_template(id).await?;

        if json {
            let fmt = OutputFormatter::new(json);
            let mut m = Map::new();
            m.insert("deleted".into(), Value::String(id.to_string()));
            fmt.print_item(&m);
        } else {
            println!("Template \"{}\" removed.", id);
        }

        Ok(())
    })
    .await
}

pub async fn submit(
    name_or_id: &str,
    description: Option<&str>,
    category: Option<&str>,
    tags: Option<&str>,
    json: bool,
) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.templates().await?;

        // Look up template by name or ID.
        let t = match svc.get_agent_template(name_or_id).await {
            Ok(t) => t,
            Err(_) => match svc.get_agent_template_by_name(name_or_id).await? {
                Some(t) => t,
                None => {
                    return Err(AppError::NotFound(format!(
                        "Template not found: {}",
                        name_or_id
                    )));
                }
            },
        };

        // Read the config YAML.
        let config_yaml = std::fs::read_to_string(&t.file_path).map_err(|e| {
            AppError::Storage(format!("Failed to read {}: {}", t.file_path, e))
        })?;

        // Extract source_slug from sourceUri: dspatch://agent/<author>/<slug>
        if !t.source_uri.starts_with("dspatch://agent/") {
            return Err(AppError::Validation(format!(
                "Invalid source URI: {}. Must be dspatch://agent/<author>/<slug>",
                t.source_uri
            )));
        }

        let tags_json: Option<Vec<serde_json::Value>> = tags.map(|t| {
            t.split(',')
                .map(|s| serde_json::json!({"slug": s.trim(), "category": "general"}))
                .collect()
        });

        let hc = sdk.hub_client().read().await;
        hc.submit_template(
            &t.name,
            &config_yaml,
            &t.source_uri,
            description,
            category,
            tags_json.as_deref(),
        )
        .await
        .map_err(|e| AppError::Api {
            message: e.to_string(),
            status_code: None,
            body: None,
        })?;

        if json {
            let fmt = OutputFormatter::new(json);
            let mut m = Map::new();
            m.insert("submitted".into(), Value::String(t.name));
            m.insert("sourceUri".into(), Value::String(t.source_uri.clone()));
            fmt.print_item(&m);
        } else {
            println!("Template \"{}\" submitted to the hub.", t.name);
        }

        Ok(())
    })
    .await
}
