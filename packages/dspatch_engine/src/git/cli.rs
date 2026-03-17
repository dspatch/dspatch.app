// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Thin wrapper around `tokio::process::Command` for Git CLI invocations.
//!
//! Mirrors the `DockerCli` pattern from `src/docker/cli.rs`.

use std::fmt;
use std::process::Output;

use tokio::process::Command;

/// Prevents child processes from spawning visible console windows on Windows.
#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x0800_0000;

use once_cell::sync::OnceCell;

/// Cached path to the `git` binary.
static GIT_BINARY: OnceCell<String> = OnceCell::new();

/// Thin wrapper around [`tokio::process::Command`] for Git CLI invocations.
///
/// Unlike [`DockerCli`](crate::docker::DockerCli), every command requires a
/// `working_dir` parameter because git commands are always directory-scoped.
#[derive(Debug, Clone)]
pub struct GitCli {
    binary: Option<String>,
}

impl GitCli {
    /// Creates a new CLI wrapper that auto-detects the git binary.
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

    /// Resolves the full path to the `git` binary.
    ///
    /// On macOS, GUI apps inherit a minimal PATH that may exclude the
    /// git binary. We check well-known locations as fallback.
    fn git_binary(&self) -> &str {
        if let Some(ref binary) = self.binary {
            return binary.as_str();
        }

        GIT_BINARY
            .get_or_init(|| {
                #[cfg(unix)]
                {
                    let candidates = [
                        "/usr/bin/git",
                        "/usr/local/bin/git",
                        "/opt/homebrew/bin/git",
                    ];
                    for path in &candidates {
                        if std::path::Path::new(path).exists() {
                            return path.to_string();
                        }
                    }
                }
                "git".to_string()
            })
            .as_str()
    }

    /// Runs `git <args>` in the given directory and waits for completion.
    pub async fn run(&self, args: &[&str], working_dir: &str) -> std::io::Result<Output> {
        let binary = self.git_binary();
        let mut cmd = Command::new(binary);
        cmd.args(args).current_dir(working_dir);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        cmd.output().await
    }
}

impl Default for GitCli {
    fn default() -> Self {
        Self::new()
    }
}

/// Exception thrown when a Git CLI command fails.
#[derive(Debug, Clone)]
pub struct GitCliException {
    /// Standard error output from the failed command.
    pub stderr: String,
    /// Process exit code (non-zero indicates failure).
    pub exit_code: i32,
}

impl GitCliException {
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
            format!("Git command failed (exit code {})", self.exit_code)
        }
    }
}

impl fmt::Display for GitCliException {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "GitCliException: {}", self.message())
    }
}

impl std::error::Error for GitCliException {}
