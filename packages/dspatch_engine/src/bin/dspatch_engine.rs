// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! dspatch engine daemon — standalone entry point.
//!
//! Starts the engine, opens/migrates the database via the SDK, starts the
//! client API server on the configured port, and runs until Ctrl+C (or
//! SIGTERM on Unix).

use std::sync::Arc;

use clap::Parser;

use dspatch_engine::client_api::invalidation::InvalidationBroadcaster;
use dspatch_engine::client_api::server::start_client_api;
use dspatch_engine::engine::config::EngineConfig;
use dspatch_engine::engine::service_registry::ServiceRegistry;
use dspatch_engine::engine::startup::{
    init_tracing, wait_for_shutdown_signal, EngineRuntime,
};
use dspatch_engine::hub::HubApiClient;
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

    // Clone values from config before it gets moved into EngineRuntime.
    let db_dir = config.db_dir.clone();
    let invalidation_debounce_ms = config.invalidation_debounce_ms;
    let backend_url_for_hub = config.backend_url.clone();

    // 2. Create and initialize the SDK (replaces direct DB open).
    let sdk_config = dspatch_engine::config::DspatchConfig::from_engine_config(&config);
    let sdk = Arc::new(DspatchSdk::with_secret_store(
        sdk_config,
        Box::new(dspatch_engine::crypto::KeyringSecretStore::new("dspatch")),
        db_dir.clone(),
    ));

    if let Err(e) = sdk.initialize().await {
        tracing::error!(error = %e, "failed to initialize SDK — exiting");
        std::process::exit(1);
    }
    tracing::info!("SDK initialized, database ready");

    // 3. Get DB handle from SDK.
    let db = match sdk.database().await {
        Ok(db) => db,
        Err(e) => {
            tracing::error!(error = %e, "failed to get database from SDK — exiting");
            std::process::exit(1);
        }
    };

    // 4. Start the invalidation broadcaster.
    let broadcaster = InvalidationBroadcaster::new(
        db.tracker().clone(),
        config.invalidation_debounce_ms,
    );
    let invalidation_handle = broadcaster.start();

    // 5. Create hub client for backend API communication.
    let backend_url = backend_url_for_hub.unwrap_or_else(|| {
        if cfg!(debug_assertions) {
            "http://localhost:3000".to_string()
        } else {
            "https://backend.dspatch.dev".to_string()
        }
    });
    let hub_client = Arc::new(HubApiClient::new(&backend_url, None));
    tracing::info!(backend_url = %backend_url, "hub client configured");

    // 6. Create the service registry and engine runtime.
    let registry = Arc::new(ServiceRegistry::new(
        db,
        db_dir.clone(),
        Some(hub_client.clone()),
    ));
    let mut runtime = Arc::new(EngineRuntime::with_services_and_invalidation(
        config, registry, invalidation_handle,
    ));

    // Register hub client on session store so backend token updates
    // are automatically forwarded to the hub client's auth header.
    runtime.session_store().set_hub_client(Arc::clone(&hub_client));

    // Store SDK on runtime (safe: no clones of the Arc exist yet).
    Arc::get_mut(&mut runtime)
        .expect("runtime has no other references yet")
        .set_sdk(Arc::clone(&sdk));

    // 7. Bridge SDK database state changes → ephemeral events + service rebuild.
    {
        let ephemeral = runtime.ephemeral().clone_sender();
        let bridge_runtime = Arc::clone(&runtime);
        let bridge_sdk = Arc::clone(&sdk);
        let bridge_db_dir = db_dir.clone();
        let bridge_hub_client = Some(hub_client);
        let bridge_debounce_ms = invalidation_debounce_ms;
        let teardown_ack = sdk.teardown_ack();
        let mut db_rx = sdk.subscribe_database_state();
        tokio::spawn(async move {
            loop {
                match db_rx.recv().await {
                    Ok(state) => {
                        let state_str = match &state {
                            dspatch_engine::sdk::DatabaseReadyState::Ready => "ready",
                            dspatch_engine::sdk::DatabaseReadyState::Closed => "closed",
                            dspatch_engine::sdk::DatabaseReadyState::MigrationPending => "migration_pending",
                        };
                        ephemeral.emit("database_state_changed", serde_json::json!({
                            "state": state_str,
                        }));

                        match state {
                            dspatch_engine::sdk::DatabaseReadyState::Ready => {
                                // Rebuild ServiceRegistry with the new database.
                                match bridge_sdk.database().await {
                                    Ok(db) => {
                                        // Rebind the invalidation broadcaster to the
                                        // new database's tracker so table change
                                        // notifications continue to reach WS clients.
                                        bridge_runtime.rebind_invalidation(
                                            db.tracker().clone(),
                                            bridge_debounce_ms,
                                        ).await;

                                        let new_registry = Arc::new(ServiceRegistry::new(
                                            db,
                                            bridge_db_dir.clone(),
                                            bridge_hub_client.clone(),
                                        ));
                                        bridge_runtime.replace_services(new_registry).await;
                                        tracing::info!("ServiceRegistry rebuilt after database change");
                                    }
                                    Err(e) => {
                                        tracing::error!(error = %e, "failed to get DB for service rebuild");
                                    }
                                }
                            }
                            dspatch_engine::sdk::DatabaseReadyState::Closed => {
                                // Drop the old ServiceRegistry so its Arc<Database> is
                                // released. Without this, file handles remain open and
                                // operations like rename fail on Windows (OS error 32).
                                bridge_runtime.clear_services().await;
                                // Signal the SDK that all external DB references are dropped.
                                teardown_ack.notify_one();
                                tracing::info!("ServiceRegistry cleared after database close");
                            }
                            _ => {}
                        }
                    }
                    Err(_) => break,
                }
            }
        });
    }

    // 8. Start the client API server in a background task.
    let api_runtime = runtime.clone();
    let shutdown_rx = runtime.subscribe_shutdown();

    // In test mode, use a oneshot channel to get the actual bound port.
    let port_tx = if test_dir.is_some() {
        let (tx, rx) = tokio::sync::oneshot::channel::<u16>();
        // Stash the receiver for later.
        Some((tx, rx))
    } else {
        None
    };

    let (sender, receiver) = match port_tx {
        Some((tx, rx)) => (Some(tx), Some(rx)),
        None => (None, None),
    };

    // Session cleanup task
    let cleanup_runtime = runtime.clone();
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
        if let Err(e) = start_client_api(api_runtime, shutdown_rx, sender).await {
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

    // 9. Wait for shutdown signal (Ctrl+C / SIGTERM).
    wait_for_shutdown_signal().await;

    // 10. Trigger graceful shutdown.
    tracing::info!("shutting down...");
    runtime.trigger_shutdown();

    // 11. Wait for the server to finish.
    let _ = tokio::time::timeout(
        std::time::Duration::from_secs(10),
        api_handle,
    )
    .await;

    tracing::info!("dspatch engine stopped");

    // 12. Clean up test directory on shutdown.
    if let Some(dir) = test_dir {
        if let Err(e) = std::fs::remove_dir_all(&dir) {
            tracing::warn!(error = %e, "failed to clean up test directory");
        } else {
            tracing::info!(dir = %dir.display(), "test directory cleaned up");
        }
    }
}
