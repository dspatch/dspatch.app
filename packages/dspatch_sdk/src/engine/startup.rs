// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Engine runtime state and initialization helpers.

use std::sync::Arc;
use std::time::Instant;

use tokio::sync::broadcast;
use tracing_subscriber::EnvFilter;

use super::config::EngineConfig;
use super::service_registry::ServiceRegistry;
use crate::client_api::invalidation::InvalidationHandle;
use crate::client_api::session::SessionStore;

/// Core runtime state for the engine daemon.
pub struct EngineRuntime {
    config: EngineConfig,
    started_at: Instant,
    shutdown_tx: broadcast::Sender<()>,
    session_store: SessionStore,
    services: Option<Arc<ServiceRegistry>>,
    invalidation: Option<InvalidationHandle>,
}

impl EngineRuntime {
    pub fn new(config: EngineConfig) -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            config,
            started_at: Instant::now(),
            shutdown_tx,
            session_store: SessionStore::new(),
            services: None,
            invalidation: None,
        }
    }

    pub fn with_services(config: EngineConfig, services: Arc<ServiceRegistry>) -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            config,
            started_at: Instant::now(),
            shutdown_tx,
            session_store: SessionStore::new(),
            services: Some(services),
            invalidation: None,
        }
    }

    /// Creates a runtime with an InvalidationHandle.
    pub fn with_invalidation(config: EngineConfig, invalidation: InvalidationHandle) -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            config,
            started_at: Instant::now(),
            shutdown_tx,
            session_store: SessionStore::new(),
            services: None,
            invalidation: Some(invalidation),
        }
    }

    /// Creates a runtime with both services and invalidation.
    pub fn with_services_and_invalidation(
        config: EngineConfig,
        services: Arc<ServiceRegistry>,
        invalidation: InvalidationHandle,
    ) -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            config,
            started_at: Instant::now(),
            shutdown_tx,
            session_store: SessionStore::new(),
            services: Some(services),
            invalidation: Some(invalidation),
        }
    }

    pub fn config(&self) -> &EngineConfig {
        &self.config
    }

    pub fn session_store(&self) -> &SessionStore {
        &self.session_store
    }

    pub fn uptime_seconds(&self) -> u64 {
        self.started_at.elapsed().as_secs()
    }

    pub fn subscribe_shutdown(&self) -> broadcast::Receiver<()> {
        self.shutdown_tx.subscribe()
    }

    pub fn trigger_shutdown(&self) {
        let _ = self.shutdown_tx.send(());
    }

    pub fn services(&self) -> Option<&Arc<ServiceRegistry>> {
        self.services.as_ref()
    }

    /// Returns true if the invalidation broadcaster has been started.
    pub fn has_invalidation(&self) -> bool {
        self.invalidation.is_some()
    }

    /// Returns the invalidation handle, if the broadcaster has been started.
    pub fn invalidation_handle(&self) -> &InvalidationHandle {
        self.invalidation
            .as_ref()
            .expect("InvalidationBroadcaster not started")
    }

    /// Sets the invalidation handle on an existing runtime.
    pub fn set_invalidation(&mut self, handle: InvalidationHandle) {
        self.invalidation = Some(handle);
    }
}

/// Initializes the `tracing` subscriber based on the configured log level.
pub fn init_tracing(log_level: &str) {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(log_level));

    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_target(true)
        .init();
}

/// Waits for Ctrl+C (SIGINT). Returns when the signal is received.
/// Opens (or creates) the engine's SQLite database at the given path.
///
/// Applies all pending migrations. WAL mode is enabled automatically.
pub fn open_database(path: &std::path::Path) -> crate::util::result::Result<crate::db::Database> {
    tracing::info!(path = %path.display(), "opening engine database");
    let db = crate::db::Database::open(path, None)?;
    tracing::info!("database ready");
    Ok(db)
}

/// Waits for Ctrl+C (SIGINT). Returns when the signal is received.
pub async fn wait_for_shutdown_signal() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{signal, SignalKind};
        let mut sigterm = signal(SignalKind::terminate())
            .expect("failed to install SIGTERM handler");
        tokio::select! {
            _ = tokio::signal::ctrl_c() => {
                tracing::info!("received Ctrl+C, initiating shutdown");
            }
            _ = sigterm.recv() => {
                tracing::info!("received SIGTERM, initiating shutdown");
            }
        }
    }

    #[cfg(not(unix))]
    {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
        tracing::info!("received Ctrl+C, initiating shutdown");
    }
}
