// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! WebSocket endpoint for the client API.

use std::sync::Arc;

use axum::extract::ws::{Message, WebSocket};
use axum::extract::{Query, State, WebSocketUpgrade};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use serde::Deserialize;

use crate::db::schema::TABLE_NAMES;
use crate::engine::startup::EngineRuntime;

use super::protocol::{ClientFrame, ServerFrame};
use super::session::{AuthMode, Session};
use super::commands::Command;
use super::dispatch::dispatch_command;
use super::error_mapping::error_to_frame;

#[derive(Debug, Deserialize)]
pub struct WsQuery {
    pub token: String,
}

pub async fn ws_handler(
    State(runtime): State<Arc<EngineRuntime>>,
    Query(query): Query<WsQuery>,
    ws: WebSocketUpgrade,
) -> impl IntoResponse {
    let session = match runtime.session_store().validate(&query.token) {
        Some(session) => session,
        None => {
            tracing::warn!("WebSocket connection rejected: invalid session token");
            return StatusCode::UNAUTHORIZED.into_response();
        }
    };

    tracing::info!(
        auth_mode = ?session.auth_mode,
        username = ?session.username,
        "WebSocket connection accepted"
    );

    let token = query.token.clone();
    ws.on_upgrade(move |socket| handle_ws_connection(socket, session, token, runtime))
        .into_response()
}

async fn handle_ws_connection(
    mut socket: WebSocket,
    session: Session,
    session_token: String,
    runtime: Arc<EngineRuntime>,
) {
    let welcome = ServerFrame::welcome();
    if let Err(e) = send_frame(&mut socket, &welcome).await {
        tracing::error!(error = %e, "failed to send welcome event");
        return;
    }

    let auth_event = ServerFrame::Event {
        name: "auth_state_changed".into(),
        data: serde_json::json!({
            "mode": match session.auth_mode {
                AuthMode::Anonymous => "anonymous",
                AuthMode::Connected => "connected",
            },
            "token_scope": if session.auth_mode == AuthMode::Connected { Some("full") } else { None::<&str> },
            "username": session.username,
        }),
    };
    send_frame(&mut socket, &auth_event).await.ok();

    let mut shutdown_rx = runtime.subscribe_shutdown();

    // Subscribe to table invalidation broadcasts (if available).
    let mut invalidation_rx = runtime.subscribe_invalidation().await;

    // Subscribe to ephemeral engine events.
    let mut ephemeral_rx = runtime.ephemeral().subscribe();

    let mut ping_interval = tokio::time::interval(std::time::Duration::from_secs(30));
    ping_interval.tick().await; // Consume the immediate first tick.

    loop {
        tokio::select! {
            // Engine is shutting down.
            _ = shutdown_rx.recv() => {
                tracing::info!("WebSocket closing: engine shutting down");
                let shutdown_event = ServerFrame::Event {
                    name: "engine_shutting_down".into(),
                    data: serde_json::json!({}),
                };
                let _ = send_frame(&mut socket, &shutdown_event).await;
                break;
            }
            // Periodic ping for keepalive.
            _ = ping_interval.tick() => {
                if socket.send(Message::Ping(vec![].into())).await.is_err() {
                    tracing::info!("WebSocket ping failed, client likely disconnected");
                    break;
                }
            }
            // Table invalidation batch from the broadcaster.
            invalidation = async {
                match &mut invalidation_rx {
                    Some(rx) => rx.recv().await,
                    None => std::future::pending().await,
                }
            } => {
                let tables = match invalidation {
                    Ok(tables) => tables,
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(n)) => {
                        tracing::warn!(
                            missed = n,
                            "invalidation receiver lagged, sending full invalidation"
                        );
                        TABLE_NAMES.iter().map(|s| s.to_string()).collect()
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                        tracing::info!("invalidation broadcaster closed");
                        invalidation_rx = None;
                        continue;
                    }
                };

                let frame = ServerFrame::Invalidate { tables };
                if send_frame(&mut socket, &frame).await.is_err() {
                    tracing::info!("WebSocket send failed during invalidation");
                    break;
                }
            }
            // Ephemeral engine lifecycle event.
            event = ephemeral_rx.recv() => {
                match event {
                    Ok(evt) => {
                        let frame = ServerFrame::Event {
                            name: evt.name,
                            data: evt.data,
                        };
                        if send_frame(&mut socket, &frame).await.is_err() {
                            tracing::info!("WebSocket send failed during ephemeral event");
                            break;
                        }
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(n)) => {
                        tracing::warn!(missed = n, "ephemeral event receiver lagged, dropping missed events");
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                        tracing::info!("ephemeral event emitter closed");
                        break;
                    }
                }
            }
            // Client sent a message.
            msg = recv_message(&mut socket) => {
                match msg {
                    Some(Ok(text)) => {
                        let should_close = handle_client_message(&mut socket, &text, &session_token, &runtime).await;
                        if should_close {
                            tracing::info!("WebSocket closing: client logged out");
                            break;
                        }
                    }
                    Some(Err(e)) => {
                        tracing::warn!(error = %e, "WebSocket receive error");
                        break;
                    }
                    None => {
                        tracing::info!("WebSocket client disconnected");
                        break;
                    }
                }
            }
        }
    }

    // Clear sensitive credentials from the session on disconnect so they
    // don't linger in memory. The session itself is kept for potential
    // reconnect, but device_id and identity_key_seed are zeroed.
    runtime.session_store().clear_credentials(&session_token);
}

/// Returns `true` if the connection should be closed (e.g. logout).
async fn handle_client_message(
    socket: &mut WebSocket,
    text: &str,
    session_token: &str,
    runtime: &Arc<EngineRuntime>,
) -> bool {
    let frame: ClientFrame = match serde_json::from_str(text) {
        Ok(f) => f,
        Err(e) => {
            tracing::warn!(error = %e, "invalid client frame");
            let err = ServerFrame::Error {
                id: None,
                code: "INVALID_FRAME".into(),
                message: format!("Failed to parse frame: {e}"),
            };
            let _ = send_frame(socket, &err).await;
            return false;
        }
    };

    match frame {
        ClientFrame::Command {
            id,
            method,
            params,
        } => {
            // Inject `method` into `params` so serde can deserialize the
            // tagged Command enum (which uses `#[serde(tag = "method")]`).
            let mut command_value = match params {
                serde_json::Value::Object(map) => serde_json::Value::Object(map),
                _ => serde_json::Value::Object(serde_json::Map::new()),
            };
            command_value
                .as_object_mut()
                .unwrap()
                .insert("method".into(), serde_json::Value::String(method));

            let command: Command = match serde_json::from_value(command_value) {
                Ok(c) => c,
                Err(e) => {
                    let err = ServerFrame::Error {
                        id: Some(id),
                        code: "INVALID_PARAMS".into(),
                        message: format!("Failed to deserialize command params: {e}"),
                    };
                    let _ = send_frame(socket, &err).await;
                    return false;
                }
            };

            // Logout: invalidate session and signal connection close.
            if matches!(command, Command::Logout) {
                runtime.session_store().remove(session_token);
                tracing::info!("Session invalidated via logout command");
                let frame = ServerFrame::Result {
                    id,
                    data: serde_json::json!({}),
                };
                let _ = send_frame(socket, &frame).await;
                return true;
            }

            // Refresh credentials: update stored token and device info.
            if let Command::RefreshCredentials { backend_token, device_id, identity_key_seed } = &command {
                runtime.session_store().update_credentials(
                    session_token,
                    backend_token.clone(),
                    device_id.clone(),
                    identity_key_seed.clone(),
                );
                tracing::info!("Session credentials refreshed");
                let frame = ServerFrame::Result {
                    id,
                    data: serde_json::json!({"status": "ok"}),
                };
                let _ = send_frame(socket, &frame).await;
                return false;
            }

            // Database lifecycle commands route to the SDK directly,
            // bypassing ServiceRegistry — they must work even when the DB
            // is not yet open (e.g. migration-pending state).
            if let Some(response) = handle_sdk_command(&command, runtime).await {
                let frame = match response {
                    Ok(data) => ServerFrame::Result { id, data },
                    Err(e) => error_to_frame(&id, &e),
                };
                let _ = send_frame(socket, &frame).await;
                return false;
            }

            let services = match runtime.services() {
                Some(s) => s,
                None => {
                    let err = ServerFrame::Error {
                        id: Some(id),
                        code: "NOT_READY".into(),
                        message: "Engine services are not yet initialized".into(),
                    };
                    let _ = send_frame(socket, &err).await;
                    return false;
                }
            };

            let response = match dispatch_command(&command, &services, runtime.ephemeral()).await {
                Ok(data) => ServerFrame::Result { id, data },
                Err(e) => error_to_frame(&id, &e),
            };
            let _ = send_frame(socket, &response).await;
            false
        }
    }
}

/// Handles commands that route to the SDK rather than ServiceRegistry.
///
/// Returns `Some(result)` if the command was handled, `None` if it should
/// fall through to the normal dispatch path.
async fn handle_sdk_command(
    command: &Command,
    runtime: &Arc<EngineRuntime>,
) -> Option<crate::util::result::Result<serde_json::Value>> {
    match command {
        Command::GetDatabaseState => {
            let sdk = match runtime.sdk() {
                Some(s) => s,
                None => return Some(Ok(serde_json::json!({ "state": "ready" }))),
            };
            let state = if sdk.is_migration_pending().await {
                "migration_pending"
            } else if sdk.is_database_ready().await {
                "ready"
            } else {
                "closed"
            };
            Some(Ok(serde_json::json!({ "state": state })))
        }
        Command::PerformMigration => {
            let sdk = match runtime.sdk() {
                Some(s) => s,
                None => {
                    return Some(Err(crate::util::error::AppError::Internal(
                        "Database migration not available in this mode".into(),
                    )))
                }
            };
            Some(sdk.perform_migration().await.map(|()| serde_json::json!({})))
        }
        Command::SkipMigration => {
            let sdk = match runtime.sdk() {
                Some(s) => s,
                None => {
                    return Some(Err(crate::util::error::AppError::Internal(
                        "Database migration not available in this mode".into(),
                    )))
                }
            };
            Some(sdk.skip_migration().await.map(|()| serde_json::json!({})))
        }
        _ => None,
    }
}

async fn send_frame(socket: &mut WebSocket, frame: &ServerFrame) -> Result<(), axum::Error> {
    let json = serde_json::to_string(frame).expect("ServerFrame serialization should never fail");
    socket.send(Message::Text(json.into())).await
}

async fn recv_message(socket: &mut WebSocket) -> Option<Result<String, axum::Error>> {
    loop {
        match socket.recv().await {
            Some(Ok(Message::Text(text))) => return Some(Ok(text.to_string())),
            Some(Ok(Message::Close(_))) => return None,
            Some(Ok(Message::Ping(_) | Message::Pong(_))) => continue,
            Some(Ok(Message::Binary(_))) => continue,
            Some(Err(e)) => return Some(Err(e)),
            None => return None,
        }
    }
}
