// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Connection supervisor — monitors WebRTC peer health and triggers reconnection.
//!
//! Periodically pings each connected peer and declares dead peers when no
//! response is received within a timeout. Dead peers are disconnected and,
//! if still reported as online by the backend, a reconnection is attempted
//! with exponential backoff.

use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};

use tokio_util::sync::CancellationToken;

use super::backend_client::BackendWsClient;
use super::message::SyncMessage;
use super::peer_connection::PeerConnectionManager;
use super::signaling::SignalingEvent;
use crate::util::panic_guard::spawn_guarded;

/// Interval between health check rounds.
const HEALTH_CHECK_INTERVAL: Duration = Duration::from_secs(15);

/// A peer is declared dead if no message (including pong) has been received
/// within this duration.
const DEAD_PEER_THRESHOLD: Duration = Duration::from_secs(30);

/// Initial reconnection delay after a dead peer is detected.
const INITIAL_RECONNECT_BACKOFF: Duration = Duration::from_secs(5);

/// Maximum reconnection delay.
const MAX_RECONNECT_BACKOFF: Duration = Duration::from_secs(60);

/// Per-peer health state tracked by the supervisor.
struct PeerHealth {
    /// Exponential backoff for reconnection attempts.
    reconnect_backoff: Duration,
    /// When the last reconnect was attempted (if any).
    last_reconnect_attempt: Option<Instant>,
}

/// Spawns the connection supervisor as a background task.
///
/// The supervisor:
/// 1. Pings each connected peer every `HEALTH_CHECK_INTERVAL`.
/// 2. Checks `last_activity` from `PeerConnectionManager` to detect dead peers.
/// 3. Disconnects dead peers and requests reconnection via the signaling channel.
pub fn spawn_connection_supervisor(
    peer_manager: Arc<PeerConnectionManager>,
    ws_client: Arc<BackendWsClient>,
    signaling_tx: tokio::sync::mpsc::Sender<SignalingEvent>,
    cancel: CancellationToken,
) -> tokio::task::JoinHandle<()> {
    spawn_guarded("connection_supervisor", async move {
        let mut health: HashMap<String, PeerHealth> = HashMap::new();
        let mut interval = tokio::time::interval(HEALTH_CHECK_INTERVAL);

        loop {
            tokio::select! {
                _ = cancel.cancelled() => break,
                _ = interval.tick() => {
                    let connected = peer_manager.connected_devices().await;
                    let activity = peer_manager.last_activity().await;

                    // Send ping to each connected peer.
                    for peer_id in &connected {
                        let ping = SyncMessage::Ping;
                        if let Err(e) = peer_manager
                            .send_raw(peer_id, serde_json::to_vec(&ping).unwrap_or_default())
                            .await
                        {
                            tracing::debug!("Failed to ping {peer_id}: {e}");
                        }
                    }

                    // Check for dead peers.
                    let now = Instant::now();
                    for peer_id in &connected {
                        let is_dead = match activity.get(peer_id) {
                            Some(last) => now.duration_since(*last) > DEAD_PEER_THRESHOLD,
                            // No activity recorded yet — peer just connected, give it time.
                            None => false,
                        };

                        if !is_dead {
                            // Peer is alive — reset backoff.
                            if let Some(ph) = health.get_mut(peer_id) {
                                ph.reconnect_backoff = INITIAL_RECONNECT_BACKOFF;
                                ph.last_reconnect_attempt = None;
                            }
                            continue;
                        }

                        tracing::warn!("Peer {peer_id} is dead (no activity for >{DEAD_PEER_THRESHOLD:?})");
                        peer_manager.disconnect(peer_id).await;

                        // Attempt reconnection if peer is still online according to backend.
                        let online_peers = ws_client.online_peers().await;
                        if online_peers.contains(peer_id) {
                            let ph = health.entry(peer_id.clone()).or_insert(PeerHealth {
                                reconnect_backoff: INITIAL_RECONNECT_BACKOFF,
                                last_reconnect_attempt: None,
                            });

                            // Respect backoff.
                            let should_reconnect = match ph.last_reconnect_attempt {
                                Some(last) => now.duration_since(last) >= ph.reconnect_backoff,
                                None => true,
                            };

                            if should_reconnect {
                                tracing::info!(
                                    "Requesting reconnection to {peer_id} (backoff={:?})",
                                    ph.reconnect_backoff
                                );
                                ph.last_reconnect_attempt = Some(now);
                                ph.reconnect_backoff =
                                    (ph.reconnect_backoff * 2).min(MAX_RECONNECT_BACKOFF);

                                // Trigger the P2P connector's reconnection flow by emitting
                                // a DeviceOnline event on the signaling channel.
                                let _ = signaling_tx
                                    .send(SignalingEvent::DeviceOnline {
                                        device_id: peer_id.clone(),
                                    })
                                    .await;
                            }
                        }
                    }

                    // Clean up health entries for peers we're no longer tracking.
                    health.retain(|id, _| connected.contains(id));
                }
            }
        }
    })
}
