// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Backend relay transport for sync messages when P2P is unavailable.
//!
//! When a peer device is offline or WebRTC cannot be established, sync
//! messages are encrypted and sent through the backend's relay API.
//! Messages are stored server-side until the recipient picks them up.

use std::sync::Arc;
use tokio::sync::Mutex;

use crate::domain::services::ApiClient;
use crate::signal::SignalService;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Sends an encrypted sync message through the backend relay.
///
/// The message is encrypted with the Signal Protocol before sending,
/// ensuring the backend cannot read the content.
pub async fn send_via_relay(
    api_client: &dyn ApiClient,
    signal: &Arc<Mutex<SignalService>>,
    target_device_id: &str,
    plaintext: &[u8],
) -> Result<()> {
    use base64::{engine::general_purpose::STANDARD, Engine};

    // Encrypt the message with Signal Protocol.
    let encrypted = {
        let addr = libsignal_protocol::ProtocolAddress::new(
            target_device_id.to_string(),
            libsignal_protocol::DeviceId::new(1).expect("valid device id"),
        );
        let mut signal = signal.lock().await;
        signal
            .encrypt(&addr, plaintext, &mut rand::rng())
            .await
            .map_err(|e| AppError::Internal(format!("Signal encrypt for relay failed: {e}")))?
    };

    // Send via backend relay API.
    let body = serde_json::json!({
        "target_device_id": target_device_id,
        "encrypted_payload": STANDARD.encode(&encrypted),
    });

    let response = api_client
        .post("/api/sync/send", Some(body))
        .await
        .map_err(|e| AppError::Server(format!("Relay send failed: {e}")))?;

    if !response.is_success() {
        return Err(AppError::Server(format!(
            "Relay API returned {}: {}",
            response.status_code, response.raw_body,
        )));
    }

    tracing::debug!("Sent relay message to {target_device_id}");
    Ok(())
}

/// Fetches and processes pending relay messages from the backend.
///
/// Called when the engine receives a `sync:ready` WebSocket event indicating
/// messages are waiting on the server.
pub async fn fetch_pending_relay_messages(
    api_client: &dyn ApiClient,
    signal: &Arc<Mutex<SignalService>>,
) -> Result<Vec<(String, Vec<u8>)>> {
    use base64::{engine::general_purpose::STANDARD, Engine};

    let response = api_client
        .get("/api/sync/pending", None)
        .await
        .map_err(|e| AppError::Server(format!("Relay fetch failed: {e}")))?;

    if !response.is_success() {
        return Err(AppError::Server(format!(
            "Relay API returned {}: {}",
            response.status_code, response.raw_body,
        )));
    }

    let messages: Vec<serde_json::Value> = serde_json::from_str(&response.raw_body)
        .map_err(|e| AppError::Internal(format!("Invalid relay response: {e}")))?;

    let mut result = Vec::new();

    for msg in messages {
        let from_device = msg["source_device_id"]
            .as_str()
            .unwrap_or_default()
            .to_string();
        let encrypted_b64 = msg["encrypted_payload"].as_str().unwrap_or_default();
        let message_id = msg["id"].as_str().unwrap_or_default().to_string();

        let encrypted = STANDARD
            .decode(encrypted_b64)
            .map_err(|e| AppError::Internal(format!("Invalid relay payload base64: {e}")))?;

        // Decrypt with Signal Protocol.
        let plaintext = {
            let addr = libsignal_protocol::ProtocolAddress::new(
                from_device.clone(),
                libsignal_protocol::DeviceId::new(1).expect("valid device id"),
            );
            let mut signal = signal.lock().await;
            signal
                .decrypt(&addr, &encrypted, &mut rand::rng())
                .await
                .map_err(|e| {
                    AppError::Internal(format!("Signal decrypt relay failed: {e}"))
                })?
        };

        // Acknowledge receipt so the server can discard the message.
        let ack_body = serde_json::json!({ "message_ids": [message_id] });
        let _ = api_client.post("/api/sync/ack", Some(ack_body)).await;

        result.push((from_device, plaintext));
    }

    tracing::info!("Fetched {} pending relay messages", result.len());
    Ok(result)
}
