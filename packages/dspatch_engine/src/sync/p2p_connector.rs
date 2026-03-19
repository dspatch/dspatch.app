// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! P2P connection orchestrator — drives WebRTC handshakes when peers come online.
//!
//! Listens for signaling events from the `BackendWsClient` and initiates or
//! accepts WebRTC data channel connections. Once a data channel opens, registers
//! it with the `PeerConnectionManager` so the sync engine can exchange data.

use std::collections::HashMap;
use std::sync::Arc;

use tokio::sync::{mpsc, Mutex};
use tokio_util::sync::CancellationToken;
use webrtc::ice_transport::ice_server::RTCIceServer;

use super::backend_client::BackendWsClient;
use super::peer_connection::PeerConnectionManager;
use super::signaling::{SignalingEvent, WsClientMessage};
use super::webrtc_transport::WebRtcTransport;

/// Spawns the P2P connection orchestrator as a background task.
pub fn spawn_p2p_connector(
    my_device_id: String,
    signaling_rx: Arc<Mutex<mpsc::Receiver<SignalingEvent>>>,
    ws_client: Arc<BackendWsClient>,
    peer_manager: Arc<PeerConnectionManager>,
    cancel: CancellationToken,
) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        let transports: Arc<Mutex<HashMap<String, Arc<WebRtcTransport>>>> =
            Arc::new(Mutex::new(HashMap::new()));

        let mut rx = signaling_rx.lock().await;

        loop {
            tokio::select! {
                _ = cancel.cancelled() => break,
                event = rx.recv() => {
                    let Some(event) = event else { break };

                    match event {
                        SignalingEvent::DeviceOnline { device_id } => {
                            // Skip self.
                            if device_id == my_device_id { continue; }
                            // Skip if already connected.
                            if peer_manager.connected_devices().await.contains(&device_id) {
                                tracing::debug!("Already connected to {device_id}, skipping");
                                continue;
                            }

                            // Glare prevention: lower device ID initiates.
                            if my_device_id < device_id {
                                tracing::info!("Peer {device_id} online — initiating WebRTC offer");
                                let transports = Arc::clone(&transports);
                                let ws = Arc::clone(&ws_client);
                                let pm = Arc::clone(&peer_manager);
                                let peer_id = device_id.clone();
                                tokio::spawn(async move {
                                    if let Err(e) = initiate_connection(&peer_id, &transports, &ws, &pm).await {
                                        tracing::warn!("WebRTC offer to {peer_id} failed: {e}");
                                    }
                                });
                            } else {
                                tracing::info!("Peer {device_id} online — waiting for their offer");
                            }
                        }

                        SignalingEvent::DeviceOffline { device_id } => {
                            tracing::info!("Peer {device_id} offline — cleaning up");
                            transports.lock().await.remove(&device_id);
                            peer_manager.disconnect(&device_id).await;
                        }

                        SignalingEvent::SdpOffer { from_device, sdp } => {
                            tracing::info!("Received SDP offer from {from_device}");
                            let transports = Arc::clone(&transports);
                            let ws = Arc::clone(&ws_client);
                            let pm = Arc::clone(&peer_manager);
                            let peer_id = from_device.clone();
                            tokio::spawn(async move {
                                if let Err(e) = accept_connection(&peer_id, &sdp, &transports, &ws, &pm).await {
                                    tracing::warn!("WebRTC answer to {peer_id} failed: {e}");
                                }
                            });
                        }

                        SignalingEvent::SdpAnswer { from_device, sdp } => {
                            tracing::info!("Received SDP answer from {from_device}");
                            let transports = transports.lock().await;
                            if let Some(transport) = transports.get(&from_device) {
                                if let Err(e) = transport.accept_answer(&sdp).await {
                                    tracing::warn!("Failed to set remote SDP from {from_device}: {e}");
                                }
                            } else {
                                tracing::warn!("No pending transport for SDP answer from {from_device}");
                            }
                        }

                        SignalingEvent::IceCandidate { from_device, candidate } => {
                            let transports = transports.lock().await;
                            if let Some(transport) = transports.get(&from_device) {
                                if let Err(e) = transport.add_ice_candidate(&candidate).await {
                                    tracing::warn!("Failed to add ICE candidate from {from_device}: {e}");
                                }
                            }
                        }
                    }
                }
            }
        }

        tracing::info!("P2P connector stopped");
    })
}

/// Sends a signaling message through the backend WS.
async fn send_signaling(ws: &BackendWsClient, msg: WsClientMessage) -> crate::util::result::Result<()> {
    let tx = ws.ws_sender().await.ok_or_else(|| {
        crate::util::error::AppError::Server("Backend WS not connected — cannot send signaling".into())
    })?;
    let json = serde_json::to_string(&msg)
        .map_err(|e| crate::util::error::AppError::Internal(format!("Serialize signaling: {e}")))?;
    tx.send(json).await
        .map_err(|_| crate::util::error::AppError::Server("Backend WS channel closed".into()))?;
    Ok(())
}

/// Initiates a WebRTC connection to a peer (offerer side).
async fn initiate_connection(
    peer_id: &str,
    transports: &Arc<Mutex<HashMap<String, Arc<WebRtcTransport>>>>,
    ws: &Arc<BackendWsClient>,
    peer_manager: &Arc<PeerConnectionManager>,
) -> crate::util::result::Result<()> {
    let ice_servers = vec![RTCIceServer {
        urls: vec!["stun:stun.l.google.com:19302".to_string()],
        ..Default::default()
    }];

    let (transport, offer_sdp) = WebRtcTransport::create_offer(ice_servers).await?;
    let transport = Arc::new(transport);

    transports.lock().await.insert(peer_id.to_string(), Arc::clone(&transport));

    // Send offer.
    send_signaling(ws, WsClientMessage::WebRtcOffer {
        target_device_id: peer_id.to_string(),
        encrypted_sdp: offer_sdp,
    }).await?;

    tracing::info!("SDP offer sent to {peer_id}");

    // Send ICE candidates after a brief gathering delay.
    let ws_ice = Arc::clone(ws);
    let transport_ice = Arc::clone(&transport);
    let peer_id_ice = peer_id.to_string();
    tokio::spawn(async move {
        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
        let candidates = transport_ice.pending_ice_candidates().await;
        tracing::info!("Sending {} ICE candidates to {peer_id_ice}", candidates.len());
        for candidate in candidates {
            if let Err(e) = send_signaling(&ws_ice, WsClientMessage::WebRtcIce {
                target_device_id: peer_id_ice.clone(),
                encrypted_candidate: candidate,
            }).await {
                tracing::warn!("Failed to send ICE candidate to {peer_id_ice}: {e}");
            }
        }
    });

    // Wait for data channel to open and register with peer manager.
    let transport_ready = Arc::clone(&transport);
    let peer_id_owned = peer_id.to_string();
    let pm = Arc::clone(peer_manager);
    tokio::spawn(async move {
        transport_ready.wait_ready().await;
        tracing::info!("WebRTC data channel open with {peer_id_owned}");
        register_transport(&peer_id_owned, &transport_ready, &pm).await;
    });

    Ok(())
}

/// Accepts a WebRTC connection from a peer (answerer side).
async fn accept_connection(
    peer_id: &str,
    offer_sdp: &str,
    transports: &Arc<Mutex<HashMap<String, Arc<WebRtcTransport>>>>,
    ws: &Arc<BackendWsClient>,
    peer_manager: &Arc<PeerConnectionManager>,
) -> crate::util::result::Result<()> {
    let ice_servers = vec![RTCIceServer {
        urls: vec!["stun:stun.l.google.com:19302".to_string()],
        ..Default::default()
    }];

    let (transport, answer_sdp) = WebRtcTransport::create_answer(ice_servers, offer_sdp).await?;
    let transport = Arc::new(transport);

    transports.lock().await.insert(peer_id.to_string(), Arc::clone(&transport));

    // Send answer.
    send_signaling(ws, WsClientMessage::WebRtcAnswer {
        target_device_id: peer_id.to_string(),
        encrypted_sdp: answer_sdp,
    }).await?;

    tracing::info!("SDP answer sent to {peer_id}");

    // Send ICE candidates.
    let ws_ice = Arc::clone(ws);
    let transport_ice = Arc::clone(&transport);
    let peer_id_ice = peer_id.to_string();
    tokio::spawn(async move {
        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
        let candidates = transport_ice.pending_ice_candidates().await;
        tracing::info!("Sending {} ICE candidates to {peer_id_ice}", candidates.len());
        for candidate in candidates {
            if let Err(e) = send_signaling(&ws_ice, WsClientMessage::WebRtcIce {
                target_device_id: peer_id_ice.clone(),
                encrypted_candidate: candidate,
            }).await {
                tracing::warn!("Failed to send ICE candidate to {peer_id_ice}: {e}");
            }
        }
    });

    // Wait for data channel to open and register.
    let transport_ready = Arc::clone(&transport);
    let peer_id_owned = peer_id.to_string();
    let pm = Arc::clone(peer_manager);
    tokio::spawn(async move {
        transport_ready.wait_ready().await;
        tracing::info!("WebRTC data channel open with {peer_id_owned}");
        register_transport(&peer_id_owned, &transport_ready, &pm).await;
    });

    Ok(())
}

/// Registers a WebRTC transport's data channel with the PeerConnectionManager.
///
/// The bridge passes bytes directly between PeerConnectionManager and WebRTC.
/// Encryption is handled by PeerConnectionManager.send() (encrypts) and
/// dispatch_incoming() (decrypts) — the callers (sync_to_peer, sync_loop)
/// use the encrypted send/dispatch paths, NOT send_raw.
///
/// The bridge itself is a transparent byte pipe:
/// - Outbound: PeerConnectionManager tx channel → WebRTC send
/// - Inbound: WebRTC recv → PeerConnectionManager dispatch_incoming
async fn register_transport(
    peer_id: &str,
    transport: &Arc<WebRtcTransport>,
    peer_manager: &Arc<PeerConnectionManager>,
) {
    let (tx, mut outbound_rx) = mpsc::channel::<Vec<u8>>(256);
    let (_unused_tx, rx) = mpsc::channel::<Vec<u8>>(256);

    peer_manager.register_peer(peer_id, tx, rx).await;
    tracing::info!("Peer {peer_id} registered with PeerConnectionManager");

    // Bridge outbound: PeerConnectionManager send_raw() → WebRTC data channel.
    // WebRTC provides DTLS transport encryption. Signal E2E encryption over
    // WebRTC data channels will be added once libsignal Send bounds are resolved.
    let transport_send = Arc::clone(transport);
    let peer_id_send = peer_id.to_string();
    tokio::spawn(async move {
        while let Some(data) = outbound_rx.recv().await {
            if let Err(e) = transport_send.send(&data).await {
                tracing::warn!("WebRTC send to {peer_id_send} failed: {e}");
                break;
            }
        }
    });

    // Bridge inbound: WebRTC data channel → deserialize → dispatch_incoming_plaintext → sync_loop.
    let transport_recv = Arc::clone(transport);
    let peer_id_recv = peer_id.to_string();
    let pm = Arc::clone(peer_manager);
    tokio::spawn(async move {
        while let Some(data) = transport_recv.recv().await {
            match serde_json::from_slice::<crate::sync::SyncMessage>(&data) {
                Ok(message) => {
                    if let Err(e) = pm.dispatch_incoming_plaintext(&peer_id_recv, message).await {
                        tracing::warn!("Failed to dispatch incoming from {peer_id_recv}: {e}");
                    }
                }
                Err(e) => {
                    tracing::warn!("Invalid SyncMessage from {peer_id_recv}: {e} (len={})", data.len());
                }
            }
        }
        tracing::info!("WebRTC receive bridge closed for {peer_id_recv}");
    });
}
