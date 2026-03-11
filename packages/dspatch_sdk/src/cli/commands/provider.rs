// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;
use std::path::Path;

use futures::StreamExt;
use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk;
use crate::domain::enums::SourceType;
use crate::domain::models::{CreateAgentProviderRequest, UpdateAgentProviderRequest};
use crate::util::error::AppError;
use crate::util::result::Result;

pub async fn list(json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.providers().await?;
        let mut stream = svc.watch_agent_providers();
        let providers = stream.next().await.unwrap_or_default();

        let fmt = OutputFormatter::new(json);
        let items: Vec<Map<String, Value>> = providers
            .iter()
            .map(|t| {
                let mut m = Map::new();
                m.insert("id".into(), Value::String(t.id.clone()));
                m.insert("name".into(), Value::String(t.name.clone()));
                m.insert(
                    "source".into(),
                    Value::String(format!("{:?}", t.source_type)),
                );
                m.insert("entryPoint".into(), Value::String(t.entry_point.clone()));
                m.insert("created".into(), Value::String(t.created_at.to_string()));
                m.insert("updated".into(), Value::String(t.updated_at.to_string()));
                m
            })
            .collect();

        fmt.print_list(&items, &["id", "name", "source", "entryPoint", "created", "updated"]);
        Ok(())
    })
    .await
}

pub async fn info(provider_id: &str, json: bool) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.providers().await?;
        let t = svc.get_agent_provider(provider_id).await?;

        let fmt = OutputFormatter::new(json);
        let mut m = Map::new();
        m.insert("id".into(), Value::String(t.id));
        m.insert("name".into(), Value::String(t.name));
        m.insert(
            "sourceType".into(),
            Value::String(format!("{:?}", t.source_type)),
        );
        m.insert(
            "sourcePath".into(),
            t.source_path
                .map(Value::String)
                .unwrap_or_else(|| Value::String("(none)".into())),
        );
        m.insert(
            "gitUrl".into(),
            t.git_url
                .map(Value::String)
                .unwrap_or_else(|| Value::String("(none)".into())),
        );
        m.insert(
            "gitBranch".into(),
            t.git_branch
                .map(Value::String)
                .unwrap_or_else(|| Value::String("(none)".into())),
        );
        m.insert("entryPoint".into(), Value::String(t.entry_point));
        m.insert(
            "description".into(),
            t.description
                .map(Value::String)
                .unwrap_or_else(|| Value::String("(none)".into())),
        );
        m.insert(
            "requiredEnv".into(),
            Value::Array(t.required_env.into_iter().map(Value::String).collect()),
        );
        m.insert(
            "created".into(),
            Value::String(t.created_at.to_string()),
        );
        m.insert(
            "updated".into(),
            Value::String(t.updated_at.to_string()),
        );
        fmt.print_item(&m);
        Ok(())
    })
    .await
}

pub async fn remove(provider_id: &str) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.providers().await?;
        svc.delete_agent_provider(provider_id).await?;

        println!("Provider \"{}\" removed.", provider_id);
        Ok(())
    })
    .await
}

/// YAML shape of `dspatch.agent.yml`.
#[derive(serde::Deserialize)]
#[allow(dead_code)] // Fields must exist for deserialization
struct AgentYml {
    name: String,
    #[serde(default)]
    description: Option<String>,
    entry_point: String,
    #[serde(default)]
    readme: Option<String>,
    #[serde(default)]
    post_install: Option<String>,
    #[serde(default)]
    required_env: Vec<String>,
    #[serde(default)]
    required_mounts: Vec<String>,
}

/// Returns `true` if the source looks like a git URL.
fn is_git_url(source: &str) -> bool {
    source.starts_with("https://")
        || source.starts_with("http://")
        || source.starts_with("git@")
        || source.starts_with("git://")
        || source.ends_with(".git")
}

pub async fn add(source: &str, branch: Option<&str>) -> Result<()> {
    with_sdk(|sdk| async move {
        let (source_type, source_path, git_url, dir_path) = if is_git_url(source) {
            (SourceType::Git, None, Some(source.to_string()), None)
        } else {
            let path = Path::new(source);
            if !path.exists() {
                return Err(AppError::Validation(format!(
                    "Directory does not exist: {}",
                    source
                )));
            }
            let abs = std::fs::canonicalize(path)
                .map_err(|e| AppError::Validation(format!("Cannot resolve path: {e}")))?;
            let abs_str = abs.to_string_lossy().to_string();
            (SourceType::Local, Some(abs_str), None, Some(abs))
        };

        // Read dspatch.agent.yml from local directory.
        let yml_path = if let Some(ref dir) = dir_path {
            dir.join("dspatch.agent.yml")
        } else {
            // For git sources we cannot read files without cloning.
            // Create provider with minimal info; user can edit later.
            println!("Git source detected. Provider will be created with the git URL.");
            println!("Run `dspatch provider edit <id> <property> <value>` to set fields after cloning.\n");

            let name = source
                .rsplit('/')
                .next()
                .unwrap_or(source)
                .trim_end_matches(".git")
                .to_string();

            let request = CreateAgentProviderRequest {
                name: name.clone(),
                source_type,
                source_path: None,
                git_url: git_url.clone(),
                git_branch: branch.map(|b| b.to_string()),
                entry_point: "agent.py".to_string(),
                description: None,
                readme: None,
                required_env: vec![],
                required_mounts: vec![],
                fields: HashMap::new(),
                hub_slug: None,
                hub_author: None,
                hub_category: None,
                hub_tags: vec![],
                hub_version: None,
                hub_repo_url: None,
                hub_commit_hash: None,
            };

            let svc = sdk.providers().await?;
            let t = svc.create_agent_provider(request).await?;
            print_provider_summary(&t);
            return Ok(());
        };

        if !yml_path.exists() {
            return Err(AppError::Validation(format!(
                "No dspatch.agent.yml found in {}",
                source
            )));
        }

        let yml_content = std::fs::read_to_string(&yml_path)
            .map_err(|e| AppError::Validation(format!("Cannot read dspatch.agent.yml: {e}")))?;
        let agent_yml: AgentYml = serde_yaml::from_str(&yml_content)
            .map_err(|e| AppError::Validation(format!("Invalid dspatch.agent.yml: {e}")))?;

        // Read readme contents if specified.
        let readme_content = if let Some(ref readme_path) = agent_yml.readme {
            let full = dir_path.as_ref().unwrap().join(readme_path);
            if full.exists() {
                Some(
                    std::fs::read_to_string(&full)
                        .map_err(|e| AppError::Validation(format!("Cannot read readme: {e}")))?,
                )
            } else {
                println!("Warning: readme file \"{}\" not found, skipping.", readme_path);
                None
            }
        } else {
            None
        };

        let request = CreateAgentProviderRequest {
            name: agent_yml.name,
            source_type,
            source_path,
            git_url,
            git_branch: branch.map(|b| b.to_string()),
            entry_point: agent_yml.entry_point,
            description: agent_yml.description,
            readme: readme_content,
            required_env: agent_yml.required_env,
            required_mounts: agent_yml.required_mounts,
            fields: HashMap::new(),
            hub_slug: None,
            hub_author: None,
            hub_category: None,
            hub_tags: vec![],
            hub_version: None,
            hub_repo_url: None,
            hub_commit_hash: None,
        };

        let svc = sdk.providers().await?;
        let t = svc.create_agent_provider(request).await?;
        print_provider_summary(&t);
        Ok(())
    })
    .await
}

fn print_provider_summary(t: &crate::domain::models::AgentProvider) {
    println!("Provider imported successfully!\n");
    println!("  ID:            {}", t.id);
    println!("  Name:          {}", t.name);
    println!("  Source Type:    {:?}", t.source_type);
    if let Some(ref p) = t.source_path {
        println!("  Source Path:    {}", p);
    }
    if let Some(ref u) = t.git_url {
        println!("  Git URL:        {}", u);
    }
    if let Some(ref b) = t.git_branch {
        println!("  Git Branch:     {}", b);
    }
    println!("  Entry Point:   {}", t.entry_point);
    if let Some(ref d) = t.description {
        println!("  Description:   {}", d);
    }
    if let Some(ref r) = t.readme {
        let preview = if r.len() > 80 {
            format!("{}...", &r[..80])
        } else {
            r.clone()
        };
        println!("  Readme:        {}", preview);
    }
    if !t.required_env.is_empty() {
        println!("  Required Env:  {}", t.required_env.join(", "));
    }
    if !t.required_mounts.is_empty() {
        println!("  Required Mounts: {}", t.required_mounts.join(", "));
    }
    println!("  Created:       {}", t.created_at);
}

pub async fn edit(provider_id: &str, property: &str, value: &str) -> Result<()> {
    with_sdk(|sdk| async move {
        let svc = sdk.providers().await?;

        // Try lookup by ID first, then by name.
        let provider = match svc.get_agent_provider(provider_id).await {
            Ok(t) => t,
            Err(_) => match svc.get_agent_provider_by_name(provider_id).await? {
                Some(t) => t,
                None => {
                    return Err(AppError::NotFound(format!(
                        "Provider not found: {}",
                        provider_id
                    )));
                }
            },
        };

        let mut request = UpdateAgentProviderRequest {
            name: None,
            source_type: None,
            source_path: None,
            git_url: None,
            git_branch: None,
            entry_point: None,
            description: None,
            readme: None,
            required_env: None,
            required_mounts: None,
            fields: None,
            hub_slug: None,
            hub_author: None,
            hub_category: None,
            hub_tags: None,
            hub_version: None,
            hub_repo_url: None,
            hub_commit_hash: None,
        };

        match property {
            "name" => request.name = Some(value.to_string()),
            "description" => request.description = Some(value.to_string()),
            "entry_point" | "entryPoint" => request.entry_point = Some(value.to_string()),
            "source_path" | "sourcePath" => request.source_path = Some(value.to_string()),
            "git_url" | "gitUrl" => request.git_url = Some(value.to_string()),
            "git_branch" | "gitBranch" => request.git_branch = Some(value.to_string()),
            _ => {
                return Err(AppError::Validation(format!(
                    "Unknown property: \"{}\". Valid properties: name, description, entry_point, source_path, git_url, git_branch",
                    property
                )));
            }
        }

        let updated = svc.update_agent_provider(&provider.id, request).await?;

        println!("Provider \"{}\" updated.\n", updated.name);
        println!("  {} = {}", property, value);
        Ok(())
    })
    .await
}
