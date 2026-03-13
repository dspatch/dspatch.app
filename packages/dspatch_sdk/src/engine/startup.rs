// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Engine runtime state and initialization helpers.

use std::time::Instant;

use tokio::sync::broadcast;
use tracing_subscriber::EnvFilter;

use super::config::EngineConfig;

/// Core runtime state for the engine daemon.
pub struct EngineRuntime {
    config: EngineConfig,
    started_at: Instant,
    shutdown_tx: broadcast::Sender<()>,
}

impl EngineRuntime {
    pub fn new(config: EngineConfig) -> Self {
        let (shutdown_tx, _) = broadcast::channel(1);
        Self {
            config,
            started_at: Instant::now(),
            shutdown_tx,
        }
    }

    pub fn config(&self) -> &EngineConfig {
        &self.config
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
