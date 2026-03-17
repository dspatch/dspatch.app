// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! dspatch engine daemon — standalone entry point.
//!
//! Starts the engine, opens/migrates the database via the SDK, starts the
//! client API server on the configured port, and runs until Ctrl+C (or
//! SIGTERM on Unix).

use std::sync::Arc;

use clap::Parser;

use dspatch_engine::client_api::server::{start_client_api, AppState};
use dspatch_engine::engine::config::EngineConfig;
use dspatch_engine::engine::startup::{init_tracing, wait_for_shutdown_signal};
use dspatch_engine::sdk::DspatchSdk;
use dspatch_engine::util::id::new_id;

/// dspatch engine daemon.
#[derive(Parser)]
#[command(name = "dspatch-daemon")]
struct Args {
    /// Run with an isolated temporary database and OS-assigned port.
    /// Prints a JSON bootstrap line to stdout: {"port": N, "db_dir": "..."}
    #[arg(long)]
    test_db: bool,
}

#[tokio::main]
async fn main() {
    let args = Args::parse();
    let mut config = EngineConfig::default();

    // In test mode, use a random temp directory and OS-assigned port.
    let test_dir = if args.test_db {
        let dir = std::env::temp_dir().join(format!("dspatch-test-{}", new_id()));
        std::fs::create_dir_all(&dir).expect("failed to create test db directory");
        config.db_dir = dir.clone();
        config.test_mode = true;
        Some(dir)
    } else {
        None
    };

    // 1. Initialize tracing/logging.
    init_tracing(&config.log_level);

    tracing::info!(
        port = config.client_api_port,
        db_dir = %config.db_dir.display(),
        "dspatch engine starting"
    );

    // 2. Create and initialize the SDK.
    let sdk_config = dspatch_engine::config::DspatchConfig::from_engine_config(&config);
    let sdk = Arc::new(DspatchSdk::with_secret_store(
        sdk_config,
        Box::new(dspatch_engine::crypto::KeyringSecretStore::new("dspatch")),
        config.db_dir.clone(),
    ));

    if let Err(e) = sdk.initialize().await {
        tracing::error!(error = %e, "failed to initialize SDK — exiting");
        std::process::exit(1);
    }
    tracing::info!("SDK initialized, database ready");

    // 3. Create runtime and AppState.
    let runtime = sdk.create_runtime(config).await;
    let state = AppState {
        sdk: Arc::clone(&sdk),
        runtime: Arc::clone(&runtime),
    };

    // 4. Start the client API server in a background task.
    let shutdown_rx = runtime.subscribe_shutdown();

    // In test mode, use a oneshot channel to get the actual bound port.
    let port_tx = if test_dir.is_some() {
        let (tx, rx) = tokio::sync::oneshot::channel::<u16>();
        Some((tx, rx))
    } else {
        None
    };

    let (sender, receiver) = match port_tx {
        Some((tx, rx)) => (Some(tx), Some(rx)),
        None => (None, None),
    };

    // Session cleanup task.
    let cleanup_runtime = Arc::clone(&runtime);
    let mut cleanup_shutdown = runtime.subscribe_shutdown();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(std::time::Duration::from_secs(60));
        loop {
            tokio::select! {
                _ = interval.tick() => {
                    cleanup_runtime.session_store().remove_expired();
                }
                _ = cleanup_shutdown.recv() => break,
            }
        }
    });

    let api_handle = tokio::spawn(async move {
        if let Err(e) = start_client_api(state, shutdown_rx, sender).await {
            tracing::error!(error = %e, "client API server failed");
        }
    });

    // In test mode, wait for the port and print the JSON bootstrap line.
    if let (Some(rx), Some(ref dir)) = (receiver, &test_dir) {
        match rx.await {
            Ok(port) => {
                let bootstrap = serde_json::json!({
                    "port": port,
                    "db_dir": dir.to_string_lossy(),
                });
                println!("{bootstrap}");
            }
            Err(_) => {
                tracing::error!("failed to receive bound port from client API server");
                std::process::exit(1);
            }
        }
    }

    // 5. Wait for shutdown signal (Ctrl+C / SIGTERM).
    wait_for_shutdown_signal().await;

    // 6. Trigger graceful shutdown.
    tracing::info!("shutting down...");
    runtime.trigger_shutdown();

    // 7. Wait for the server to finish.
    let _ = tokio::time::timeout(
        std::time::Duration::from_secs(10),
        api_handle,
    )
    .await;

    tracing::info!("dspatch engine stopped");

    // 8. Clean up test directory on shutdown.
    if let Some(dir) = test_dir {
        if let Err(e) = std::fs::remove_dir_all(&dir) {
            tracing::warn!(error = %e, "failed to clean up test directory");
        } else {
            tracing::info!(dir = %dir.display(), "test directory cleaned up");
        }
    }
}
