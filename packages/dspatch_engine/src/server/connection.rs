// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! WebSocket connection management for agent hosts.
//!
//! Ported from `server/connection_service.dart`.

use std::collections::HashMap;
use std::sync::{Arc, RwLock};

use axum::extract::ws::{Message, WebSocket};
use futures::{SinkExt, StreamExt};
use tokio::sync::Mutex;

use super::inspector::PackageInspectorService;
use super::packages::*;
use crate::util::panic_guard::spawn_guarded;

/// Type alias for the sender half of a split WebSocket.
pub type WsSender = Arc<Mutex<futures::stream::SplitSink<WebSocket, Message>>>;

// ── Callback types ──────────────────────────────────────────────────

pub type InstanceStateChangedFn = Arc<
    dyn Fn(String, String, String, Option<String>, String) + Send + Sync,
>;

pub type InstanceGoneFn = Arc<
    dyn Fn(String, String, String, String) + Send + Sync,
>;

pub type AgentConnectedFn = Arc<dyn Fn(String, String) + Send + Sync>;
pub type AgentDisconnectedFn = Arc<dyn Fn(String, String) + Send + Sync>;
pub type EventReceivedFn = Arc<dyn Fn(String, String, Package) + Send + Sync>;
pub type HeartbeatReceivedFn =
    Arc<dyn Fn(String, String, HashMap<String, String>) + Send + Sync>;

/// Manages WebSocket connections for agent hosts, keyed by run ID.
///
/// Owns the physical WebSocket lifecycle: auth handshake, heartbeat diffing,
/// connection tracking, and message routing.
pub struct ConnectionService {
    /// `run_id -> agent_name -> WsSender`
    ///
    /// Uses `std::sync::RwLock` so that sync read-only lookups (e.g.
    /// `is_connected`) don't require spawning OS threads.
    connections: RwLock<HashMap<String, HashMap<String, WsSender>>>,

    /// `(run_id, agent_name) -> { instance_id -> state }`
    ///
    /// Uses `std::sync::RwLock` for sync read access from callbacks.
    instance_states: RwLock<HashMap<(String, String), HashMap<String, String>>>,

    /// `(run_id, agent_name) -> registered name`
    registered_names: Mutex<HashMap<(String, String), String>>,

    /// `run_id -> api_key`
    api_keys: Mutex<HashMap<String, String>>,

    // ── Delegate callbacks ──
    pub on_agent_connected: Mutex<Option<AgentConnectedFn>>,
    pub on_agent_disconnected: Mutex<Option<AgentDisconnectedFn>>,
    pub on_instance_state_changed: Mutex<Option<InstanceStateChangedFn>>,
    pub on_instance_gone: Mutex<Option<InstanceGoneFn>>,
    pub on_event_received: Mutex<Option<EventReceivedFn>>,
    pub on_heartbeat_received: Mutex<Option<HeartbeatReceivedFn>>,

    /// Optional package inspector for dev-mode frame logging.
    pub inspector: Option<Arc<PackageInspectorService>>,
}

impl ConnectionService {
    pub fn new(inspector: Option<Arc<PackageInspectorService>>) -> Self {
        Self {
            connections: RwLock::new(HashMap::new()),
            instance_states: RwLock::new(HashMap::new()),
            registered_names: Mutex::new(HashMap::new()),
            api_keys: Mutex::new(HashMap::new()),
            on_agent_connected: Mutex::new(None),
            on_agent_disconnected: Mutex::new(None),
            on_instance_state_changed: Mutex::new(None),
            on_instance_gone: Mutex::new(None),
            on_event_received: Mutex::new(None),
            on_heartbeat_received: Mutex::new(None),
            inspector,
        }
    }

    // ── Heartbeat diffing ──

    /// Process a heartbeat, diffing instance states against previous.
    pub async fn process_heartbeat(
        &self,
        run_id: &str,
        agent_name: &str,
        instances: &HashMap<String, String>,
    ) {
        let key = (run_id.to_string(), agent_name.to_string());
        let previous = {
            let states = self.instance_states.read().unwrap_or_else(|e| e.into_inner());
            states.get(&key).cloned().unwrap_or_default()
        };

        // Detect new or changed instances.
        let on_changed = self.on_instance_state_changed.lock().await;
        for (instance_id, new_state) in instances {
            let old_state = previous.get(instance_id);
            if old_state.map(|s| s.as_str()) != Some(new_state.as_str()) {
                if let Some(ref cb) = *on_changed {
                    cb(
                        run_id.to_string(),
                        agent_name.to_string(),
                        instance_id.clone(),
                        old_state.cloned(),
                        new_state.clone(),
                    );
                }
            }
        }
        drop(on_changed);

        // Detect gone instances.
        let on_gone = self.on_instance_gone.lock().await;
        for (instance_id, last_state) in &previous {
            if !instances.contains_key(instance_id) {
                if let Some(ref cb) = *on_gone {
                    cb(
                        run_id.to_string(),
                        agent_name.to_string(),
                        instance_id.clone(),
                        last_state.clone(),
                    );
                }
            }
        }
        drop(on_gone);

        self.instance_states.write().unwrap_or_else(|e| e.into_inner()).insert(key, instances.clone());
    }

    /// Process a proactive state report from a single instance.
    pub async fn process_state_report(
        &self,
        run_id: &str,
        agent_name: &str,
        instance_id: &str,
        new_state: &str,
    ) {
        let key = (run_id.to_string(), agent_name.to_string());
        let old_state = {
            let mut states = self.instance_states.write().unwrap_or_else(|e| e.into_inner());
            let instance_map = states.entry(key).or_default();
            let old_state = instance_map.get(instance_id).cloned();
            if old_state.as_deref() == Some(new_state) {
                return;
            }
            instance_map.insert(instance_id.to_string(), new_state.to_string());
            old_state
        };

        let on_changed = self.on_instance_state_changed.lock().await;
        if let Some(ref cb) = *on_changed {
            cb(
                run_id.to_string(),
                agent_name.to_string(),
                instance_id.to_string(),
                old_state,
                new_state.to_string(),
            );
        }
    }

    // ── Run registration ──

    pub async fn register_run(&self, run_id: &str, api_key: &str) {
        self.api_keys
            .lock()
            .await
            .insert(run_id.to_string(), api_key.to_string());
        tracing::info!(run_id, "Run registered");
    }

    pub async fn deregister_run(&self, run_id: &str) {
        self.api_keys.lock().await.remove(run_id);

        // Close all agent connections for this run.
        let agents = self.connections.write().unwrap_or_else(|e| e.into_inner()).remove(run_id);
        if let Some(agents) = agents {
            for (_, sender) in agents {
                let mut sink = sender.lock().await;
                let _ = sink
                    .send(Message::Close(Some(axum::extract::ws::CloseFrame {
                        code: 4001,
                        reason: "Run shutting down".into(),
                    })))
                    .await;
            }
        }

        // Clear instance states and registered names for this run.
        self.instance_states
            .write()
            .unwrap_or_else(|e| e.into_inner())
            .retain(|k, _| k.0 != run_id);
        self.registered_names
            .lock()
            .await
            .retain(|k, _| k.0 != run_id);

        tracing::info!(run_id, "Run deregistered");
    }

    // ── WebSocket handler ──

    /// Handle a new WebSocket connection for the given run/agent.
    pub async fn handle_agent(
        self: &Arc<Self>,
        ws: WebSocket,
        run_id: String,
        agent_name: String,
    ) {
        let (ws_sink, mut ws_stream) = ws.split();
        let sender = Arc::new(Mutex::new(ws_sink));
        let service = Arc::clone(self);

        let mut authenticated = false;
        let mut registered = false;
        let r_id = run_id.clone();
        let a_name = agent_name.clone();

        // Bounded inbound channel — provides backpressure: if the processing loop
        // falls behind, incoming messages are dropped with a warning rather than
        // buffering unboundedly in memory.
        let (inbound_tx, mut inbound_rx) = tokio::sync::mpsc::channel::<String>(256);

        // Spawn a task that reads from the WebSocket and forwards into the channel.
        let r_id_reader = r_id.clone();
        let a_name_reader = a_name.clone();
        let reader_handle = crate::util::panic_guard::spawn_guarded("connection_ws_reader", async move {
            loop {
                match ws_stream.next().await {
                    Some(Ok(Message::Text(t))) => {
                        let s = t.to_string();
                        match inbound_tx.try_send(s) {
                            Ok(_) => {}
                            Err(tokio::sync::mpsc::error::TrySendError::Full(_)) => {
                                tracing::warn!(
                                    run_id = r_id_reader.as_str(),
                                    agent_name = a_name_reader.as_str(),
                                    "Inbound channel full — dropping message (backpressure)"
                                );
                            }
                            Err(tokio::sync::mpsc::error::TrySendError::Closed(_)) => {
                                break;
                            }
                        }
                    }
                    Some(Ok(Message::Pong(_))) => {} // ignore pong frames
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(_)) => {} // ignore binary/other
                    Some(Err(e)) => {
                        tracing::warn!(
                            run_id = r_id_reader.as_str(),
                            agent_name = a_name_reader.as_str(),
                            error = %e,
                            "WebSocket error"
                        );
                        break;
                    }
                }
            }
            // Drop the channel sender to signal EOF to the processing loop.
            drop(inbound_tx);
        });

        // Auth timeout: 10 seconds
        let auth_sender = Arc::clone(&sender);
        let auth_service = Arc::clone(&service);
        let auth_run_id = run_id.clone();
        let auth_agent_name = agent_name.clone();
        let auth_handle = spawn_guarded("connection_auth_timeout", async move {
            tokio::time::sleep(std::time::Duration::from_secs(10)).await;
            // If this task completes, the auth timed out.
            tracing::warn!(
                run_id = auth_run_id.as_str(),
                agent_name = auth_agent_name.as_str(),
                "Auth timeout"
            );
            let error_pkg = Package::AuthError(AuthErrorPackage {
                message: "Auth timeout".to_string(),
            });
            if let Ok(json) = error_pkg.to_json() {
                if let Some(ref inspector) = auth_service.inspector {
                    inspector.log_outbound_str(&auth_run_id, &json);
                }
                let mut sink = auth_sender.lock().await;
                let _ = sink.send(Message::Text(json.into())).await;
                let _ = sink
                    .send(Message::Close(Some(axum::extract::ws::CloseFrame {
                        code: 4001,
                        reason: "Auth timeout".into(),
                    })))
                    .await;
            }
        });

        while let Some(raw) = inbound_rx.recv().await {
            // Try parse as JSON.
            let parsed = match Package::from_json(&raw) {
                Ok(p) => p,
                Err(_) => {
                    tracing::warn!("WebSocket JSON parse error");
                    continue;
                }
            };

            if let Some(ref inspector) = service.inspector {
                inspector.log_inbound(&r_id, &raw);
            }

            if !authenticated {
                auth_handle.abort();

                match parsed {
                    Package::Auth(ref auth_pkg) => {
                        let api_keys = service.api_keys.lock().await;
                        let expected = api_keys.get(&r_id);
                        if expected.map(|k| k.as_str()) != Some(&auth_pkg.api_key) {
                            tracing::warn!(
                                run_id = r_id.as_str(),
                                agent_name = a_name.as_str(),
                                "Auth failed"
                            );
                            let error_pkg = Package::AuthError(AuthErrorPackage {
                                message: "Invalid credentials".to_string(),
                            });
                            if let Ok(json) = error_pkg.to_json() {
                                if let Some(ref inspector) = service.inspector {
                                    inspector.log_outbound_str(&r_id, &json);
                                }
                                let mut sink = sender.lock().await;
                                let _ = sink.send(Message::Text(json.into())).await;
                                let _ = sink
                                    .send(Message::Close(Some(
                                        axum::extract::ws::CloseFrame {
                                            code: 4001,
                                            reason: "Invalid credentials".into(),
                                        },
                                    )))
                                    .await;
                            }
                            break;
                        }
                        drop(api_keys);

                        // Auth successful.
                        authenticated = true;
                        service
                            .register_connection(&r_id, &a_name, Arc::clone(&sender))
                            .await;

                        let ack_pkg = Package::AuthAck(AuthAckPackage {});
                        if let Ok(json) = ack_pkg.to_json() {
                            if let Some(ref inspector) = service.inspector {
                                inspector.log_outbound_str(&r_id, &json);
                            }
                            let mut sink = sender.lock().await;
                            if sink.send(Message::Text(json.into())).await.is_err() {
                                tracing::warn!("Failed to send auth_ack");
                                service.remove_connection(&r_id, &a_name);
                                break;
                            }
                        }

                        tracing::info!(
                            run_id = r_id.as_str(),
                            agent_name = a_name.as_str(),
                            "Agent authenticated"
                        );
                        continue;
                    }
                    _ => {
                        tracing::warn!(
                            run_id = r_id.as_str(),
                            agent_name = a_name.as_str(),
                            pkg_type = parsed.type_str(),
                            "Expected auth event"
                        );
                        let error_pkg = Package::AuthError(AuthErrorPackage {
                            message: "Auth required".to_string(),
                        });
                        if let Ok(json) = error_pkg.to_json() {
                            if let Some(ref inspector) = service.inspector {
                                inspector.log_outbound_str(&r_id, &json);
                            }
                            let mut sink = sender.lock().await;
                            let _ = sink.send(Message::Text(json.into())).await;
                            let _ = sink
                                .send(Message::Close(Some(
                                    axum::extract::ws::CloseFrame {
                                        code: 4001,
                                        reason: "Auth required".into(),
                                    },
                                )))
                                .await;
                        }
                        break;
                    }
                }
            }

            // Wait for register event.
            if !registered {
                if let Package::Register(ref reg) = parsed {
                    registered = true;
                    service
                        .registered_names
                        .lock()
                        .await
                        .insert(
                            (r_id.clone(), a_name.clone()),
                            reg.name.clone(),
                        );
                    tracing::info!(
                        run_id = r_id.as_str(),
                        agent_name = a_name.as_str(),
                        name = reg.name.as_str(),
                        "Agent registered"
                    );
                    let cb = service.on_agent_connected.lock().await;
                    if let Some(ref cb) = *cb {
                        cb(r_id.clone(), a_name.clone());
                    }
                    drop(cb);
                    // Also forward register event to EventService.
                    let cb = service.on_event_received.lock().await;
                    if let Some(ref cb) = *cb {
                        cb(r_id.clone(), a_name.clone(), parsed);
                    }
                } else {
                    tracing::warn!(
                        pkg_type = parsed.type_str(),
                        "Expected register event after auth"
                    );
                    let cb = service.on_event_received.lock().await;
                    if let Some(ref cb) = *cb {
                        cb(r_id.clone(), a_name.clone(), parsed);
                    }
                }
                continue;
            }

            // Authenticated + registered — normal event routing.
            match parsed {
                Package::Heartbeat(ref hb) => {
                    let cb = service.on_heartbeat_received.lock().await;
                    if let Some(ref cb) = *cb {
                        cb(r_id.clone(), a_name.clone(), hb.instances.clone());
                    }
                    drop(cb);
                    service
                        .process_heartbeat(&r_id, &a_name, &hb.instances)
                        .await;
                }
                Package::StateReport(ref sr) => {
                    if !sr.instance_id.is_empty() {
                        service
                            .process_state_report(&r_id, &a_name, &sr.instance_id, sr.state.to_wire())
                            .await;
                    }
                }
                other => {
                    if other.is_output() {
                        tracing::trace!(
                            run_id = r_id.as_str(),
                            agent_name = a_name.as_str(),
                            pkg_type = other.type_str(),
                            "Output received"
                        );
                    } else {
                        tracing::debug!(
                            run_id = r_id.as_str(),
                            agent_name = a_name.as_str(),
                            pkg_type = other.type_str(),
                            "Event received"
                        );
                    }
                    let cb = service.on_event_received.lock().await;
                    if let Some(ref cb) = *cb {
                        cb(r_id.clone(), a_name.clone(), other);
                    }
                }
            }
        }

        // Disconnection.
        auth_handle.abort();
        reader_handle.abort();

        // Fix connection replacement race: only remove the connection from the
        // map if the stored sender is the same Arc as the one created in this
        // handler invocation. If a newer connection has already replaced it,
        // leave the map entry intact.
        let was_registered = service.remove_connection_if_matches(&r_id, &a_name, &sender);
        service
            .registered_names
            .lock()
            .await
            .remove(&(r_id.clone(), a_name.clone()));
        if was_registered {
            tracing::info!(
                run_id = r_id.as_str(),
                agent_name = a_name.as_str(),
                "Agent disconnected"
            );
            let cb = service.on_agent_disconnected.lock().await;
            if let Some(ref cb) = *cb {
                cb(r_id.clone(), a_name.clone());
            }
        }
    }

    // ── Connection management ──

    async fn register_connection(
        &self,
        run_id: &str,
        agent_name: &str,
        sender: WsSender,
    ) {
        // Extract existing sender first, then drop the write lock before
        // sending the close frame to avoid holding RwLock while awaiting.
        let existing_sender = {
            let mut conns = self.connections.write().unwrap_or_else(|e| e.into_inner());
            let workspace = conns.entry(run_id.to_string()).or_default();
            let existing = workspace.get(agent_name).map(Arc::clone);
            workspace.insert(agent_name.to_string(), sender);
            existing
        };

        if let Some(existing) = existing_sender {
            tracing::warn!(
                run_id,
                agent_name,
                "Closing existing connection (replaced)"
            );
            let mut sink = existing.lock().await;
            let _ = sink
                .send(Message::Close(Some(axum::extract::ws::CloseFrame {
                    code: 4000,
                    reason: "Replaced by new connection".into(),
                })))
                .await;
        }
    }

    fn remove_connection(&self, run_id: &str, agent_name: &str) -> bool {
        let mut conns = self.connections.write().unwrap_or_else(|e| e.into_inner());
        let workspace = match conns.get_mut(run_id) {
            Some(w) => w,
            None => return false,
        };
        let removed = workspace.remove(agent_name).is_some();
        if workspace.is_empty() {
            conns.remove(run_id);
        }
        removed
    }

    /// Remove a connection only if the stored sender is the same Arc as
    /// `disconnected_sender`. This prevents the disconnection path of a replaced
    /// (stale) connection from evicting the newer connection that replaced it.
    fn remove_connection_if_matches(
        &self,
        run_id: &str,
        agent_name: &str,
        disconnected_sender: &WsSender,
    ) -> bool {
        let mut conns = self.connections.write().unwrap_or_else(|e| e.into_inner());
        let workspace = match conns.get_mut(run_id) {
            Some(w) => w,
            None => return false,
        };
        let matches = workspace
            .get(agent_name)
            .map(|existing| Arc::ptr_eq(existing, disconnected_sender))
            .unwrap_or(false);
        if matches {
            workspace.remove(agent_name);
            if workspace.is_empty() {
                conns.remove(run_id);
            }
            true
        } else {
            false
        }
    }

    // ── Public API ──

    /// Get the registered name for a connected agent.
    pub async fn registered_name(
        &self,
        run_id: &str,
        agent_name: &str,
    ) -> Option<String> {
        self.registered_names
            .lock()
            .await
            .get(&(run_id.to_string(), agent_name.to_string()))
            .cloned()
    }

    /// Send a Package to a connected agent. Returns false if not connected or send fails.
    pub async fn send_to_agent(
        &self,
        run_id: &str,
        agent_name: &str,
        event: &Package,
    ) -> bool {
        let json = match event.to_json() {
            Ok(j) => j,
            Err(_) => return false,
        };
        self.send_json_to_agent(run_id, agent_name, &json).await
    }

    /// Send a raw JSON string to a specific agent's WebSocket connection.
    pub async fn send_json_to_agent(
        &self,
        run_id: &str,
        agent_name: &str,
        json: &str,
    ) -> bool {
        let sender = {
            let conns = self.connections.read().unwrap_or_else(|e| e.into_inner());
            match conns.get(run_id).and_then(|w| w.get(agent_name)) {
                Some(s) => Arc::clone(s),
                None => return false,
            }
        };

        if let Some(ref inspector) = self.inspector {
            inspector.log_outbound_str(run_id, json);
        }

        let mut sink = sender.lock().await;
        match sink.send(Message::Text(json.to_string().into())).await {
            Ok(_) => true,
            Err(e) => {
                tracing::warn!(run_id, agent_name, error = %e, "Send failed, removing");
                drop(sink);
                self.remove_connection(run_id, agent_name);
                false
            }
        }
    }

    /// Disconnect an agent by closing its WebSocket channel.
    pub async fn disconnect_agent(
        &self,
        run_id: &str,
        agent_name: &str,
        close_code: u16,
        reason: &str,
    ) {
        // Extract the sender Arc from the lock before sending the close frame.
        let sender = {
            let conns = self.connections.read().unwrap_or_else(|e| e.into_inner());
            conns.get(run_id).and_then(|w| w.get(agent_name)).map(Arc::clone)
        };
        if let Some(sender) = sender {
            let mut sink = sender.lock().await;
            let _ = sink
                .send(Message::Close(Some(axum::extract::ws::CloseFrame {
                    code: close_code,
                    reason: reason.to_string().into(),
                })))
                .await;
        }
        self.remove_connection(run_id, agent_name);
    }

    /// Whether the given agent has an active WebSocket connection.
    ///
    /// Sync-safe: uses `std::sync::RwLock` so it can be called from
    /// synchronous callback contexts without spawning OS threads.
    pub fn is_connected(&self, run_id: &str, agent_name: &str) -> bool {
        let conns = self.connections.read().unwrap_or_else(|e| e.into_inner());
        conns
            .get(run_id)
            .map(|w| w.contains_key(agent_name))
            .unwrap_or(false)
    }

    /// Whether a specific instance is still alive on the given agent.
    ///
    /// Sync-safe: uses `std::sync::RwLock`.
    pub fn is_instance_alive(
        &self,
        run_id: &str,
        agent_name: &str,
        instance_id: &str,
    ) -> bool {
        let states = self.instance_states.read().unwrap_or_else(|e| e.into_inner());
        states
            .get(&(run_id.to_string(), agent_name.to_string()))
            .map(|m| m.contains_key(instance_id))
            .unwrap_or(false)
    }

    /// Returns the heartbeat-reported state for a specific instance.
    ///
    /// Sync-safe: uses `std::sync::RwLock`.
    pub fn get_instance_state(
        &self,
        run_id: &str,
        agent_name: &str,
        instance_id: &str,
    ) -> Option<String> {
        let states = self.instance_states.read().unwrap_or_else(|e| e.into_inner());
        states
            .get(&(run_id.to_string(), agent_name.to_string()))
            .and_then(|m| m.get(instance_id).cloned())
    }

    /// List all connected agent names for a run.
    pub fn connected_agents(&self, run_id: &str) -> Vec<String> {
        let conns = self.connections.read().unwrap_or_else(|e| e.into_inner());
        conns
            .get(run_id)
            .map(|w| w.keys().cloned().collect())
            .unwrap_or_default()
    }

    /// Returns the instance IDs known for a given agent (from heartbeat state).
    ///
    /// Sync-safe: uses `std::sync::RwLock`.
    pub fn connected_instances(
        &self,
        run_id: &str,
        agent_name: &str,
    ) -> Vec<String> {
        let states = self.instance_states.read().unwrap_or_else(|e| e.into_inner());
        states
            .get(&(run_id.to_string(), agent_name.to_string()))
            .map(|m| m.keys().cloned().collect())
            .unwrap_or_default()
    }

    /// Total number of active connections across all runs.
    pub fn total_connections(&self) -> usize {
        let conns = self.connections.read().unwrap_or_else(|e| e.into_inner());
        conns.values().map(|w| w.len()).sum()
    }
}
