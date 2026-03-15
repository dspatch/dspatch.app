// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! `/health` endpoint — always public, no auth required.

use std::sync::Arc;

use axum::extract::State;
use axum::Json;
use serde::{Deserialize, Serialize};

use crate::engine::startup::EngineRuntime;

/// JSON response for `GET /health`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub uptime_seconds: u64,
    pub docker_available: bool,
    pub authenticated: bool,
    pub connected_devices: u32,
    pub backend_url: Option<String>,
}

/// Handler for `GET /health`.
pub async fn health_handler(
    State(runtime): State<Arc<EngineRuntime>>,
) -> Json<HealthResponse> {
    let docker_available = check_docker_available().await;

    Json(HealthResponse {
        status: "running".into(),
        uptime_seconds: runtime.uptime_seconds(),
        docker_available,
        authenticated: runtime.session_store().has_sessions(),
        connected_devices: 0,    // TODO: M8 — wire to P2P layer
        backend_url: runtime.config().backend_url.clone(),
    })
}

/// JSON response for `GET /engine-info`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EngineInfoResponse {
    pub db_path: String,
    pub test_mode: bool,
}

/// Handler for `GET /engine-info`.
/// Clients use this to discover the DB path for Drift read-only access.
pub async fn engine_info_handler(
    State(runtime): State<Arc<EngineRuntime>>,
) -> Json<EngineInfoResponse> {
    let config = runtime.config();
    let db_path = config.db_dir.join("engine.db");

    Json(EngineInfoResponse {
        db_path: db_path.to_string_lossy().into_owned(),
        test_mode: config.test_mode,
    })
}

async fn check_docker_available() -> bool {
    match tokio::process::Command::new("docker")
        .arg("info")
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .await
    {
        Ok(status) => status.success(),
        Err(_) => false,
    }
}
