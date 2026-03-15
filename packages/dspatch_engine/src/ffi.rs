// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! FFI entry points for mobile platforms.
//!
//! The engine is loaded as a shared library (cdylib) and controlled via two
//! C-ABI functions: [`start_engine`] and [`stop_engine`].

use std::ffi::{c_char, CStr};
use std::sync::{Arc, Mutex};

use once_cell::sync::Lazy;

use crate::client_api::invalidation::InvalidationBroadcaster;
use crate::client_api::server::start_client_api;
use crate::config::DspatchConfig;
use crate::crypto::KeyringSecretStore;
use crate::engine::config::EngineConfig;
use crate::engine::service_registry::ServiceRegistry;
use crate::engine::startup::{init_tracing, EngineRuntime};
use crate::sdk::{DatabaseReadyState, DspatchSdk};

/// Holds the tokio runtime and engine runtime so we can shut down later.
struct EngineHandle {
    runtime: tokio::runtime::Runtime,
    engine_runtime: Arc<EngineRuntime>,
}

static ENGINE: Lazy<Mutex<Option<EngineHandle>>> = Lazy::new(|| Mutex::new(None));

/// Start the dspatch engine in-process.
///
/// # Parameters
/// - `config_json`: Pointer to a null-terminated UTF-8 JSON string containing
///   [`EngineConfig`] fields. Pass a valid JSON object; unknown fields are
///   ignored. Missing fields use their defaults.
///
/// # Returns
/// - `0` on success
/// - `1` on invalid/null config pointer or malformed JSON
/// - `2` if the engine is already running
/// - `3` on engine startup failure
///
/// # Safety
/// `config_json` must be a valid pointer to a null-terminated C string, or null.
#[no_mangle]
pub unsafe extern "C" fn start_engine(config_json: *const c_char) -> i32 {
    if config_json.is_null() {
        return 1;
    }

    let c_str = match CStr::from_ptr(config_json).to_str() {
        Ok(s) => s,
        Err(_) => return 1,
    };

    let config: EngineConfig = match serde_json::from_str(c_str) {
        Ok(c) => c,
        Err(_) => return 1,
    };

    let mut guard = match ENGINE.lock() {
        Ok(g) => g,
        Err(_) => return 3,
    };

    if guard.is_some() {
        return 2;
    }

    // Build tokio runtime.
    let rt = match tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
    {
        Ok(rt) => rt,
        Err(_) => return 3,
    };

    // Initialize the engine inside the runtime.
    let engine_runtime = match rt.block_on(async {
        init_tracing(&config.log_level);

        // Ensure db directory exists.
        std::fs::create_dir_all(&config.db_dir)
            .map_err(|e| format!("failed to create db_dir: {e}"))?;

        // Clone db_dir before config is moved into EngineRuntime.
        let db_dir = config.db_dir.clone();

        // Create and initialize the SDK (replaces direct DB open).
        let sdk_config = DspatchConfig::from_engine_config(&config);
        let sdk = Arc::new(DspatchSdk::with_secret_store(
            sdk_config,
            Box::new(KeyringSecretStore::new("dspatch")),
            db_dir.clone(),
        ));

        sdk.initialize()
            .await
            .map_err(|e| format!("failed to initialize SDK: {e}"))?;

        // Get DB handle from SDK.
        let db = sdk
            .database()
            .await
            .map_err(|e| format!("failed to get database from SDK: {e}"))?;

        let broadcaster = InvalidationBroadcaster::new(
            db.tracker().clone(),
            config.invalidation_debounce_ms,
        );
        let invalidation_handle = broadcaster.start();

        let registry = Arc::new(ServiceRegistry::new(db, db_dir.clone(), None));
        let mut runtime = Arc::new(EngineRuntime::with_services_and_invalidation(
            config,
            registry,
            invalidation_handle,
        ));

        // Store SDK on runtime (safe: no clones of the Arc exist yet).
        Arc::get_mut(&mut runtime)
            .expect("runtime has no other references yet")
            .set_sdk(Arc::clone(&sdk));

        // Bridge SDK database state changes → ephemeral events + service rebuild.
        {
            let ephemeral = runtime.ephemeral().clone_sender();
            let bridge_runtime = Arc::clone(&runtime);
            let bridge_sdk = Arc::clone(&sdk);
            let bridge_db_dir = db_dir.clone();
            let mut db_rx = sdk.subscribe_database_state();
            tokio::spawn(async move {
                loop {
                    match db_rx.recv().await {
                        Ok(state) => {
                            let state_str = match &state {
                                DatabaseReadyState::Ready => "ready",
                                DatabaseReadyState::Closed => "closed",
                                DatabaseReadyState::MigrationPending => "migration_pending",
                            };
                            ephemeral.emit(
                                "database_state_changed",
                                serde_json::json!({ "state": state_str }),
                            );

                            // Rebuild ServiceRegistry when a new database becomes ready.
                            if matches!(state, DatabaseReadyState::Ready) {
                                match bridge_sdk.database().await {
                                    Ok(db) => {
                                        let new_registry = Arc::new(ServiceRegistry::new(
                                            db,
                                            bridge_db_dir.clone(),
                                            None,
                                        ));
                                        bridge_runtime.replace_services(new_registry).await;
                                        tracing::info!(
                                            "ServiceRegistry rebuilt after database change"
                                        );
                                    }
                                    Err(e) => {
                                        tracing::error!(
                                            error = %e,
                                            "failed to get DB for service rebuild"
                                        );
                                    }
                                }
                            }
                        }
                        Err(_) => break,
                    }
                }
            });
        }

        Ok::<_, String>(runtime)
    }) {
        Ok(r) => r,
        Err(_) => return 3,
    };

    // Spawn the client API server in the background.
    let api_runtime = engine_runtime.clone();
    let shutdown_rx = engine_runtime.subscribe_shutdown();
    rt.spawn(async move {
        if let Err(e) = start_client_api(api_runtime, shutdown_rx, None).await {
            tracing::error!(error = %e, "client API server failed");
        }
    });

    *guard = Some(EngineHandle {
        runtime: rt,
        engine_runtime,
    });

    0
}

/// Stop the dspatch engine.
///
/// Sends the shutdown signal and drops the tokio runtime, blocking until all
/// spawned tasks complete.
///
/// # Returns
/// - `0` on success
/// - `1` if the engine is not running
/// - `2` on shutdown failure
#[no_mangle]
pub extern "C" fn stop_engine() -> i32 {
    let mut guard = match ENGINE.lock() {
        Ok(g) => g,
        Err(_) => return 2,
    };

    let handle = match guard.take() {
        Some(h) => h,
        None => return 1,
    };

    handle.engine_runtime.trigger_shutdown();
    drop(handle.runtime);

    0
}
