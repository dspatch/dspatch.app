// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Authentication HTTP endpoints for the client API.

use std::sync::Arc;

use axum::extract::State;
use axum::http::StatusCode;
use axum::Json;
use base64::Engine as _;
use serde::{Deserialize, Serialize};

use crate::engine::startup::EngineRuntime;

use super::session::AuthMode;

#[derive(Debug, Deserialize)]
pub struct ConnectRequest {
    pub backend_token: String,
}

#[derive(Debug, Deserialize)]
pub struct RefreshRequest {
    pub backend_token: String,
    pub session_token: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub session_token: String,
    pub auth_mode: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub username: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expires_at: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct AuthErrorResponse {
    pub error: String,
}

#[derive(Debug, Deserialize)]
struct BackendStatusResponse {
    scope: String,
    username: String,
    #[allow(dead_code)]
    email: String,
}

pub async fn anonymous_handler(
    State(runtime): State<Arc<EngineRuntime>>,
) -> Json<AuthResponse> {
    let token = runtime
        .session_store()
        .create_session(AuthMode::Anonymous, None, None, None);
    tracing::info!("anonymous session created");
    Json(AuthResponse {
        session_token: token,
        auth_mode: "anonymous".into(),
        username: None,
        expires_at: None,
    })
}

pub async fn connect_handler(
    State(runtime): State<Arc<EngineRuntime>>,
    Json(body): Json<ConnectRequest>,
) -> Result<Json<AuthResponse>, (StatusCode, Json<AuthErrorResponse>)> {
    let backend_url = runtime.config().backend_url.as_ref().ok_or_else(|| {
        (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(AuthErrorResponse {
                error: "Backend URL is not configured.".into(),
            }),
        )
    })?;

    let status = validate_backend_token(backend_url, &body.backend_token)
        .await
        .map_err(|e| {
            tracing::warn!(error = %e, "backend token validation failed");
            (
                StatusCode::UNAUTHORIZED,
                Json(AuthErrorResponse { error: e }),
            )
        })?;

    if status.scope != "full" {
        return Err((
            StatusCode::FORBIDDEN,
            Json(AuthErrorResponse {
                error: "Incomplete authentication. Full scope required.".into(),
            }),
        ));
    }

    let expires_at = decode_jwt_exp(&body.backend_token);

    let token = runtime.session_store().create_session(
        AuthMode::Connected,
        Some(status.username.clone()),
        Some(body.backend_token),
        expires_at,
    );

    tracing::info!(username = %status.username, "connected session created");

    // Switch to per-user database. May signal migration-pending via
    // ephemeral event if an anonymous DB exists without a user DB.
    if let Some(sdk) = runtime.sdk() {
        if let Err(e) = sdk.open_user_database(&status.username).await {
            tracing::error!(
                error = %e,
                username = %status.username,
                "failed to switch to per-user database"
            );
            // Non-fatal: session is created, client can retry via
            // get_database_state or re-connect.
        }
    }

    Ok(Json(AuthResponse {
        session_token: token,
        auth_mode: "connected".into(),
        username: Some(status.username),
        expires_at,
    }))
}

pub async fn refresh_handler(
    State(runtime): State<Arc<EngineRuntime>>,
    Json(body): Json<RefreshRequest>,
) -> Result<Json<AuthResponse>, (StatusCode, Json<AuthErrorResponse>)> {
    let session = runtime
        .session_store()
        .validate(&body.session_token)
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(AuthErrorResponse {
                    error: "Invalid or expired session token.".into(),
                }),
            )
        })?;

    let backend_url = runtime.config().backend_url.as_ref().ok_or_else(|| {
        (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(AuthErrorResponse {
                error: "Backend URL is not configured.".into(),
            }),
        )
    })?;

    let status = validate_backend_token(backend_url, &body.backend_token)
        .await
        .map_err(|e| {
            tracing::warn!(error = %e, "backend token validation failed during refresh");
            (
                StatusCode::UNAUTHORIZED,
                Json(AuthErrorResponse { error: e }),
            )
        })?;

    if status.scope != "full" {
        return Err((
            StatusCode::FORBIDDEN,
            Json(AuthErrorResponse {
                error: "Incomplete authentication. Full scope required.".into(),
            }),
        ));
    }

    let expires_at = decode_jwt_exp(&body.backend_token);

    let updated = runtime.session_store().update_session(
        &body.session_token,
        Some(body.backend_token),
        expires_at,
    );

    if !updated {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(AuthErrorResponse {
                error: "Session no longer exists.".into(),
            }),
        ));
    }

    tracing::info!(username = %status.username, "session refreshed");

    Ok(Json(AuthResponse {
        session_token: body.session_token,
        auth_mode: "connected".into(),
        username: session.username,
        expires_at,
    }))
}

async fn validate_backend_token(
    backend_url: &str,
    token: &str,
) -> Result<BackendStatusResponse, String> {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{backend_url}/api/auth/status"))
        .header("Authorization", format!("Bearer {token}"))
        .timeout(std::time::Duration::from_secs(10))
        .send()
        .await
        .map_err(|e| format!("Backend request failed: {e}"))?;

    if resp.status() != reqwest::StatusCode::OK {
        return Err(format!(
            "Backend returned status {}",
            resp.status().as_u16()
        ));
    }

    resp.json::<BackendStatusResponse>()
        .await
        .map_err(|e| format!("Failed to parse backend response: {e}"))
}

/// Decode the `exp` claim from a JWT without verifying the signature.
/// Returns `None` if the token is malformed or the claim is missing.
fn decode_jwt_exp(jwt: &str) -> Option<i64> {
    let payload = jwt.split('.').nth(1)?;
    let decoded = base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(payload)
        .ok()?;
    let value: serde_json::Value = serde_json::from_slice(&decoded).ok()?;
    value.get("exp")?.as_i64()
}
