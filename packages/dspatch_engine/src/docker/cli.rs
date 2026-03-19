// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Thin wrapper around `tokio::process::Command` for Docker CLI invocations.
//!
//! Ported from `data/docker/docker_cli.dart`.

use std::fmt;
use std::process::Output;
use std::time::Duration;

use tokio::process::{Child, Command};
use tokio::time::timeout;

/// Prevents child processes from spawning visible console windows on Windows.
#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x0800_0000;

/// Maximum time to wait for any Docker CLI command to complete.
const DOCKER_CLI_TIMEOUT: Duration = Duration::from_secs(120);

use once_cell::sync::OnceCell;

/// Cached path to the `docker` binary.
static DOCKER_BINARY: OnceCell<String> = OnceCell::new();

/// Thin wrapper around [`tokio::process::Command`] for Docker CLI invocations.
///
/// Production code uses the default constructor which delegates to the
/// system `docker` binary. Tests can provide a custom `DockerCli` with
/// a different binary path.
#[derive(Debug, Clone)]
pub struct DockerCli {
    binary: Option<String>,
}

impl DockerCli {
    /// Creates a new CLI wrapper that auto-detects the docker binary.
    pub fn new() -> Self {
        Self { binary: None }
    }

    /// Creates a CLI wrapper with a specific binary path (for testing).
    #[cfg(test)]
    pub fn with_binary(binary: impl Into<String>) -> Self {
        Self {
            binary: Some(binary.into()),
        }
    }

    /// Resolves the full path to the `docker` binary.
    ///
    /// On macOS, GUI apps inherit a minimal PATH that excludes
    /// `/usr/local/bin` (where Docker Desktop installs the CLI).
    /// We check well-known locations as fallback.
    async fn docker_binary(&self) -> &str {
        if let Some(ref binary) = self.binary {
            return binary.as_str();
        }

        DOCKER_BINARY
            .get_or_init(|| {
                // Try bare `docker` first. If the binary exists on PATH, use it.
                // On failure, check well-known locations.
                #[cfg(unix)]
                {
                    let candidates = [
                        "/usr/local/bin/docker",
                        "/opt/homebrew/bin/docker",
                        "/usr/bin/docker",
                    ];
                    for path in &candidates {
                        if std::path::Path::new(path).exists() {
                            return path.to_string();
                        }
                    }
                }
                "docker".to_string()
            })
            .as_str()
    }

    /// Runs `docker <args>` and waits for completion.
    ///
    /// Times out after [`DOCKER_CLI_TIMEOUT`] to prevent hung Docker daemons
    /// from stalling the engine indefinitely.
    pub async fn run(&self, args: &[&str]) -> std::io::Result<Output> {
        let binary = self.docker_binary().await;
        let mut cmd = Command::new(binary);
        cmd.args(args);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        timeout(DOCKER_CLI_TIMEOUT, cmd.output())
            .await
            .map_err(|_| std::io::Error::new(
                std::io::ErrorKind::TimedOut,
                format!("Docker command timed out after {}s", DOCKER_CLI_TIMEOUT.as_secs()),
            ))?
    }

    /// Starts `docker <args>` for streaming stdout (builds, logs).
    pub async fn start(&self, args: &[&str]) -> std::io::Result<Child> {
        let binary = self.docker_binary().await;
        let mut cmd = Command::new(binary);
        cmd.args(args)
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped());
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        cmd.spawn()
    }
}

impl Default for DockerCli {
    fn default() -> Self {
        Self::new()
    }
}

/// Exception thrown when a Docker CLI command fails.
///
/// Wraps the process stderr and exit code from a failed `docker` command.
#[derive(Debug, Clone)]
pub struct DockerCliException {
    /// Standard error output from the failed command.
    pub stderr: String,
    /// Process exit code (non-zero indicates failure).
    pub exit_code: i32,
}

impl DockerCliException {
    pub fn new(stderr: impl Into<String>, exit_code: i32) -> Self {
        Self {
            stderr: stderr.into(),
            exit_code,
        }
    }

    /// Human-readable error message, preferring stderr content.
    pub fn message(&self) -> String {
        let trimmed = self.stderr.trim();
        if !trimmed.is_empty() {
            trimmed.to_string()
        } else {
            format!("Docker command failed (exit code {})", self.exit_code)
        }
    }
}

impl fmt::Display for DockerCliException {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "DockerCliException: {}", self.message())
    }
}

impl std::error::Error for DockerCliException {}
