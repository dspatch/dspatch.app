// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Background sync loop that flushes the outbox to connected peers and
//! processes incoming changes.

use std::sync::Arc;
use std::time::Duration;

use futures::StreamExt;
use tokio_util::sync::CancellationToken;

use super::materializer::ChangeMaterializer;
use super::message::{SyncMessage, SyncOp};
use super::sync_engine::SyncEngine;

/// Default interval between outbox flushes.
const FLUSH_INTERVAL: Duration = Duration::from_secs(1);

/// Starts the background sync loop.
///
/// Returns a `CancellationToken` that can be used to stop the loop.
///
/// The loop performs two concurrent tasks:
/// 1. **Outbox flush** — every `FLUSH_INTERVAL`, syncs pending changes to
///    all connected peers.
/// 2. **Incoming handler** — processes `SyncMessage`s received from peers,
///    applying remote changes and sending acknowledgements.
pub fn start_sync_loop(
    engine: Arc<SyncEngine>,
    cancel: CancellationToken,
) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        let flush_engine = Arc::clone(&engine);
        let incoming_engine = Arc::clone(&engine);
        let cancel_flush = cancel.clone();
        let cancel_incoming = cancel.clone();

        // Spawn outbox flush task.
        let flush_handle = tokio::spawn(async move {
            let mut interval = tokio::time::interval(FLUSH_INTERVAL);
            loop {
                tokio::select! {
                    _ = cancel_flush.cancelled() => break,
                    _ = interval.tick() => {
                        if let Err(e) = flush_outbox(&flush_engine).await {
                            tracing::warn!("Sync outbox flush failed: {e}");
                        }
                    }
                }
            }
        });

        // Spawn incoming message handler task.
        let incoming_handle = tokio::spawn(async move {
            let mut stream = incoming_engine.peer_manager().incoming_messages();
            loop {
                tokio::select! {
                    _ = cancel_incoming.cancelled() => break,
                    item = stream.next() => {
                        match item {
                            Some((device_id, message)) => {
                                handle_incoming(&incoming_engine, &device_id, message).await;
                            }
                            None => break, // Stream closed.
                        }
                    }
                }
            }
        });

        // Wait for both tasks to complete (or cancellation).
        let _ = tokio::join!(flush_handle, incoming_handle);
    })
}

/// Flushes the outbox to all connected peers.
async fn flush_outbox(engine: &SyncEngine) -> crate::util::result::Result<()> {
    let peers = engine.peer_manager().connected_devices().await;
    for peer_id in &peers {
        match engine.sync_to_peer(peer_id).await {
            Ok(count) if count > 0 => {
                tracing::info!("Synced {count} changes to {peer_id}");
            }
            Ok(_) => {} // Nothing to sync.
            Err(e) => {
                // Log at debug level to avoid spam — the 1-second flush retries automatically.
                tracing::debug!("Sync flush to {peer_id} failed: {e}");
            }
        }
    }
    Ok(())
}

/// Handles an incoming sync message from a peer.
async fn handle_incoming(engine: &SyncEngine, from_device: &str, message: SyncMessage) {
    match message {
        SyncMessage::Changes(changes) => {
            let last_id = changes.last().map(|c| c.id.clone());
            match engine.apply_remote_changes(changes) {
                Ok(applied) => {
                    tracing::info!("Applied {applied} remote changes from {from_device}");
                    // Send acknowledgement.
                    if let Some(id) = last_id {
                        let ack = SyncMessage::Ack { last_id: id };
                        if let Err(e) = engine
                            .peer_manager()
                            .send_raw(
                                from_device,
                                serde_json::to_vec(&ack).unwrap_or_default(),
                            )
                            .await
                        {
                            tracing::warn!("Failed to send ack to {from_device}: {e}");
                        }
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to apply changes from {from_device}: {e}");
                }
            }
        }
        SyncMessage::Ack { last_id } => {
            if let Err(e) = engine.acknowledge_up_to(&last_id) {
                tracing::warn!("Failed to acknowledge from {from_device}: {e}");
            }
        }
        SyncMessage::CursorExchange(cursors) => {
            // Peer sent their cursors. Send back our changes since their cursors.
            for (table, since_lamport) in &cursors {
                match engine.get_outbox_since(table, *since_lamport) {
                    Ok(changes) if !changes.is_empty() => {
                        let msg = SyncMessage::Changes(changes);
                        if let Err(e) = engine
                            .peer_manager()
                            .send_raw(
                                from_device,
                                serde_json::to_vec(&msg).unwrap_or_default(),
                            )
                            .await
                        {
                            tracing::warn!("Failed to send changes to {from_device}: {e}");
                        }
                    }
                    Ok(_) => {}
                    Err(e) => {
                        tracing::warn!(
                            "Failed to get outbox for {table} since {since_lamport}: {e}"
                        );
                    }
                }
            }
        }
        SyncMessage::RequestChanges {
            table,
            since_lamport,
        } => match engine.get_outbox_since(&table, since_lamport) {
            Ok(changes) if !changes.is_empty() => {
                let msg = SyncMessage::Changes(changes);
                if let Err(e) = engine
                    .peer_manager()
                    .send_raw(
                        from_device,
                        serde_json::to_vec(&msg).unwrap_or_default(),
                    )
                    .await
                {
                    tracing::warn!("Failed to send requested changes to {from_device}: {e}");
                }
            }
            Ok(_) => {}
            Err(e) => {
                tracing::warn!("Failed to get outbox for request from {from_device}: {e}");
            }
        },
        SyncMessage::DeltaRequest { max_lamport_seen } => {
            tracing::info!("Peer {from_device} requested delta (cursor={max_lamport_seen})");
            match engine.generate_delta(max_lamport_seen) {
                Ok(tables) => {
                    let total_rows: usize = tables.iter().map(|(_, rows)| rows.len()).sum();
                    tracing::info!("Sending delta: {total_rows} rows across {} tables to {from_device}", tables.len());
                    // Send in chunks of 50 rows to avoid overwhelming the WebRTC data channel.
                    for (table, rows) in tables {
                        for chunk in rows.chunks(50) {
                            let msg = SyncMessage::DeltaResponse {
                                table: table.clone(),
                                rows: chunk.to_vec(),
                            };
                            if let Err(e) = engine
                                .peer_manager()
                                .send_raw(
                                    from_device,
                                    serde_json::to_vec(&msg).unwrap_or_default(),
                                )
                                .await
                            {
                                tracing::warn!("Failed to send delta chunk to {from_device}: {e}");
                                break;
                            }
                            // Small yield to let the data channel flush.
                            tokio::task::yield_now().await;
                        }
                    }
                    // Also send tombstones.
                    match engine.get_tombstones() {
                        Ok(tombstones) if !tombstones.is_empty() => {
                            tracing::info!("Sending {} tombstones to {from_device}", tombstones.len());
                            let msg = SyncMessage::Changes(tombstones);
                            let _ = engine
                                .peer_manager()
                                .send_raw(from_device, serde_json::to_vec(&msg).unwrap_or_default())
                                .await;
                        }
                        _ => {}
                    }
                }
                Err(e) => tracing::warn!("Failed to generate delta for {from_device}: {e}"),
            }
        }
        SyncMessage::DeltaResponse { table, rows } => {
            tracing::info!("Received delta: {} rows for table {table} from {from_device}", rows.len());
            for row in &rows {
                // Find the primary key value.
                let row_id = row.get("id")
                    .or_else(|| row.get("key")) // preferences uses "key" as PK
                    .and_then(|v| v.as_str())
                    .unwrap_or_default();
                let change = super::message::SyncChange {
                    id: crate::util::new_id(),
                    table: table.clone(),
                    row_id: row_id.to_string(),
                    operation: SyncOp::Upsert,
                    data: row.clone(),
                    lamport_ts: row.get("_lamport_ts").and_then(|v| v.as_i64()).unwrap_or(0),
                    device_id: from_device.to_string(),
                };
                if let Err(e) = ChangeMaterializer::apply(&engine.db().conn(), &change) {
                    tracing::warn!("Failed to apply delta row {table}.{row_id}: {e}");
                }
            }
        }
        SyncMessage::Command(_) | SyncMessage::CommandResult(_) => {
            // Command routing is handled separately by the command dispatcher.
            // These variants are included here for exhaustive matching.
            tracing::debug!("Received command/result from {from_device} — routing TBD");
        }
        SyncMessage::RequestFullState => {
            tracing::info!("Peer {from_device} requested full state snapshot");
            // Send all rows from synced tables.
            match engine.generate_full_state(500) {
                Ok(chunks) => {
                    let total_rows: usize = chunks.iter().map(|(_, rows, _, _)| rows.len()).sum();
                    tracing::info!("Sending {total_rows} rows in {} chunks to {from_device}", chunks.len());
                    for (table, rows, chunk_index, total_chunks) in chunks {
                        let msg = SyncMessage::FullState {
                            table,
                            rows,
                            chunk_index,
                            total_chunks,
                        };
                        if let Err(e) = engine
                            .peer_manager()
                            .send_raw(
                                from_device,
                                serde_json::to_vec(&msg).unwrap_or_default(),
                            )
                            .await
                        {
                            tracing::warn!(
                                "Failed to send snapshot chunk to {from_device}: {e}"
                            );
                            break;
                        }
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to generate snapshot for {from_device}: {e}");
                }
            }
            // Also send tombstones so the peer knows about deletions.
            match engine.get_tombstones() {
                Ok(tombstones) if !tombstones.is_empty() => {
                    tracing::info!("Sending {} tombstones to {from_device}", tombstones.len());
                    let msg = SyncMessage::Changes(tombstones);
                    if let Err(e) = engine
                        .peer_manager()
                        .send_raw(
                            from_device,
                            serde_json::to_vec(&msg).unwrap_or_default(),
                        )
                        .await
                    {
                        tracing::warn!("Failed to send tombstones to {from_device}: {e}");
                    }
                }
                Ok(_) => {} // No tombstones.
                Err(e) => tracing::warn!("Failed to read tombstones: {e}"),
            }
        }
        SyncMessage::FullState {
            table,
            rows,
            chunk_index,
            total_chunks,
        } => {
            tracing::info!(
                "Received snapshot chunk {}/{} for table {table} from {from_device}",
                chunk_index + 1,
                total_chunks
            );
            // Apply all rows via materializer in "accept all" mode.
            for row in &rows {
                let row_id = row["id"].as_str().unwrap_or_default();
                let change = super::message::SyncChange {
                    id: crate::util::new_id(),
                    table: table.clone(),
                    row_id: row_id.to_string(),
                    operation: super::message::SyncOp::Upsert,
                    data: row.clone(),
                    lamport_ts: 0, // Snapshot — accept unconditionally
                    device_id: from_device.to_string(),
                };
                if let Err(e) =
                    super::materializer::ChangeMaterializer::apply(&engine.db().conn(), &change)
                {
                    tracing::warn!("Failed to apply snapshot row {table}.{row_id}: {e}");
                }
            }
        }
    }
}
