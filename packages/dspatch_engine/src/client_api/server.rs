// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Axum router construction and server lifecycle for the client API.

use std::sync::Arc;

use axum::Router;
use tokio::net::TcpListener;

use crate::engine::startup::ClientApiRuntime;
use crate::sdk::DspatchSdk;
use crate::util::error::AppError;
use crate::util::result::Result;

use super::auth::{anonymous_handler, connect_handler, refresh_handler};
use super::health::{engine_info_handler, health_handler};
use super::ws::ws_handler;

/// Shared application state for Axum handlers.
#[derive(Clone)]
pub struct AppState {
    pub sdk: Arc<DspatchSdk>,
    pub runtime: Arc<ClientApiRuntime>,
}

impl axum::extract::FromRef<AppState> for Arc<DspatchSdk> {
    fn from_ref(state: &AppState) -> Self {
        Arc::clone(&state.sdk)
    }
}

impl axum::extract::FromRef<AppState> for Arc<ClientApiRuntime> {
    fn from_ref(state: &AppState) -> Self {
        Arc::clone(&state.runtime)
    }
}

/// Builds the axum router with all client API routes.
pub fn build_router(state: AppState) -> Router {
    Router::new()
        .route("/health", axum::routing::get(health_handler))
        .route("/engine-info", axum::routing::get(engine_info_handler))
        .route("/auth/anonymous", axum::routing::post(anonymous_handler))
        .route("/auth/connect", axum::routing::post(connect_handler))
        .route("/auth/refresh", axum::routing::post(refresh_handler))
        .route("/ws", axum::routing::get(ws_handler))
        .with_state(state)
}

/// Starts the client API server on the configured port.
/// Returns the actual bound port.
///
/// If `port_tx` is provided, the actual bound port is sent through the channel
/// immediately after binding (before the server starts accepting connections).
pub async fn start_client_api(
    state: AppState,
    mut shutdown_rx: tokio::sync::broadcast::Receiver<()>,
    port_tx: Option<tokio::sync::oneshot::Sender<u16>>,
) -> Result<u16> {
    let port = state.runtime.config().client_api_port;
    let addr = format!("127.0.0.1:{port}");

    let listener = TcpListener::bind(&addr).await.map_err(|e| {
        AppError::Internal(format!("failed to bind client API to {addr}: {e}"))
    })?;

    let actual_port = listener.local_addr().map_err(|e| {
        AppError::Internal(format!("failed to get local address: {e}"))
    })?.port();

    tracing::info!(port = actual_port, "client API server listening");

    if let Some(tx) = port_tx {
        let _ = tx.send(actual_port);
    }

    let app = build_router(state);

    axum::serve(listener, app)
        .with_graceful_shutdown(async move {
            let _ = shutdown_rx.recv().await;
            tracing::info!("client API server shutting down");
        })
        .await
        .map_err(|e| AppError::Internal(format!("client API server error: {e}")))?;

    Ok(actual_port)
}
