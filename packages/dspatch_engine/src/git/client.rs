// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Git CLI client that shells out to the `git` binary.
//!
//! All methods invoke `git <subcommand>` via [`GitCli`] and parse the result.
//! Mirrors the `DockerClient` pattern from `src/docker/client.rs`.

use std::process::Output;

use regex_lite::Regex;

use super::cli::{GitCli, GitCliException};

/// Git CLI client with typed methods for common operations.
pub struct GitClient {
    cli: GitCli,
}

impl GitClient {
    pub fn new(cli: GitCli) -> Self {
        Self { cli }
    }

    /// Creates a client using the default [`GitCli`] (real process calls).
    pub fn for_platform() -> Self {
        Self::new(GitCli::new())
    }

    // ─── Helpers ────────────────────────────────────────────────────────

    /// Returns `Err` if the output has a non-zero exit code.
    fn check_result(output: &Output) -> Result<(), GitCliException> {
        if !output.status.success() {
            let exit_code = output.status.code().unwrap_or(-1);
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            return Err(GitCliException::new(stderr, exit_code));
        }
        Ok(())
    }

    /// Parses stdout as a trimmed UTF-8 string. Returns `None` if empty.
    fn stdout_trimmed(output: &Output) -> Option<String> {
        let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if s.is_empty() { None } else { Some(s) }
    }

    // ─── Public API ─────────────────────────────────────────────────────

    /// Checks whether `directory` contains a `.git/` subdirectory.
    /// Does not invoke a process.
    pub fn is_git_repository(directory: &str) -> bool {
        std::path::Path::new(directory).join(".git").exists()
    }

    /// Returns the URL of the given remote (default: `origin`).
    pub async fn remote_url(
        &self,
        directory: &str,
        remote: &str,
    ) -> Result<Option<String>, GitCliException> {
        let output = self
            .cli
            .run(&["remote", "get-url", remote], directory)
            .await
            .map_err(|e| GitCliException::new(e.to_string(), -1))?;
        if !output.status.success() {
            // No remote configured — not an error, just None.
            return Ok(None);
        }
        Ok(Self::stdout_trimmed(&output))
    }

    /// Returns the current branch name, or `None` if in detached HEAD state.
    pub async fn current_branch(
        &self,
        directory: &str,
    ) -> Result<Option<String>, GitCliException> {
        let output = self
            .cli
            .run(&["rev-parse", "--abbrev-ref", "HEAD"], directory)
            .await
            .map_err(|e| GitCliException::new(e.to_string(), -1))?;
        if !output.status.success() {
            return Ok(None);
        }
        let branch = Self::stdout_trimmed(&output);
        // `git rev-parse --abbrev-ref HEAD` returns "HEAD" when detached.
        Ok(branch.filter(|b| b != "HEAD"))
    }

    /// Returns `true` if the working tree has uncommitted changes
    /// (staged or unstaged).
    pub async fn has_uncommitted_changes(
        &self,
        directory: &str,
    ) -> Result<bool, GitCliException> {
        let output = self
            .cli
            .run(&["status", "--porcelain"], directory)
            .await
            .map_err(|e| GitCliException::new(e.to_string(), -1))?;
        if !output.status.success() {
            return Ok(false);
        }
        Ok(Self::stdout_trimmed(&output).is_some())
    }

    /// Returns `true` if there are local commits not yet pushed to `origin/{branch}`.
    pub async fn has_unpushed_commits(
        &self,
        directory: &str,
        branch: &str,
    ) -> Result<bool, GitCliException> {
        let range = format!("origin/{branch}..HEAD");
        let output = self
            .cli
            .run(&["log", &range, "--oneline"], directory)
            .await
            .map_err(|e| GitCliException::new(e.to_string(), -1))?;
        if !output.status.success() {
            // May fail if origin/{branch} doesn't exist — treat as "no info".
            return Ok(false);
        }
        Ok(Self::stdout_trimmed(&output).is_some())
    }

    /// Converts an SSH git URL (`user@host:path`) to HTTPS format.
    /// Returns the input unchanged if it doesn't match the SSH pattern.
    pub fn ssh_to_https_url(url: &str) -> String {
        let re = Regex::new(r"^([\w.\-]+)@([\w.\-]+):(.+)$").unwrap();
        match re.captures(url) {
            Some(caps) => {
                let host = &caps[2];
                let path = &caps[3];
                format!("https://{host}/{path}")
            }
            None => url.to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ssh_to_https_github() {
        assert_eq!(
            GitClient::ssh_to_https_url("git@github.com:org/repo.git"),
            "https://github.com/org/repo.git"
        );
    }

    #[test]
    fn ssh_to_https_passthrough() {
        let https = "https://github.com/org/repo.git";
        assert_eq!(GitClient::ssh_to_https_url(https), https);
    }
}
