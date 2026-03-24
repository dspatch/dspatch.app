// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Embedded WebSocket server for agent-to-app communication.
//!
//! Thin HTTP shell that delegates all service wiring to HostRouter.
//!
//! Ported from `server/agent_server.dart`.

use std::sync::Arc;

use axum::{
    extract::{Path, State, WebSocketUpgrade},
    response::IntoResponse,
    Router,
};
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;

use crate::db::dao::WorkspaceDao;
use crate::docker::DockerClient;

use super::host_router::HostRouter;

/// Shared state for axum handlers.
struct AppState {
    host_router: Arc<HostRouter>,
}

/// Embedded WebSocket server for agent-to-app communication.
///
/// Serves run-scoped WebSocket connections:
/// - `/ws/<runId>` -- single router connection per container/run
///
/// Binds to localhost on a specified or random port.
pub struct EmbeddedAgentServer {
    workspace_dao: Arc<WorkspaceDao>,
    docker_client: Arc<DockerClient>,

    host_router: Option<Arc<HostRouter>>,

    port: Option<u16>,
    shutdown_tx: Option<tokio::sync::oneshot::Sender<()>>,
}

impl EmbeddedAgentServer {
    pub fn new(
        workspace_dao: Arc<WorkspaceDao>,
        docker_client: Arc<DockerClient>,
    ) -> Self {
        Self {
            workspace_dao,
            docker_client,
            host_router: None,
            port: None,
            shutdown_tx: None,
        }
    }

    /// Whether the server is currently running.
    pub fn is_running(&self) -> bool {
        self.port.is_some()
    }

    /// The port the server is bound to, or None if not running.
    pub fn port(&self) -> Option<u16> {
        self.port
    }

    /// Returns a reference to the host router (only valid after start).
    pub fn host_router(&self) -> Option<&Arc<HostRouter>> {
        self.host_router.as_ref()
    }

    /// Starts the server. Returns the bound port number.
    pub async fn start(
        &mut self,
        preferred_port: u16,
        dev_mode: bool,
    ) -> Result<u16, String> {
        if self.is_running() {
            return Ok(self.port.unwrap());
        }

        // Create HostRouter.
        let host_router = HostRouter::new(
            Arc::clone(&self.workspace_dao),
            dev_mode,
        );

        // Set up routes.
        let state = Arc::new(AppState {
            host_router: Arc::clone(&host_router),
        });

        let app = Router::new()
            .route(
                "/ws/{run_id}",
                axum::routing::get(ws_handler),
            )
            .layer(CorsLayer::permissive())
            .with_state(state);

        let bind_addr = format!("127.0.0.1:{}", preferred_port);
        let listener = TcpListener::bind(&bind_addr)
            .await
            .map_err(|e| format!("Failed to bind to {}: {}", bind_addr, e))?;

        let actual_port = listener
            .local_addr()
            .map_err(|e| format!("Failed to get local address: {}", e))?
            .port();

        let (shutdown_tx, shutdown_rx) = tokio::sync::oneshot::channel();

        tokio::spawn(async move {
            axum::serve(listener, app)
                .with_graceful_shutdown(async {
                    let _ = shutdown_rx.await;
                })
                .await
                .ok();
        });

        tracing::info!(port = actual_port, "Agent server started");
        host_router.start().await;

        self.host_router = Some(host_router);
        self.port = Some(actual_port);
        self.shutdown_tx = Some(shutdown_tx);

        Ok(actual_port)
    }

    /// Stops the server, closing all connections.
    pub async fn stop(&mut self) {
        if let Some(router) = self.host_router.take() {
            router.dispose().await;
        }
        if let Some(tx) = self.shutdown_tx.take() {
            let _ = tx.send(());
        }
        self.port = None;
        tracing::info!("Agent server stopped");
    }

    /// Registers a run's API key for WebSocket auth.
    pub async fn register_run(&self, run_id: &str, api_key: &str) {
        if let Some(ref router) = self.host_router {
            router.register_run(run_id, api_key).await;
        }
    }

    /// Deregisters a run and closes all its connections.
    pub async fn deregister_run(&self, run_id: &str) {
        if let Some(ref router) = self.host_router {
            router.deregister_run(run_id).await;
        }
    }
}

/// WebSocket upgrade handler for `/ws/:run_id`.
async fn ws_handler(
    ws: WebSocketUpgrade,
    Path(run_id): Path<String>,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let router = Arc::clone(&state.host_router);
    ws.on_upgrade(move |socket| async move {
        router.handle_connection(socket, run_id).await;
    })
}
