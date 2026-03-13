// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! WebSocket endpoint for the client API.

use std::sync::Arc;

use axum::extract::ws::{Message, WebSocket};
use axum::extract::{Query, State, WebSocketUpgrade};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use serde::Deserialize;

use crate::engine::startup::EngineRuntime;

use super::protocol::{ClientFrame, ServerFrame};
use super::session::Session;
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

    ws.on_upgrade(move |socket| handle_ws_connection(socket, session, runtime))
        .into_response()
}

async fn handle_ws_connection(
    mut socket: WebSocket,
    _session: Session,
    runtime: Arc<EngineRuntime>,
) {
    let welcome = ServerFrame::welcome();
    if let Err(e) = send_frame(&mut socket, &welcome).await {
        tracing::error!(error = %e, "failed to send welcome event");
        return;
    }

    let mut shutdown_rx = runtime.subscribe_shutdown();

    let mut ping_interval = tokio::time::interval(std::time::Duration::from_secs(30));
    ping_interval.tick().await; // Consume the immediate first tick.

    loop {
        tokio::select! {
            _ = ping_interval.tick() => {
                if socket.send(Message::Ping(vec![].into())).await.is_err() {
                    tracing::info!("WebSocket ping failed, client likely disconnected");
                    break;
                }
            }
            _ = shutdown_rx.recv() => {
                tracing::info!("WebSocket closing: engine shutting down");
                let shutdown_event = ServerFrame::Event {
                    name: "engine_shutting_down".into(),
                    data: serde_json::json!({}),
                };
                let _ = send_frame(&mut socket, &shutdown_event).await;
                break;
            }
            msg = recv_message(&mut socket) => {
                match msg {
                    Some(Ok(text)) => {
                        handle_client_message(&mut socket, &text, &runtime).await;
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
}

async fn handle_client_message(socket: &mut WebSocket, text: &str, runtime: &Arc<EngineRuntime>) {
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
            return;
        }
    };

    match frame {
        ClientFrame::Command {
            id,
            method: _,
            params,
        } => {
            let command: Command = match serde_json::from_value(params.clone()) {
                Ok(c) => c,
                Err(e) => {
                    let err = ServerFrame::Error {
                        id: Some(id),
                        code: "INVALID_PARAMS".into(),
                        message: format!("Failed to deserialize command params: {e}"),
                    };
                    let _ = send_frame(socket, &err).await;
                    return;
                }
            };

            let services = match runtime.services() {
                Some(s) => s,
                None => {
                    let err = ServerFrame::Error {
                        id: Some(id),
                        code: "NOT_READY".into(),
                        message: "Engine services are not yet initialized".into(),
                    };
                    let _ = send_frame(socket, &err).await;
                    return;
                }
            };

            let response = match dispatch_command(&command, services).await {
                Ok(data) => ServerFrame::Result { id, data },
                Err(e) => error_to_frame(&id, &e),
            };
            let _ = send_frame(socket, &response).await;
        }
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
