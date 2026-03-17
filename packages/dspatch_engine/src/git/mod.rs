// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Git CLI wrapper and client for repository inspection.
//!
//! Mirrors the `docker/` module structure.

mod cli;
mod client;

pub use cli::{GitCli, GitCliException};
pub use client::GitClient;
