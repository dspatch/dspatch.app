// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Signaling client for WebRTC connection establishment.
//!
//! Sends SDP offers/answers and ICE candidates through the engine's main
//! WebSocket connection to the backend, which relays them to the target device.

use serde::{Deserialize, Serialize};
use tokio::sync::mpsc;

use crate::util::error::AppError;
use crate::util::result::Result;

/// An event received from the backend's WebSocket.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SignalingEvent {
    SdpOffer { from_device: String, sdp: String },
    SdpAnswer { from_device: String, sdp: String },
    IceCandidate { from_device: String, candidate: String },
    DeviceOnline { device_id: String },
    DeviceOffline { device_id: String },
}

/// Outbound WebSocket message matching backend's ClientMessage enum.
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type")]
pub enum WsClientMessage {
    #[serde(rename = "webrtc:offer")]
    WebRtcOffer { target_device_id: String, encrypted_sdp: String },
    #[serde(rename = "webrtc:answer")]
    WebRtcAnswer { target_device_id: String, encrypted_sdp: String },
    #[serde(rename = "webrtc:ice")]
    WebRtcIce { target_device_id: String, encrypted_candidate: String },
}

/// Client for WebRTC signaling via the engine's main WebSocket.
pub struct SignalingClient {
    device_id: String,
    /// Sender for outbound WebSocket messages. Set when WebSocket connects.
    ws_tx: Option<mpsc::Sender<String>>,
}

impl SignalingClient {
    pub fn new(device_id: &str) -> Self {
        Self {
            device_id: device_id.to_string(),
            ws_tx: None,
        }
    }

    /// Sets the WebSocket sender. Called when the engine's WS connects.
    pub fn set_ws_sender(&mut self, tx: mpsc::Sender<String>) {
        self.ws_tx = Some(tx);
    }

    pub fn device_id(&self) -> &str {
        &self.device_id
    }

    pub async fn send_sdp_offer(&self, target_device_id: &str, sdp: &str) -> Result<()> {
        self.send_ws_message(WsClientMessage::WebRtcOffer {
            target_device_id: target_device_id.to_string(),
            encrypted_sdp: sdp.to_string(),
        }).await
    }

    pub async fn send_sdp_answer(&self, target_device_id: &str, sdp: &str) -> Result<()> {
        self.send_ws_message(WsClientMessage::WebRtcAnswer {
            target_device_id: target_device_id.to_string(),
            encrypted_sdp: sdp.to_string(),
        }).await
    }

    pub async fn send_ice_candidate(&self, target_device_id: &str, candidate: &str) -> Result<()> {
        self.send_ws_message(WsClientMessage::WebRtcIce {
            target_device_id: target_device_id.to_string(),
            encrypted_candidate: candidate.to_string(),
        }).await
    }

    async fn send_ws_message(&self, msg: WsClientMessage) -> Result<()> {
        let tx = self.ws_tx.as_ref().ok_or_else(|| {
            AppError::Server("WebSocket not connected — cannot send signaling message".into())
        })?;

        let json = serde_json::to_string(&msg)
            .map_err(|e| AppError::Internal(format!("Failed to serialize signaling message: {e}")))?;

        tx.send(json).await
            .map_err(|_| AppError::Server("WebSocket channel closed".into()))?;

        Ok(())
    }
}
