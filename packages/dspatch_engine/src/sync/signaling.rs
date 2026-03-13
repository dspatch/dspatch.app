// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Signaling client for P2P connection establishment.
//!
//! Connects to the backend's signaling WebSocket endpoint to exchange SDP
//! offers/answers and ICE candidates with other devices. Also relays device
//! online/offline presence events.

use std::pin::Pin;

use futures::Stream;
use serde::{Deserialize, Serialize};

use crate::util::error::AppError;
use crate::util::result::Result;

/// An event received from the signaling server.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SignalingEvent {
    /// A remote device sent an SDP offer.
    SdpOffer { from_device: String, sdp: String },
    /// A remote device sent an SDP answer.
    SdpAnswer { from_device: String, sdp: String },
    /// A remote device sent an ICE candidate.
    IceCandidate {
        from_device: String,
        candidate: String,
    },
    /// A device came online and is available for sync.
    DeviceOnline { device_id: String },
    /// A device went offline.
    DeviceOffline { device_id: String },
}

/// An outbound signaling message sent to the backend.
#[derive(Debug, Clone, Serialize, Deserialize)]
struct SignalingPayload {
    #[serde(rename = "type")]
    msg_type: String,
    target_device_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    sdp: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    candidate: Option<String>,
}

/// Client for the signaling WebSocket endpoint on the backend.
///
/// The signaling server acts as a relay for connection establishment messages
/// (SDP, ICE) between devices that want to set up a P2P data channel.
pub struct SignalingClient {
    backend_url: String,
    auth_token: String,
    device_id: String,
}

impl SignalingClient {
    /// Creates a new signaling client.
    ///
    /// - `backend_url`: Base URL of the backend (e.g. `wss://api.dspatch.dev`).
    /// - `auth_token`: Bearer token for authentication.
    /// - `device_id`: This device's unique identifier.
    pub fn new(backend_url: &str, auth_token: &str, device_id: &str) -> Self {
        Self {
            backend_url: backend_url.to_string(),
            auth_token: auth_token.to_string(),
            device_id: device_id.to_string(),
        }
    }

    /// Returns this client's device ID.
    pub fn device_id(&self) -> &str {
        &self.device_id
    }

    /// Returns the backend URL.
    pub fn backend_url(&self) -> &str {
        &self.backend_url
    }

    /// Sends an SDP offer or answer to a target device via the backend relay.
    pub async fn send_sdp(
        &self,
        target_device_id: &str,
        sdp: &str,
        is_offer: bool,
    ) -> Result<()> {
        let payload = SignalingPayload {
            msg_type: if is_offer {
                "sdp_offer".to_string()
            } else {
                "sdp_answer".to_string()
            },
            target_device_id: target_device_id.to_string(),
            sdp: Some(sdp.to_string()),
            candidate: None,
        };

        self.send_payload(&payload).await
    }

    /// Sends an ICE candidate to a target device.
    pub async fn send_ice_candidate(
        &self,
        target_device_id: &str,
        candidate: &str,
    ) -> Result<()> {
        let payload = SignalingPayload {
            msg_type: "ice_candidate".to_string(),
            target_device_id: target_device_id.to_string(),
            sdp: None,
            candidate: Some(candidate.to_string()),
        };

        self.send_payload(&payload).await
    }

    /// Subscribes to incoming signaling events from the backend.
    ///
    /// Returns a stream of `SignalingEvent` items. The stream stays open as
    /// long as the WebSocket connection is alive.
    pub async fn subscribe(
        &self,
    ) -> Result<Pin<Box<dyn Stream<Item = SignalingEvent> + Send>>> {
        use futures::StreamExt;
        use tokio_tungstenite::tungstenite::client::IntoClientRequest;

        let ws_url = format!(
            "{}/v1/sync/signaling?device_id={}",
            self.backend_url, self.device_id
        );

        let mut request = ws_url
            .into_client_request()
            .map_err(|e| AppError::Server(format!("Invalid signaling URL: {e}")))?;

        request.headers_mut().insert(
            "Authorization",
            format!("Bearer {}", self.auth_token)
                .parse()
                .map_err(|e| AppError::Server(format!("Invalid auth token header: {e}")))?,
        );

        let (ws_stream, _) = tokio_tungstenite::connect_async(request)
            .await
            .map_err(|e| AppError::Server(format!("Signaling WebSocket connect failed: {e}")))?;

        let stream = ws_stream.filter_map(|msg| async move {
            match msg {
                Ok(tokio_tungstenite::tungstenite::Message::Text(text)) => {
                    serde_json::from_str::<SignalingEvent>(&text).ok()
                }
                _ => None,
            }
        });

        Ok(Box::pin(stream))
    }

    /// Sends a signaling payload to the backend via HTTP POST.
    ///
    /// This is used as a fallback when the WebSocket is not yet established,
    /// or for one-shot messages like the initial SDP offer.
    async fn send_payload(&self, payload: &SignalingPayload) -> Result<()> {
        let url = format!("{}/v1/sync/signal", self.backend_url);

        let client = reqwest::Client::new();
        let response = client
            .post(&url)
            .bearer_auth(&self.auth_token)
            .json(payload)
            .send()
            .await
            .map_err(|e| AppError::Server(format!("Signaling send failed: {e}")))?;

        if !response.status().is_success() {
            let status = response.status().as_u16();
            let body = response.text().await.unwrap_or_default();
            return Err(AppError::Api {
                message: format!("Signaling relay returned {status}"),
                status_code: Some(status),
                body: Some(body),
            });
        }

        Ok(())
    }
}
