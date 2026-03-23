// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! WebRTC data channel transport for P2P sync.
//!
//! Wraps the `webrtc-rs` crate to establish RTCPeerConnections, negotiate SDP,
//! handle ICE candidates, and provide an ordered, reliable data channel named
//! "sync" for exchanging encrypted sync messages between devices.

use std::sync::Arc;

use bytes::Bytes;
use tokio::sync::{mpsc, Mutex, Notify};
use webrtc::api::interceptor_registry::register_default_interceptors;
use webrtc::api::media_engine::MediaEngine;
use webrtc::api::APIBuilder;
use webrtc::data_channel::data_channel_message::DataChannelMessage;
use webrtc::data_channel::RTCDataChannel;
use webrtc::ice_transport::ice_candidate::RTCIceCandidateInit;
use webrtc::ice_transport::ice_server::RTCIceServer;
use webrtc::interceptor::registry::Registry;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use webrtc::peer_connection::RTCPeerConnection;

use crate::util::error::AppError;
use crate::util::result::Result;

/// Name of the data channel used for sync message exchange.
const DATA_CHANNEL_LABEL: &str = "sync";

/// Capacity for the internal receive buffer.
const RECV_CHANNEL_CAPACITY: usize = 512;

/// A WebRTC data channel transport for P2P sync.
///
/// Encapsulates an `RTCPeerConnection` with a single ordered, reliable data
/// channel. The offerer creates the data channel; the answerer receives it
/// via the `on_data_channel` callback.
pub struct WebRtcTransport {
    peer_connection: Arc<RTCPeerConnection>,
    /// Handle to the data channel (set once the channel opens).
    data_channel: Arc<Mutex<Option<Arc<RTCDataChannel>>>>,
    /// Receive side: incoming messages from the remote peer.
    data_channel_rx: Arc<Mutex<mpsc::Receiver<Vec<u8>>>>,
    /// Gathered ICE candidates (serialized as JSON) — used as a buffer
    /// for candidates gathered before the trickle task starts.
    ice_candidates: Arc<Mutex<Vec<String>>>,
    /// Trickle ICE: candidates are sent here as they're gathered.
    /// The p2p_connector reads from this and sends each one immediately.
    /// Kept alive so callback clones of the sender remain valid.
    #[allow(dead_code)]
    ice_trickle_tx: mpsc::Sender<String>,
    /// Receiver end for the trickle ICE channel.
    ice_trickle_rx: Arc<Mutex<Option<mpsc::Receiver<String>>>>,
    /// Notified when the data channel is open and ready to send/receive.
    ready: Arc<Notify>,
}

impl WebRtcTransport {
    // ------------------------------------------------------------------
    // Construction helpers
    // ------------------------------------------------------------------

    /// Builds a `webrtc::api::API` with default media engine and interceptors.
    fn build_api() -> Result<webrtc::api::API> {
        let mut media_engine = MediaEngine::default();
        let registry = Registry::new();
        let registry = register_default_interceptors(registry, &mut media_engine)
            .map_err(|e| AppError::Internal(format!("Failed to register interceptors: {e}")))?;

        Ok(APIBuilder::new()
            .with_media_engine(media_engine)
            .with_interceptor_registry(registry)
            .build())
    }

    /// Builds an `RTCConfiguration` from a list of ICE servers.
    fn build_config(ice_servers: Vec<RTCIceServer>) -> RTCConfiguration {
        RTCConfiguration {
            ice_servers,
            ..Default::default()
        }
    }

    /// Wires up the `on_ice_candidate` callback to collect gathered candidates
    /// and forward them to the trickle ICE channel for immediate sending.
    fn setup_ice_gathering(
        pc: &Arc<RTCPeerConnection>,
        candidates: Arc<Mutex<Vec<String>>>,
        trickle_tx: mpsc::Sender<String>,
    ) {
        pc.on_ice_candidate(Box::new(move |candidate| {
            let candidates = Arc::clone(&candidates);
            let trickle_tx = trickle_tx.clone();
            Box::pin(async move {
                if let Some(c) = candidate {
                    if let Ok(init) = c.to_json() {
                        if let Ok(json) = serde_json::to_string(&init) {
                            // Buffer for pending_ice_candidates() fallback.
                            candidates.lock().await.push(json.clone());
                            // Send immediately via trickle channel.
                            let _ = trickle_tx.send(json).await;
                        }
                    }
                }
            })
        }));
    }

    /// Wires `on_open` and `on_message` callbacks on a data channel so that
    /// incoming bytes are forwarded to `tx` and `ready` is notified on open.
    fn setup_data_channel_callbacks(
        dc: &Arc<RTCDataChannel>,
        dc_holder: Arc<Mutex<Option<Arc<RTCDataChannel>>>>,
        tx: mpsc::Sender<Vec<u8>>,
        ready: Arc<Notify>,
    ) {
        let dc_for_open = Arc::clone(dc);
        let dc_holder_for_open = Arc::clone(&dc_holder);
        let ready_for_open = Arc::clone(&ready);
        dc.on_open(Box::new(move || {
            let dc = Arc::clone(&dc_for_open);
            let holder = Arc::clone(&dc_holder_for_open);
            let ready = Arc::clone(&ready_for_open);
            Box::pin(async move {
                tracing::info!(label = dc.label(), "WebRTC data channel open");
                *holder.lock().await = Some(dc);
                ready.notify_waiters();
            })
        }));

        dc.on_message(Box::new(move |msg: DataChannelMessage| {
            let tx = tx.clone();
            Box::pin(async move {
                let _ = tx.send(msg.data.to_vec()).await;
            })
        }));
    }

    // ------------------------------------------------------------------
    // Offerer flow
    // ------------------------------------------------------------------

    /// Creates a new WebRTC transport as the **offerer**.
    ///
    /// Returns `(transport, sdp_offer_json)`. The caller must send the SDP
    /// offer to the remote peer via signaling, receive the SDP answer, and
    /// call [`accept_answer`](Self::accept_answer).
    pub async fn create_offer(ice_servers: Vec<RTCIceServer>) -> Result<(Self, String)> {
        let api = Self::build_api()?;
        let config = Self::build_config(ice_servers);

        let pc = Arc::new(
            api.new_peer_connection(config)
                .await
                .map_err(|e| AppError::Internal(format!("Failed to create RTCPeerConnection: {e}")))?,
        );

        // Shared state.
        let ice_candidates: Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));
        let (tx, rx) = mpsc::channel(RECV_CHANNEL_CAPACITY);
        let (trickle_tx, trickle_rx) = mpsc::channel::<String>(64);
        let ready = Arc::new(Notify::new());
        let dc_holder: Arc<Mutex<Option<Arc<RTCDataChannel>>>> = Arc::new(Mutex::new(None));

        // ICE gathering with trickle support.
        Self::setup_ice_gathering(&pc, Arc::clone(&ice_candidates), trickle_tx.clone());

        // Create the data channel (offerer creates it).
        let dc = pc
            .create_data_channel(DATA_CHANNEL_LABEL, None)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to create data channel: {e}")))?;

        Self::setup_data_channel_callbacks(&dc, Arc::clone(&dc_holder), tx, Arc::clone(&ready));

        // Create & set local description (SDP offer).
        let offer = pc
            .create_offer(None)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to create SDP offer: {e}")))?;

        pc.set_local_description(offer.clone())
            .await
            .map_err(|e| AppError::Internal(format!("Failed to set local description: {e}")))?;

        let sdp_json = serde_json::to_string(&offer)
            .map_err(|e| AppError::Internal(format!("Failed to serialize SDP offer: {e}")))?;

        let transport = Self {
            peer_connection: pc,
            data_channel: dc_holder,
            data_channel_rx: Arc::new(Mutex::new(rx)),
            ice_candidates,
            ice_trickle_tx: trickle_tx,
            ice_trickle_rx: Arc::new(Mutex::new(Some(trickle_rx))),
            ready,
        };

        Ok((transport, sdp_json))
    }

    /// Sets the remote SDP answer on this offerer transport.
    pub async fn accept_answer(&self, sdp_json: &str) -> Result<()> {
        let answer: RTCSessionDescription = serde_json::from_str(sdp_json)
            .map_err(|e| AppError::Internal(format!("Failed to parse SDP answer: {e}")))?;

        self.peer_connection
            .set_remote_description(answer)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to set remote description: {e}")))?;

        Ok(())
    }

    // ------------------------------------------------------------------
    // Answerer flow
    // ------------------------------------------------------------------

    /// Creates a new WebRTC transport as the **answerer**.
    ///
    /// Takes the remote peer's SDP offer and returns `(transport, sdp_answer_json)`.
    pub async fn create_answer(
        ice_servers: Vec<RTCIceServer>,
        offer_sdp_json: &str,
    ) -> Result<(Self, String)> {
        let api = Self::build_api()?;
        let config = Self::build_config(ice_servers);

        let pc = Arc::new(
            api.new_peer_connection(config)
                .await
                .map_err(|e| AppError::Internal(format!("Failed to create RTCPeerConnection: {e}")))?,
        );

        // Shared state.
        let ice_candidates: Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));
        let (tx, rx) = mpsc::channel(RECV_CHANNEL_CAPACITY);
        let (trickle_tx, trickle_rx) = mpsc::channel::<String>(64);
        let ready = Arc::new(Notify::new());
        let dc_holder: Arc<Mutex<Option<Arc<RTCDataChannel>>>> = Arc::new(Mutex::new(None));

        // ICE gathering with trickle support.
        Self::setup_ice_gathering(&pc, Arc::clone(&ice_candidates), trickle_tx.clone());

        // The answerer receives the data channel via callback.
        let dc_holder_for_cb = Arc::clone(&dc_holder);
        let tx_for_cb = tx.clone();
        let ready_for_cb = Arc::clone(&ready);
        pc.on_data_channel(Box::new(move |dc: Arc<RTCDataChannel>| {
            let dc_holder = Arc::clone(&dc_holder_for_cb);
            let tx = tx_for_cb.clone();
            let ready = Arc::clone(&ready_for_cb);
            Box::pin(async move {
                tracing::info!(label = dc.label(), "Answerer received data channel");
                Self::setup_data_channel_callbacks(&dc, dc_holder, tx, ready);
            })
        }));

        // Set remote offer.
        let offer: RTCSessionDescription = serde_json::from_str(offer_sdp_json)
            .map_err(|e| AppError::Internal(format!("Failed to parse SDP offer: {e}")))?;

        pc.set_remote_description(offer)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to set remote description: {e}")))?;

        // Create & set local answer.
        let answer = pc
            .create_answer(None)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to create SDP answer: {e}")))?;

        pc.set_local_description(answer.clone())
            .await
            .map_err(|e| AppError::Internal(format!("Failed to set local description: {e}")))?;

        let sdp_json = serde_json::to_string(&answer)
            .map_err(|e| AppError::Internal(format!("Failed to serialize SDP answer: {e}")))?;

        let transport = Self {
            peer_connection: pc,
            data_channel: dc_holder,
            data_channel_rx: Arc::new(Mutex::new(rx)),
            ice_candidates,
            ice_trickle_tx: trickle_tx,
            ice_trickle_rx: Arc::new(Mutex::new(Some(trickle_rx))),
            ready,
        };

        Ok((transport, sdp_json))
    }

    // ------------------------------------------------------------------
    // ICE candidate exchange
    // ------------------------------------------------------------------

    /// Adds a remote ICE candidate received via signaling.
    pub async fn add_ice_candidate(&self, candidate_json: &str) -> Result<()> {
        let init: RTCIceCandidateInit = serde_json::from_str(candidate_json)
            .map_err(|e| AppError::Internal(format!("Failed to parse ICE candidate: {e}")))?;

        self.peer_connection
            .add_ice_candidate(init)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to add ICE candidate: {e}")))?;

        Ok(())
    }

    /// Returns all locally gathered ICE candidates (as JSON strings).
    ///
    /// Call this after creating the offer/answer and send each candidate
    /// to the remote peer via signaling.
    pub async fn pending_ice_candidates(&self) -> Vec<String> {
        self.ice_candidates.lock().await.clone()
    }

    /// Takes the trickle ICE receiver for immediate candidate forwarding.
    ///
    /// Returns `None` if already taken (single-consumer). The p2p_connector
    /// spawns a task that reads from this receiver and sends each candidate
    /// via signaling immediately as it's gathered.
    pub async fn take_trickle_rx(&self) -> Option<mpsc::Receiver<String>> {
        self.ice_trickle_rx.lock().await.take()
    }

    // ------------------------------------------------------------------
    // Data transfer
    // ------------------------------------------------------------------

    /// Waits until the data channel is open and ready.
    pub async fn wait_ready(&self) {
        self.ready.notified().await;
    }

    /// Sends binary data on the data channel.
    pub async fn send(&self, data: &[u8]) -> Result<()> {
        let dc_guard = self.data_channel.lock().await;
        let dc = dc_guard.as_ref().ok_or_else(|| {
            AppError::Internal("Data channel not yet open".into())
        })?;

        dc.send(&Bytes::copy_from_slice(data))
            .await
            .map_err(|e| AppError::Internal(format!("Data channel send failed: {e}")))?;

        Ok(())
    }

    /// Receives the next message from the data channel.
    ///
    /// Returns `None` if the channel has been closed.
    pub async fn recv(&self) -> Option<Vec<u8>> {
        let mut rx = self.data_channel_rx.lock().await;
        rx.recv().await
    }

    /// Closes the peer connection and data channel.
    pub async fn close(&self) {
        if let Err(e) = self.peer_connection.close().await {
            tracing::warn!("Error closing RTCPeerConnection: {e}");
        }
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    /// Verifies that `create_offer` produces a valid SDP offer.
    #[tokio::test]
    async fn test_create_offer_produces_sdp() {
        let ice_servers = vec![RTCIceServer {
            urls: vec!["stun:stun.l.google.com:19302".to_string()],
            ..Default::default()
        }];

        let (transport, sdp_json) = WebRtcTransport::create_offer(ice_servers)
            .await
            .expect("create_offer should succeed");

        // SDP should be valid JSON containing an offer.
        assert!(!sdp_json.is_empty(), "SDP JSON should not be empty");
        assert!(sdp_json.contains("offer"), "SDP should be of type offer");
        assert!(sdp_json.contains("v=0"), "SDP should contain SDP content");

        transport.close().await;
    }

    /// Loopback test: two transports exchange offer/answer and communicate
    /// over the data channel.
    #[tokio::test]
    async fn test_loopback_offer_answer_data_exchange() {
        let ice_servers = vec![RTCIceServer {
            urls: vec!["stun:stun.l.google.com:19302".to_string()],
            ..Default::default()
        }];

        // Offerer creates offer.
        let (offerer, offer_sdp) = WebRtcTransport::create_offer(ice_servers.clone())
            .await
            .expect("create_offer should succeed");

        // Answerer creates answer from the offer.
        let (answerer, answer_sdp) =
            WebRtcTransport::create_answer(ice_servers.clone(), &offer_sdp)
                .await
                .expect("create_answer should succeed");

        // Offerer accepts the answer.
        offerer
            .accept_answer(&answer_sdp)
            .await
            .expect("accept_answer should succeed");

        // Exchange ICE candidates (offerer -> answerer, answerer -> offerer).
        // Give a moment for ICE gathering.
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;

        for candidate in offerer.pending_ice_candidates().await {
            let _ = answerer.add_ice_candidate(&candidate).await;
        }
        for candidate in answerer.pending_ice_candidates().await {
            let _ = offerer.add_ice_candidate(&candidate).await;
        }

        // Wait for both data channels to open (with timeout).
        let timeout = std::time::Duration::from_secs(10);
        tokio::select! {
            _ = offerer.wait_ready() => {},
            _ = tokio::time::sleep(timeout) => {
                // In CI or environments without network, ICE may not complete.
                // Close and skip the data exchange portion.
                tracing::warn!("Offerer data channel did not open in time — skipping data exchange (expected in restricted network environments)");
                offerer.close().await;
                answerer.close().await;
                return;
            }
        }
        tokio::select! {
            _ = answerer.wait_ready() => {},
            _ = tokio::time::sleep(timeout) => {
                tracing::warn!("Answerer data channel did not open in time — skipping data exchange");
                offerer.close().await;
                answerer.close().await;
                return;
            }
        }

        // Send data offerer -> answerer.
        let payload = b"hello from offerer";
        offerer.send(payload).await.expect("send should succeed");

        let received = tokio::time::timeout(timeout, answerer.recv())
            .await
            .expect("recv should not timeout")
            .expect("should receive a message");

        assert_eq!(received, payload);

        // Cleanup.
        offerer.close().await;
        answerer.close().await;
    }
}
