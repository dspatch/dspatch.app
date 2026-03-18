// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! WebSocket client for real-time communication with the dspatch backend.
//!
//! Connects to `{backend_url}/ws?token={jwt}` and receives presence events,
//! WebRTC signaling, `sync:ready`, and `PreKeysLow` notifications. Outbound
//! messages (e.g. WebRTC signaling) are sent through the `ws_tx` channel.

use std::collections::HashSet;
use std::sync::Arc;
use std::time::Duration;

use futures::{SinkExt, StreamExt};
use serde::Deserialize;
use tokio::sync::{mpsc, Mutex, RwLock};
use tokio::task::JoinHandle;
use tokio_tungstenite::tungstenite::Message;
use tokio_util::sync::CancellationToken;

use super::signaling::SignalingEvent;

/// Maximum reconnect backoff delay.
const MAX_BACKOFF: Duration = Duration::from_secs(30);

/// Initial reconnect delay.
const INITIAL_BACKOFF: Duration = Duration::from_secs(1);

/// Inbound events from the backend WebSocket.
#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "type")]
pub enum BackendEvent {
    #[serde(rename = "device:online")]
    DeviceOnline { device_id: String },
    #[serde(rename = "device:offline")]
    DeviceOffline { device_id: String },
    #[serde(rename = "device:roster")]
    DeviceRoster { device_ids: Vec<String> },
    #[serde(rename = "sync:ready")]
    SyncReady { count: i64 },
    #[serde(rename = "prekeys:low")]
    PreKeysLow { remaining: i64 },
    #[serde(rename = "webrtc:offer")]
    WebRtcOffer {
        source_device_id: String,
        encrypted_sdp: String,
    },
    #[serde(rename = "webrtc:answer")]
    WebRtcAnswer {
        source_device_id: String,
        encrypted_sdp: String,
    },
    #[serde(rename = "webrtc:ice")]
    WebRtcIce {
        source_device_id: String,
        encrypted_candidate: String,
    },
    #[serde(rename = "pong")]
    Pong,
}

/// WebSocket client for the engine's connection to the backend.
///
/// Maintains a persistent, reconnecting WebSocket connection and dispatches
/// incoming events to the appropriate handlers (presence tracking, signaling).
pub struct EngineWsClient {
    backend_url: String,
    auth_token: Arc<RwLock<String>>,
    device_id: String,
    online_peers: Arc<RwLock<HashSet<String>>>,
    ws_tx: Arc<Mutex<Option<mpsc::Sender<String>>>>,
    signaling_tx: mpsc::Sender<SignalingEvent>,
    #[allow(dead_code)]
    signaling_rx: Arc<Mutex<mpsc::Receiver<SignalingEvent>>>,
}

impl EngineWsClient {
    /// Creates a new `EngineWsClient`.
    ///
    /// The `auth_token` is wrapped in `Arc<RwLock<>>` so it can be refreshed
    /// externally while the WS loop is running.
    pub fn new(
        backend_url: String,
        auth_token: Arc<RwLock<String>>,
        device_id: String,
    ) -> Self {
        let (signaling_tx, signaling_rx) = mpsc::channel(64);
        Self {
            backend_url,
            auth_token,
            device_id,
            online_peers: Arc::new(RwLock::new(HashSet::new())),
            ws_tx: Arc::new(Mutex::new(None)),
            signaling_tx,
            signaling_rx: Arc::new(Mutex::new(signaling_rx)),
        }
    }

    /// Returns the list of currently online peer device IDs.
    pub async fn online_peers(&self) -> Vec<String> {
        self.online_peers.read().await.iter().cloned().collect()
    }

    /// Returns a clone of the current WebSocket sender, if connected.
    pub async fn ws_sender(&self) -> Option<mpsc::Sender<String>> {
        self.ws_tx.lock().await.clone()
    }

    /// Starts the reconnecting WebSocket loop in a background task.
    ///
    /// The loop will keep reconnecting with exponential backoff until the
    /// `cancel` token is triggered.
    pub fn start(self: Arc<Self>, cancel: CancellationToken) -> JoinHandle<()> {
        tokio::spawn(async move {
            let mut backoff = INITIAL_BACKOFF;

            loop {
                if cancel.is_cancelled() {
                    break;
                }

                match self.connect_once(&cancel).await {
                    Ok(()) => {
                        // Clean disconnect (cancellation). Don't reconnect.
                        tracing::info!("Engine WS client shut down cleanly");
                        break;
                    }
                    Err(e) => {
                        tracing::warn!("Engine WS disconnected: {e} — reconnecting in {backoff:?}");

                        // Clear WS sender on disconnect.
                        *self.ws_tx.lock().await = None;

                        tokio::select! {
                            _ = cancel.cancelled() => break,
                            _ = tokio::time::sleep(backoff) => {}
                        }

                        // Exponential backoff with cap.
                        backoff = (backoff * 2).min(MAX_BACKOFF);
                    }
                }
            }
        })
    }

    /// Runs a single WebSocket connection session.
    ///
    /// Returns `Ok(())` if cancelled cleanly, or `Err` if the connection
    /// failed or was lost.
    pub async fn connect_once(&self, cancel: &CancellationToken) -> crate::util::result::Result<()> {
        let token = self.auth_token.read().await.clone();
        let ws_url = self
            .backend_url
            .replacen("http://", "ws://", 1)
            .replacen("https://", "wss://", 1);
        let url = format!("{ws_url}/ws?token={token}");

        tracing::info!("Engine WS connecting to {ws_url}/ws");

        let (ws_stream, _response) = tokio_tungstenite::connect_async(&url)
            .await
            .map_err(|e| crate::util::error::AppError::Server(format!("WS connect failed: {e}")))?;

        let (mut ws_sink, mut ws_stream_rx) = ws_stream.split();

        // Set up outbound channel.
        let (outbound_tx, mut outbound_rx) = mpsc::channel::<String>(64);
        *self.ws_tx.lock().await = Some(outbound_tx);

        // Reset backoff on successful connection.
        // (handled by caller resetting backoff)

        // Subscribe to device presence channel.
        let subscribe_msg = r#"{"type": "subscribe", "channel": "devices"}"#;
        ws_sink
            .send(Message::Text(subscribe_msg.into()))
            .await
            .map_err(|e| {
                crate::util::error::AppError::Server(format!("WS send subscribe failed: {e}"))
            })?;

        tracing::info!(
            "Engine WS connected for device {}",
            self.device_id
        );

        loop {
            tokio::select! {
                _ = cancel.cancelled() => {
                    tracing::debug!("Engine WS cancelled, closing");
                    let _ = ws_sink.close().await;
                    *self.ws_tx.lock().await = None;
                    return Ok(());
                }

                // Outbound messages from other parts of the engine.
                msg = outbound_rx.recv() => {
                    match msg {
                        Some(text) => {
                            if let Err(e) = ws_sink.send(Message::Text(text.into())).await {
                                *self.ws_tx.lock().await = None;
                                return Err(crate::util::error::AppError::Server(
                                    format!("WS send failed: {e}"),
                                ));
                            }
                        }
                        None => {
                            // All senders dropped — shouldn't happen normally.
                            tracing::warn!("Engine WS outbound channel closed");
                        }
                    }
                }

                // Inbound messages from the backend.
                frame = ws_stream_rx.next() => {
                    match frame {
                        Some(Ok(Message::Text(text))) => {
                            match serde_json::from_str::<BackendEvent>(&text) {
                                Ok(event) => {
                                    Self::handle_event(
                                        event,
                                        &self.online_peers,
                                        &self.signaling_tx,
                                    )
                                    .await;
                                }
                                Err(e) => {
                                    tracing::debug!("Unknown WS message: {e} — {text}");
                                }
                            }
                        }
                        Some(Ok(Message::Ping(data))) => {
                            let _ = ws_sink.send(Message::Pong(data)).await;
                        }
                        Some(Ok(Message::Close(_))) | None => {
                            *self.ws_tx.lock().await = None;
                            return Err(crate::util::error::AppError::Server(
                                "WS connection closed by server".into(),
                            ));
                        }
                        Some(Err(e)) => {
                            *self.ws_tx.lock().await = None;
                            return Err(crate::util::error::AppError::Server(
                                format!("WS read error: {e}"),
                            ));
                        }
                        Some(Ok(_)) => {
                            // Binary, Pong, Frame — ignore.
                        }
                    }
                }
            }
        }
    }

    /// Dispatches a parsed `BackendEvent` to the appropriate handler.
    async fn handle_event(
        event: BackendEvent,
        online_peers: &Arc<RwLock<HashSet<String>>>,
        signaling_tx: &mpsc::Sender<SignalingEvent>,
    ) {
        match event {
            BackendEvent::DeviceOnline { device_id } => {
                tracing::info!("Device online: {device_id}");
                online_peers.write().await.insert(device_id.clone());
                let _ = signaling_tx
                    .send(SignalingEvent::DeviceOnline { device_id })
                    .await;
            }
            BackendEvent::DeviceOffline { device_id } => {
                tracing::info!("Device offline: {device_id}");
                online_peers.write().await.remove(&device_id);
                let _ = signaling_tx
                    .send(SignalingEvent::DeviceOffline { device_id })
                    .await;
            }
            BackendEvent::DeviceRoster { device_ids } => {
                tracing::info!("Device roster: {} devices", device_ids.len());
                let mut peers = online_peers.write().await;
                peers.clear();
                for id in device_ids {
                    peers.insert(id);
                }
            }
            BackendEvent::SyncReady { count } => {
                tracing::info!("Sync ready: {count} messages pending on server");
                // TODO: trigger server-relay sync fetch
            }
            BackendEvent::PreKeysLow { remaining } => {
                tracing::warn!("Pre-keys low: {remaining} remaining — should upload more");
                // TODO: trigger pre-key replenishment
            }
            BackendEvent::WebRtcOffer {
                source_device_id,
                encrypted_sdp,
            } => {
                tracing::debug!("WebRTC offer from {source_device_id}");
                let _ = signaling_tx
                    .send(SignalingEvent::SdpOffer {
                        from_device: source_device_id,
                        sdp: encrypted_sdp,
                    })
                    .await;
            }
            BackendEvent::WebRtcAnswer {
                source_device_id,
                encrypted_sdp,
            } => {
                tracing::debug!("WebRTC answer from {source_device_id}");
                let _ = signaling_tx
                    .send(SignalingEvent::SdpAnswer {
                        from_device: source_device_id,
                        sdp: encrypted_sdp,
                    })
                    .await;
            }
            BackendEvent::WebRtcIce {
                source_device_id,
                encrypted_candidate,
            } => {
                tracing::debug!("ICE candidate from {source_device_id}");
                let _ = signaling_tx
                    .send(SignalingEvent::IceCandidate {
                        from_device: source_device_id,
                        candidate: encrypted_candidate,
                    })
                    .await;
            }
            BackendEvent::Pong => {
                tracing::trace!("WS pong received");
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deserialize_device_online() {
        let json = r#"{"type": "device:online", "device_id": "abc-123"}"#;
        let event: BackendEvent = serde_json::from_str(json).unwrap();
        assert!(matches!(event, BackendEvent::DeviceOnline { device_id } if device_id == "abc-123"));
    }

    #[test]
    fn deserialize_device_roster() {
        let json = r#"{"type": "device:roster", "device_ids": ["a", "b", "c"]}"#;
        let event: BackendEvent = serde_json::from_str(json).unwrap();
        assert!(
            matches!(event, BackendEvent::DeviceRoster { device_ids } if device_ids.len() == 3)
        );
    }

    #[test]
    fn deserialize_sync_ready() {
        let json = r#"{"type": "sync:ready", "count": 42}"#;
        let event: BackendEvent = serde_json::from_str(json).unwrap();
        assert!(matches!(event, BackendEvent::SyncReady { count } if count == 42));
    }

    #[test]
    fn deserialize_prekeys_low() {
        let json = r#"{"type": "prekeys:low", "remaining": 5}"#;
        let event: BackendEvent = serde_json::from_str(json).unwrap();
        assert!(matches!(event, BackendEvent::PreKeysLow { remaining } if remaining == 5));
    }

    #[test]
    fn deserialize_webrtc_offer() {
        let json =
            r#"{"type": "webrtc:offer", "source_device_id": "dev-1", "encrypted_sdp": "sdp-data"}"#;
        let event: BackendEvent = serde_json::from_str(json).unwrap();
        assert!(matches!(event, BackendEvent::WebRtcOffer { source_device_id, .. } if source_device_id == "dev-1"));
    }

    #[test]
    fn deserialize_pong() {
        let json = r#"{"type": "pong"}"#;
        let event: BackendEvent = serde_json::from_str(json).unwrap();
        assert!(matches!(event, BackendEvent::Pong));
    }

    #[tokio::test]
    async fn handle_event_tracks_online_peers() {
        let peers = Arc::new(RwLock::new(HashSet::new()));
        let (tx, _rx) = mpsc::channel(16);

        // Device comes online.
        EngineWsClient::handle_event(
            BackendEvent::DeviceOnline {
                device_id: "dev-a".into(),
            },
            &peers,
            &tx,
        )
        .await;
        assert!(peers.read().await.contains("dev-a"));

        // Another device comes online.
        EngineWsClient::handle_event(
            BackendEvent::DeviceOnline {
                device_id: "dev-b".into(),
            },
            &peers,
            &tx,
        )
        .await;
        assert_eq!(peers.read().await.len(), 2);

        // Device goes offline.
        EngineWsClient::handle_event(
            BackendEvent::DeviceOffline {
                device_id: "dev-a".into(),
            },
            &peers,
            &tx,
        )
        .await;
        assert!(!peers.read().await.contains("dev-a"));
        assert_eq!(peers.read().await.len(), 1);
    }

    #[tokio::test]
    async fn handle_event_roster_replaces_peers() {
        let peers = Arc::new(RwLock::new(HashSet::new()));
        let (tx, _rx) = mpsc::channel(16);

        // Pre-populate.
        peers.write().await.insert("old-device".into());

        // Roster replaces everything.
        EngineWsClient::handle_event(
            BackendEvent::DeviceRoster {
                device_ids: vec!["x".into(), "y".into()],
            },
            &peers,
            &tx,
        )
        .await;

        let set = peers.read().await;
        assert_eq!(set.len(), 2);
        assert!(set.contains("x"));
        assert!(set.contains("y"));
        assert!(!set.contains("old-device"));
    }

    #[tokio::test]
    async fn handle_event_forwards_signaling() {
        let peers = Arc::new(RwLock::new(HashSet::new()));
        let (tx, mut rx) = mpsc::channel(16);

        EngineWsClient::handle_event(
            BackendEvent::WebRtcOffer {
                source_device_id: "dev-1".into(),
                encrypted_sdp: "sdp".into(),
            },
            &peers,
            &tx,
        )
        .await;

        let event = rx.recv().await.unwrap();
        assert!(matches!(event, SignalingEvent::SdpOffer { from_device, sdp }
            if from_device == "dev-1" && sdp == "sdp"));
    }
}
