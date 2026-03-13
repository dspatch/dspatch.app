// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use tracing_subscriber::{fmt, EnvFilter};

/// Initializes the global tracing subscriber for the d:spatch SDK.
///
/// Uses `RUST_LOG` env var for filtering (defaults to `info`).
/// Output goes to stderr with timestamps and target modules.
pub fn init_logging() {
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));

    fmt()
        .with_env_filter(filter)
        .with_target(true)
        .with_thread_ids(false)
        .with_file(false)
        .with_line_number(false)
        .try_init()
        .ok();
}
