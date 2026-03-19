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

use super::peer_connection::PeerConnectionManager;
use super::signaling::{SignalingClient, SignalingEvent};
use super::webrtc_transport::WebRtcTransport;

/// Spawns the P2P connection orchestrator as a background task.
///
/// - `my_device_id`: this device's ID (for glare resolution — lower ID initiates)
/// - `signaling_rx`: receives events from BackendWsClient
/// - `signaling_client`: sends SDP/ICE through the backend WS
/// - `peer_manager`: registers data channels for sync
/// - `cancel`: stops the task
pub fn spawn_p2p_connector(
    my_device_id: String,
    signaling_rx: Arc<Mutex<mpsc::Receiver<SignalingEvent>>>,
    signaling_client: Arc<Mutex<SignalingClient>>,
    peer_manager: Arc<PeerConnectionManager>,
    cancel: CancellationToken,
) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        // Track active WebRTC transports by peer device ID.
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
                            // Glare prevention: lower device ID initiates.
                            if my_device_id < device_id {
                                tracing::info!("Peer {device_id} online — initiating WebRTC offer");
                                let transports = Arc::clone(&transports);
                                let sig = Arc::clone(&signaling_client);
                                let pm = Arc::clone(&peer_manager);
                                let peer_id = device_id.clone();
                                let my_id = my_device_id.clone();
                                tokio::spawn(async move {
                                    if let Err(e) = initiate_connection(&my_id, &peer_id, &transports, &sig, &pm).await {
                                        tracing::warn!("WebRTC offer to {peer_id} failed: {e}");
                                    }
                                });
                            } else {
                                tracing::info!("Peer {device_id} online — waiting for their offer (they have lower ID)");
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
                            let sig = Arc::clone(&signaling_client);
                            let pm = Arc::clone(&peer_manager);
                            let peer_id = from_device.clone();
                            tokio::spawn(async move {
                                if let Err(e) = accept_connection(&peer_id, &sdp, &transports, &sig, &pm).await {
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

/// Initiates a WebRTC connection to a peer (offerer side).
async fn initiate_connection(
    my_device_id: &str,
    peer_id: &str,
    transports: &Arc<Mutex<HashMap<String, Arc<WebRtcTransport>>>>,
    signaling: &Arc<Mutex<SignalingClient>>,
    peer_manager: &Arc<PeerConnectionManager>,
) -> crate::util::result::Result<()> {
    let ice_servers = vec![RTCIceServer {
        urls: vec!["stun:stun.l.google.com:19302".to_string()],
        ..Default::default()
    }];

    // Create offer.
    let (transport, offer_sdp) = WebRtcTransport::create_offer(ice_servers).await?;
    let transport = Arc::new(transport);

    // Store transport for answer/ICE handling.
    transports.lock().await.insert(peer_id.to_string(), Arc::clone(&transport));

    // Send offer via signaling.
    {
        let sig = signaling.lock().await;
        sig.send_sdp_offer(peer_id, &offer_sdp).await?;
    }

    // Send ICE candidates.
    send_ice_candidates(&transport, peer_id, signaling).await;

    // Wait for data channel to open.
    let transport_clone = Arc::clone(&transport);
    let peer_id_owned = peer_id.to_string();
    let pm = Arc::clone(peer_manager);
    tokio::spawn(async move {
        transport_clone.wait_ready().await;
        tracing::info!("WebRTC data channel open with {peer_id_owned}");
        register_transport(&peer_id_owned, &transport_clone, &pm).await;
    });

    Ok(())
}

/// Accepts a WebRTC connection from a peer (answerer side).
async fn accept_connection(
    peer_id: &str,
    offer_sdp: &str,
    transports: &Arc<Mutex<HashMap<String, Arc<WebRtcTransport>>>>,
    signaling: &Arc<Mutex<SignalingClient>>,
    peer_manager: &Arc<PeerConnectionManager>,
) -> crate::util::result::Result<()> {
    let ice_servers = vec![RTCIceServer {
        urls: vec!["stun:stun.l.google.com:19302".to_string()],
        ..Default::default()
    }];

    // Create answer.
    let (transport, answer_sdp) = WebRtcTransport::create_answer(ice_servers, offer_sdp).await?;
    let transport = Arc::new(transport);

    // Store transport.
    transports.lock().await.insert(peer_id.to_string(), Arc::clone(&transport));

    // Send answer via signaling.
    {
        let sig = signaling.lock().await;
        sig.send_sdp_answer(peer_id, &answer_sdp).await?;
    }

    // Send ICE candidates.
    send_ice_candidates(&transport, peer_id, signaling).await;

    // Wait for data channel to open.
    let transport_clone = Arc::clone(&transport);
    let peer_id_owned = peer_id.to_string();
    let pm = Arc::clone(peer_manager);
    tokio::spawn(async move {
        transport_clone.wait_ready().await;
        tracing::info!("WebRTC data channel open with {peer_id_owned}");
        register_transport(&peer_id_owned, &transport_clone, &pm).await;
    });

    Ok(())
}

/// Sends gathered ICE candidates through the signaling channel.
async fn send_ice_candidates(
    transport: &WebRtcTransport,
    peer_id: &str,
    signaling: &Arc<Mutex<SignalingClient>>,
) {
    // Small delay for ICE gathering.
    tokio::time::sleep(std::time::Duration::from_millis(500)).await;

    let candidates = transport.pending_ice_candidates().await;
    let sig = signaling.lock().await;
    for candidate in candidates {
        if let Err(e) = sig.send_ice_candidate(peer_id, &candidate).await {
            tracing::warn!("Failed to send ICE candidate to {peer_id}: {e}");
        }
    }
}

/// Registers a WebRTC transport's data channel with the PeerConnectionManager.
async fn register_transport(
    peer_id: &str,
    transport: &Arc<WebRtcTransport>,
    peer_manager: &Arc<PeerConnectionManager>,
) {
    // Create mpsc channels that bridge between WebRtcTransport and PeerConnectionManager.
    let (tx, mut bridge_rx) = mpsc::channel::<Vec<u8>>(256);
    let (bridge_tx, rx) = mpsc::channel::<Vec<u8>>(256);

    // Register with peer manager.
    peer_manager.register_peer(peer_id, tx, rx).await;

    // Bridge: forward from peer_manager's tx → webrtc send.
    let transport_send = Arc::clone(transport);
    let peer_id_send = peer_id.to_string();
    tokio::spawn(async move {
        while let Some(data) = bridge_rx.recv().await {
            if let Err(e) = transport_send.send(&data).await {
                tracing::warn!("WebRTC send to {peer_id_send} failed: {e}");
                break;
            }
        }
    });

    // Bridge: forward from webrtc recv → peer_manager's rx.
    let transport_recv = Arc::clone(transport);
    let peer_id_recv = peer_id.to_string();
    tokio::spawn(async move {
        while let Some(data) = transport_recv.recv().await {
            if bridge_tx.send(data).await.is_err() {
                tracing::warn!("Bridge channel closed for {peer_id_recv}");
                break;
            }
        }
    });
}
