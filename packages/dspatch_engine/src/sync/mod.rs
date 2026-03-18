// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! P2P sync engine for device-to-device data synchronization.
//!
//! Architecture:
//! - [`message`] — Sync message types (`SyncChange`, `SyncMessage`, `SyncOp`).
//! - [`signaling`] — WebSocket signaling client for connection establishment.
//! - [`peer_connection`] — Encrypted peer connection manager using Signal Protocol.
//! - [`sync_engine`] — Orchestration layer: outbox, cursors, Lamport clock,
//!   conflict resolution (last-writer-wins).
//!
//! The sync engine records local mutations into a `sync_outbox` table and
//! exchanges them with connected peers over encrypted channels. Lamport
//! timestamps provide causal ordering; conflicts are resolved by
//! last-writer-wins with device-ID tiebreaking.

pub mod materializer;
pub mod message;
pub mod outbox_hook;
pub mod peer_connection;
pub mod signaling;
pub mod sync_engine;
pub mod sync_loop;
pub mod table_class;
pub mod ws_client;

pub use message::{CommandResult, RemoteCommand, SyncChange, SyncMessage, SyncOp};
pub use peer_connection::PeerConnectionManager;
pub use signaling::SignalingClient;
pub use sync_engine::SyncEngine;
pub use sync_loop::start_sync_loop;
