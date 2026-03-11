// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Peer connection manager for encrypted P2P data transfer.
//!
//! Uses TCP streams with Signal Protocol E2E encryption as the transport layer.
//! Each peer connection is a bidirectional encrypted channel identified by the
//! remote device ID. The `PeerConnectionManager` handles connection lifecycle,
//! message routing, and encryption/decryption via the `SignalManager`.

use std::collections::HashMap;
use std::sync::Arc;

use futures::Stream;
use tokio::sync::{mpsc, Mutex};

use crate::signal::SignalManager;
use crate::util::error::AppError;
use crate::util::result::Result;

use super::message::SyncMessage;

/// Capacity of internal message channels per peer.
const CHANNEL_CAPACITY: usize = 256;

/// A single peer connection with bidirectional message passing.
pub struct PeerConnection {
    /// The remote device's identifier.
    pub device_id: String,
    /// Send side of the channel (to the peer).
    tx: mpsc::Sender<Vec<u8>>,
    /// Receive side of the channel (from the peer).
    rx: Arc<Mutex<mpsc::Receiver<Vec<u8>>>>,
}

/// Manages connections to multiple peer devices.
///
/// All messages are encrypted using the `SignalManager` before transmission
/// and decrypted on receipt. The transport is abstracted — currently uses
/// in-process channels for testing and TCP for production.
pub struct PeerConnectionManager {
    signal_manager: Arc<Mutex<SignalManager>>,
    connections: Arc<Mutex<HashMap<String, PeerConnection>>>,
    /// Broadcast channel for incoming messages from all peers.
    incoming_tx: mpsc::Sender<(String, SyncMessage)>,
    incoming_rx: Arc<Mutex<mpsc::Receiver<(String, SyncMessage)>>>,
}

impl PeerConnectionManager {
    /// Creates a new peer connection manager with Signal Protocol encryption.
    pub fn new(signal_manager: Arc<Mutex<SignalManager>>) -> Self {
        let (incoming_tx, incoming_rx) = mpsc::channel(CHANNEL_CAPACITY);
        Self {
            signal_manager,
            connections: Arc::new(Mutex::new(HashMap::new())),
            incoming_tx,
            incoming_rx: Arc::new(Mutex::new(incoming_rx)),
        }
    }

    /// Registers a peer connection using pre-built channels.
    ///
    /// This is the low-level method used by both `connect()` (for outbound
    /// connections) and the signaling handler (for inbound connections).
    /// In tests, this is used to wire up two managers directly.
    pub async fn register_peer(
        &self,
        device_id: &str,
        tx: mpsc::Sender<Vec<u8>>,
        rx: mpsc::Receiver<Vec<u8>>,
    ) {
        let peer = PeerConnection {
            device_id: device_id.to_string(),
            tx,
            rx: Arc::new(Mutex::new(rx)),
        };
        self.connections
            .lock()
            .await
            .insert(device_id.to_string(), peer);
    }

    /// Initiates a connection to a peer device.
    ///
    /// In the current implementation this creates in-memory channels. In
    /// production this would establish a TCP/TLS connection via the signaling
    /// server relay or a direct WebRTC data channel.
    pub async fn connect(&self, target_device_id: &str) -> Result<()> {
        let conns = self.connections.lock().await;
        if conns.contains_key(target_device_id) {
            return Ok(()); // Already connected.
        }
        drop(conns);

        // In production, this would:
        // 1. Send SDP offer via SignalingClient
        // 2. Wait for SDP answer
        // 3. Exchange ICE candidates
        // 4. Establish WebRTC data channel or TCP/TLS connection
        //
        // For now, connections are established externally via register_peer().
        Err(AppError::Server(format!(
            "Direct connect not yet implemented — use register_peer() or signaling flow for {target_device_id}"
        )))
    }

    /// Sends an encrypted `SyncMessage` to a connected peer.
    pub async fn send(&self, device_id: &str, message: &SyncMessage) -> Result<()> {
        let conns = self.connections.lock().await;
        let peer = conns.get(device_id).ok_or_else(|| {
            AppError::Server(format!("Not connected to peer {device_id}"))
        })?;

        // Serialize the message.
        let plaintext = serde_json::to_vec(message)
            .map_err(|e| AppError::Internal(format!("Failed to serialize SyncMessage: {e}")))?;

        // Encrypt with Signal Protocol.
        let encrypted = {
            let signal = self.signal_manager.lock().await;
            signal.encrypt(device_id, 1, &plaintext)?
        };

        peer.tx
            .send(encrypted)
            .await
            .map_err(|_| AppError::Server(format!("Peer channel closed for {device_id}")))?;

        Ok(())
    }

    /// Sends a raw (already-encrypted or plaintext-for-testing) message to a peer.
    ///
    /// Used in tests to bypass Signal encryption.
    pub async fn send_raw(&self, device_id: &str, data: Vec<u8>) -> Result<()> {
        let conns = self.connections.lock().await;
        let peer = conns.get(device_id).ok_or_else(|| {
            AppError::Server(format!("Not connected to peer {device_id}"))
        })?;

        peer.tx
            .send(data)
            .await
            .map_err(|_| AppError::Server(format!("Peer channel closed for {device_id}")))?;

        Ok(())
    }

    /// Receives the next raw message from a specific peer.
    ///
    /// Returns `None` if the peer channel is closed.
    pub async fn recv_raw(&self, device_id: &str) -> Result<Option<Vec<u8>>> {
        let conns = self.connections.lock().await;
        let peer = conns.get(device_id).ok_or_else(|| {
            AppError::Server(format!("Not connected to peer {device_id}"))
        })?;
        let rx = Arc::clone(&peer.rx);
        drop(conns);

        let mut rx = rx.lock().await;
        Ok(rx.recv().await)
    }

    /// Returns a stream of incoming messages from all connected peers.
    ///
    /// Each item is `(device_id, SyncMessage)`. Messages are decrypted
    /// using the Signal Protocol before being yielded.
    pub fn incoming_messages(
        &self,
    ) -> Pin<Box<dyn Stream<Item = (String, SyncMessage)> + Send>>
    where
        Self: 'static,
    {
        let rx = Arc::clone(&self.incoming_rx);
        let stream = async_stream::stream! {
            let mut rx = rx.lock().await;
            while let Some(item) = rx.recv().await {
                yield item;
            }
        };
        Box::pin(stream)
    }

    /// Dispatches a received encrypted message from a peer into the incoming
    /// messages stream. Decrypts the message before forwarding.
    pub async fn dispatch_incoming(
        &self,
        from_device: &str,
        encrypted: &[u8],
    ) -> Result<()> {
        let plaintext = {
            let signal = self.signal_manager.lock().await;
            signal.decrypt(from_device, 1, encrypted)?
        };

        let message: SyncMessage = serde_json::from_slice(&plaintext)
            .map_err(|e| AppError::Internal(format!("Failed to deserialize SyncMessage: {e}")))?;

        self.incoming_tx
            .send((from_device.to_string(), message))
            .await
            .map_err(|_| AppError::Internal("Incoming message channel closed".into()))?;

        Ok(())
    }

    /// Dispatches a plaintext (unencrypted) message into the incoming stream.
    ///
    /// Used in tests to bypass Signal encryption.
    pub async fn dispatch_incoming_plaintext(
        &self,
        from_device: &str,
        message: SyncMessage,
    ) -> Result<()> {
        self.incoming_tx
            .send((from_device.to_string(), message))
            .await
            .map_err(|_| AppError::Internal("Incoming message channel closed".into()))?;
        Ok(())
    }

    /// Disconnects from a specific peer.
    pub async fn disconnect(&self, device_id: &str) {
        self.connections.lock().await.remove(device_id);
    }

    /// Disconnects from all peers.
    pub async fn disconnect_all(&self) {
        self.connections.lock().await.clear();
    }

    /// Returns the list of currently connected device IDs.
    pub async fn connected_devices(&self) -> Vec<String> {
        self.connections
            .lock()
            .await
            .keys()
            .cloned()
            .collect()
    }
}

use std::pin::Pin;
