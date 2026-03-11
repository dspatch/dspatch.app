// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use clap::Parser;
use dspatch_sdk::cli::{run_command, Cli};

#[tokio::main]
async fn main() {
    let cli = Cli::parse();
    if let Err(e) = run_command(cli).await {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}
