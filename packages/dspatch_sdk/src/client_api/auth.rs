// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Authentication HTTP endpoints for the client API.

use std::sync::Arc;

use axum::extract::State;
use axum::http::StatusCode;
use axum::Json;
use serde::{Deserialize, Serialize};

use crate::engine::startup::EngineRuntime;

use super::session::AuthMode;

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub session_token: String,
    pub auth_mode: String,
}

#[derive(Debug, Serialize)]
pub struct AuthErrorResponse {
    pub error: String,
}

pub async fn anonymous_handler(
    State(runtime): State<Arc<EngineRuntime>>,
) -> Json<AuthResponse> {
    let token = runtime.session_store().create_session(AuthMode::Anonymous, None);
    tracing::info!("anonymous session created");
    Json(AuthResponse {
        session_token: token,
        auth_mode: "anonymous".into(),
    })
}

pub async fn login_handler(
    State(_runtime): State<Arc<EngineRuntime>>,
    Json(_body): Json<LoginRequest>,
) -> (StatusCode, Json<AuthErrorResponse>) {
    // TODO: Wire ConnectedAuthService when backend URL config is available.
    tracing::warn!("login attempted but backend auth is not yet available");
    (
        StatusCode::SERVICE_UNAVAILABLE,
        Json(AuthErrorResponse {
            error: "Backend authentication is not available. Use anonymous mode or try again later.".into(),
        }),
    )
}

pub async fn register_handler(
    State(_runtime): State<Arc<EngineRuntime>>,
    Json(_body): Json<RegisterRequest>,
) -> (StatusCode, Json<AuthErrorResponse>) {
    // TODO: Wire ConnectedAuthService when backend URL config is available.
    tracing::warn!("register attempted but backend auth is not yet available");
    (
        StatusCode::SERVICE_UNAVAILABLE,
        Json(AuthErrorResponse {
            error: "Backend registration is not available. Use anonymous mode or try again later.".into(),
        }),
    )
}
