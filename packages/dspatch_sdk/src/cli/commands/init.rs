// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::path::Path;

use crate::util::error::AppError;
use crate::util::result::Result;

const TEMPLATE: &str = r#"# d:spatch Workspace Configuration
# See https://docs.dspatch.dev/config for full reference.

name: my-workspace

# Global environment variables shared by all agents.
# env:
#   SOME_VAR: value

# Agent definitions. Each key is the agent's unique identifier.
agents:
  main:
    template: my-agent-template
    # Per-agent environment variable overrides.
    # env:
    #   AGENT_SPECIFIC_VAR: value
    # peers:
    #   - other-agent
    # sub_agents:
    #   helper:
    #     template: helper-template

# Additional host mounts into the container.
# mounts:
#   - host_path: /path/on/host
#     container_path: /data
#     read_only: true

# Docker resource limits.
# docker:
#   memory_limit: 4g
#   cpu_limit: 2.0
#   network_mode: bridge
#   ports:
#     - "8080:8080"
"#;

pub async fn run(path: Option<&str>) -> Result<()> {
    let dir = path
        .map(|s| s.to_string())
        .unwrap_or_else(|| {
            std::env::current_dir()
                .map(|p| p.to_string_lossy().into_owned())
                .unwrap_or_else(|_| ".".to_string())
        });

    let file_path = Path::new(&dir).join("dspatch.workspace.yml");

    if file_path.exists() {
        return Err(AppError::Validation(format!(
            "dspatch.workspace.yml already exists in \"{}\"",
            dir
        )));
    }

    std::fs::write(&file_path, TEMPLATE).map_err(|e| {
        AppError::Storage(format!(
            "Failed to write {}: {}",
            file_path.display(),
            e
        ))
    })?;

    println!("Created dspatch.workspace.yml in \"{}\".", dir);
    Ok(())
}
