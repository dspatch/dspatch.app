// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! dspatch engine daemon — standalone entry point.
//!
//! Starts the engine, opens/migrates the database, starts the client API
//! server on the configured port, and runs until Ctrl+C (or SIGTERM on Unix).

use std::sync::Arc;

use dspatch_sdk::engine::config::EngineConfig;
use dspatch_sdk::engine::service_registry::ServiceRegistry;
use dspatch_sdk::engine::startup::{
    init_tracing, open_database, wait_for_shutdown_signal, EngineRuntime,
};
use dspatch_sdk::client_api::server::start_client_api;

#[tokio::main]
async fn main() {
    let config = EngineConfig::default();

    // 1. Initialize tracing/logging.
    init_tracing(&config.log_level);

    tracing::info!(
        port = config.client_api_port,
        db_dir = %config.db_dir.display(),
        "dspatch engine starting"
    );

    // 2. Open/migrate the database.
    let db_path = config.db_dir.join("engine.db");
    let db = match open_database(&db_path) {
        Ok(db) => {
            tracing::info!("database initialized successfully");
            Arc::new(db)
        }
        Err(e) => {
            tracing::error!(error = %e, "failed to open database — exiting");
            std::process::exit(1);
        }
    };

    // 3. Create the service registry and engine runtime.
    let registry = Arc::new(ServiceRegistry::new(db, config.db_dir.clone()));
    let runtime = Arc::new(EngineRuntime::with_services(config, registry));

    // 4. Start the client API server in a background task.
    let api_runtime = runtime.clone();
    let shutdown_rx = runtime.subscribe_shutdown();
    let api_handle = tokio::spawn(async move {
        if let Err(e) = start_client_api(api_runtime, shutdown_rx).await {
            tracing::error!(error = %e, "client API server failed");
        }
    });

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
}
