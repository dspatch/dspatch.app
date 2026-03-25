//! WebSocket client for bidirectional communication with the host engine.
//!
//! Handles: connection, auth+register handshake, send/receive, reconnect with backoff.
//! Packages flow through the WAL before being sent.

use crate::config::RouterConfig;
use crate::wal::{Wal, WalDirection};
use crate::wire::WirePackage;
use anyhow::{Context, Result};
use futures::{SinkExt, StreamExt};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::mpsc;
use tokio_tungstenite::{connect_async, tungstenite::Message};

pub struct ExponentialBackoff {
    base: Duration,
    max: Duration,
    attempt: u32,
}

impl ExponentialBackoff {
    pub fn new(base: Duration, max: Duration) -> Self {
        Self { base, max, attempt: 0 }
    }

    pub fn next_delay(&mut self) -> Duration {
        let delay = self.base * 2u32.saturating_pow(self.attempt);
        self.attempt += 1;
        delay.min(self.max)
    }

    pub fn reset(&mut self) {
        self.attempt = 0;
    }
}

pub struct WsClient {
    config: Arc<RouterConfig>,
}

impl WsClient {
    pub fn new(config: Arc<RouterConfig>) -> Self {
        Self { config }
    }

    pub async fn run(
        &self,
        mut outbound_rx: mpsc::Receiver<WirePackage>,
        inbound_tx: mpsc::Sender<WirePackage>,
        wal: Arc<parking_lot::Mutex<Wal>>,
    ) {
        let mut backoff = ExponentialBackoff::new(Duration::from_secs(2), Duration::from_secs(30));

        loop {
            match self.connect_and_run(&mut outbound_rx, &inbound_tx, &wal).await {
                Ok(()) => {
                    tracing::info!("WebSocket connection closed cleanly");
                    backoff.reset();
                }
                Err(e) => {
                    tracing::warn!("WebSocket error: {}", e);
                }
            }

            let delay = backoff.next_delay();
            tracing::info!("Reconnecting in {:?}", delay);
            tokio::time::sleep(delay).await;
        }
    }

    async fn connect_and_run(
        &self,
        outbound_rx: &mut mpsc::Receiver<WirePackage>,
        inbound_tx: &mpsc::Sender<WirePackage>,
        wal: &Arc<parking_lot::Mutex<Wal>>,
    ) -> Result<()> {
        let url = self.config.ws_url();
        tracing::info!("Connecting to engine: {}", url);

        let (ws_stream, _) = connect_async(&url)
            .await
            .context("Failed to connect to engine")?;

        let (mut ws_tx, mut ws_rx) = ws_stream.split();

        // ── Auth handshake ──
        let auth = WirePackage::auth(&self.config.api_key);
        ws_tx.send(Message::Text(auth.to_string().into())).await?;

        match ws_rx.next().await {
            Some(Ok(Message::Text(text))) => {
                let json: serde_json::Value = serde_json::from_str(&text)?;
                let pkg = WirePackage::from_json(json)
                    .map_err(|e| anyhow::anyhow!(e))?;
                if pkg.package_type() != "connection.auth_ack" {
                    anyhow::bail!("Expected auth_ack, got {}", pkg.package_type());
                }
            }
            other => anyhow::bail!("Auth handshake failed: {:?}", other),
        }

        // ── Register ──
        let reg = WirePackage::register("router", "container_router");
        ws_tx.send(Message::Text(reg.to_string().into())).await?;

        tracing::info!("Connected and authenticated");

        // ── Replay WAL ──
        {
            let replay_msgs: Vec<String> = {
                let wal_guard = wal.lock();
                wal_guard
                    .unacked_entries(WalDirection::Outbound)
                    .into_iter()
                    .map(|e| e.data.to_string())
                    .collect()
            };
            let entry_count = replay_msgs.len();
            for msg in replay_msgs {
                ws_tx.send(Message::Text(msg.into())).await?;
            }
            if entry_count > 0 {
                tracing::info!("Replayed {} WAL entries", entry_count);
            }
        }

        // ── Main loop: multiplex send/receive ──
        loop {
            tokio::select! {
                Some(pkg) = outbound_rx.recv() => {
                    let _seq = wal.lock().append(WalDirection::Outbound, pkg.to_json())?;
                    ws_tx.send(Message::Text(pkg.to_string().into())).await?;
                }
                msg = ws_rx.next() => {
                    match msg {
                        Some(Ok(Message::Text(text))) => {
                            let json: serde_json::Value = serde_json::from_str(&text)?;

                            if json.get("type").and_then(|t| t.as_str()) == Some("connection.ack") {
                                if let Some(seq) = json.get("sequence_number").and_then(|s| s.as_u64()) {
                                    wal.lock().ack(WalDirection::Outbound, seq);
                                }
                                continue;
                            }

                            let pkg = WirePackage::from_json(json)
                                .map_err(|e| anyhow::anyhow!(e))?;
                            if inbound_tx.send(pkg).await.is_err() {
                                tracing::error!("Inbound channel closed");
                                return Ok(());
                            }
                        }
                        Some(Ok(Message::Ping(data))) => {
                            ws_tx.send(Message::Pong(data)).await?;
                        }
                        Some(Ok(Message::Close(_))) | None => {
                            return Ok(());
                        }
                        Some(Err(e)) => {
                            return Err(e.into());
                        }
                        _ => {}
                    }
                }
            }
        }
    }
}
