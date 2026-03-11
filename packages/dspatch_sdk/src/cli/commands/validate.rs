// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::path::Path;

use crate::util::error::AppError;
use crate::util::result::Result;
use crate::workspace_config::{parser, validation};

pub async fn run(path: Option<&str>) -> Result<()> {
    let dir = path
        .map(|s| s.to_string())
        .unwrap_or_else(|| {
            std::env::current_dir()
                .map(|p| p.to_string_lossy().into_owned())
                .unwrap_or_else(|_| ".".to_string())
        });

    let project_path = Path::new(&dir);
    let config = parser::parse_workspace_config_file(project_path).map_err(|e| {
        AppError::Validation(format!("{}", e))
    })?;

    let errors = validation::validate_config(&config);

    if errors.is_empty() {
        println!(
            "Config is valid: \"{}\" with {} agent(s).",
            config.name,
            config.agents.len()
        );
    } else {
        println!("Validation errors:");
        for error in &errors {
            println!("  - {}: {}", error.field, error.message);
        }
        return Err(AppError::Validation(
            "Workspace config has validation errors".into(),
        ));
    }

    Ok(())
}
