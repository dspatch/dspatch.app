// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Broadcast channel for ephemeral engine lifecycle events.
//!
//! Ephemeral events are engine-local state that does NOT need to be persisted
//! or synced across devices. Examples: `engine_shutting_down`, `p2p_connected`,
//! `p2p_disconnected`.
//!
//! WebSocket handlers subscribe to this emitter and forward events to clients
//! as `ServerFrame::Event` frames.

use tokio::sync::broadcast;

/// An ephemeral event payload.
#[derive(Debug, Clone)]
pub struct EphemeralEvent {
    /// Event name (e.g., `engine_shutting_down`, `p2p_connected`).
    pub name: String,
    /// Event data (arbitrary JSON).
    pub data: serde_json::Value,
}

/// Capacity of the broadcast channel. Ephemeral events are low-frequency,
/// so 32 is plenty.
const CHANNEL_CAPACITY: usize = 32;

/// Broadcast emitter for ephemeral engine lifecycle events.
///
/// Created once per engine, stored in `EngineRuntime`. Any subsystem can call
/// [`emit`](Self::emit) to broadcast an event. WebSocket handlers call
/// [`subscribe`](Self::subscribe) to receive events.
pub struct EphemeralEventEmitter {
    tx: broadcast::Sender<EphemeralEvent>,
}

impl EphemeralEventEmitter {
    /// Creates a new emitter with no subscribers.
    pub fn new() -> Self {
        let (tx, _) = broadcast::channel(CHANNEL_CAPACITY);
        Self { tx }
    }

    /// Emits an event to all current subscribers. Silent if nobody is listening.
    pub fn emit(&self, name: &str, data: serde_json::Value) {
        let _ = self.tx.send(EphemeralEvent {
            name: name.to_string(),
            data,
        });
    }

    /// Creates a new subscription receiver.
    pub fn subscribe(&self) -> broadcast::Receiver<EphemeralEvent> {
        self.tx.subscribe()
    }

    /// Returns a clone of this emitter (shares the underlying broadcast channel).
    pub fn clone_sender(&self) -> Self {
        Self { tx: self.tx.clone() }
    }
}

impl Default for EphemeralEventEmitter {
    fn default() -> Self {
        Self::new()
    }
}
