// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Consolidated event processing service.
//!
//! Ported from `server/event_service.dart`.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, RwLock};
use std::time::Duration;

use tokio::sync::{oneshot, Mutex};

use crate::db::dao::WorkspaceDao;
use crate::domain::enums::AgentState;
use crate::domain::models::WorkspaceAgent;
use crate::util::new_id;
use crate::workspace_config::flat_agent::FlatAgent;

use super::packages::*;

// ── Callback types ──────────────────────────────────────────────────

pub type SendToHostFn =
    Arc<dyn Fn(&str, &str, &Package) -> bool + Send + Sync>;

pub type SendToInstanceFn =
    Arc<dyn Fn(&str, &str, &str, &Package) -> bool + Send + Sync>;

pub type IsHostConnectedFn =
    Arc<dyn Fn(&str, &str) -> bool + Send + Sync>;

pub type IsInstanceConnectedFn =
    Arc<dyn Fn(&str, &str, &str) -> bool + Send + Sync>;

pub type GetInstanceStateFn =
    Arc<dyn Fn(&str, &str, &str) -> Option<String> + Send + Sync>;

pub type ConnectedInstancesFn =
    Arc<dyn Fn(&str, &str) -> Vec<String> + Send + Sync>;

pub type TryStatusTransitionFn = Arc<
    dyn Fn(String, String, String, AgentState, String) -> tokio::task::JoinHandle<()>
        + Send
        + Sync,
>;

pub type OnOutputPacketFn =
    Arc<dyn Fn(String, String, String, Package) + Send + Sync>;

pub type OnTurnCompletedFn =
    Arc<dyn Fn(String, String, String, String, String) + Send + Sync>;

/// Internal chain link for talk_to request lifecycle.
struct ChainLink {
    request_id: String,
    workspace_id: String,
    caller_agent: String,
    caller_instance: Option<String>,
    target_agent: String,
    #[allow(dead_code)]
    chain: Vec<String>,
    sender: Option<oneshot::Sender<TalkToResponsePackage>>,
}

/// Pending inquiry bubble metadata — tracks a forwarded inquiry that is
/// waiting for a supervisor to respond or bubble.
struct PendingInquiryBubble {
    workspace_id: String,
    inquiry_id: String,
    origin_agent_key: String,
    origin_instance_id: String,
    current_supervisor_key: String,
    event: InquiryRequestPackage,
    forwarding_chain: Vec<String>,
    spawned_instance_id: Option<String>,
}

/// Consolidated event processing service.
///
/// - Parses agent events and delegates output-packet persistence
/// - Tracks conversation chains (talk_to request lifecycle)
/// - Routes inquiries through the supervisor hierarchy
/// - Manages active run tracking
pub struct EventService {
    pub workspace_dao: Arc<WorkspaceDao>,

    // ── Injected transport & status delegates ──
    pub send_to_host: Mutex<Option<SendToHostFn>>,
    pub send_to_instance: Mutex<Option<SendToInstanceFn>>,
    pub is_host_connected: Mutex<Option<IsHostConnectedFn>>,
    pub is_instance_connected: Mutex<Option<IsInstanceConnectedFn>>,
    pub get_instance_state: Mutex<Option<GetInstanceStateFn>>,
    pub connected_instances: Mutex<Option<ConnectedInstancesFn>>,
    pub try_status_transition: Mutex<Option<TryStatusTransitionFn>>,

    // ── Delegates ──
    pub on_output_packet: Mutex<Option<OnOutputPacketFn>>,
    pub on_turn_completed: Mutex<Option<OnTurnCompletedFn>>,
    // ── Chain tracking state ──
    links: Mutex<HashMap<String, ChainLink>>,
    instance_chains: Mutex<HashMap<String, Vec<String>>>,

    // ── Conversation instance tracking ──
    conversation_instances: Mutex<HashMap<(String, String, String), String>>,

    // ── Active run tracking ──
    /// Uses `std::sync::RwLock` so sync callbacks can look up run IDs
    /// without spawning OS threads.
    active_run_ids: RwLock<HashMap<String, String>>,
    run_id_to_workspace_id: RwLock<HashMap<String, String>>,

    // ── Flat agent metadata ──
    flat_agents: Mutex<HashMap<String, HashMap<String, FlatAgent>>>,

    // ── Pending auto-start tracking ──
    pending_auto_start: Mutex<HashSet<(String, String)>>,

    // ── Inquiry bubbling state ──
    hierarchies: Mutex<HashMap<String, HashMap<String, Option<String>>>>,
    pending_timers: Mutex<HashMap<String, tokio::task::JoinHandle<()>>>,
    pending_bubbles: Mutex<HashMap<String, PendingInquiryBubble>>,

    // ── Chain heartbeat timer ──
    chain_heartbeat_handle: Mutex<Option<tokio::task::JoinHandle<()>>>,
    chain_heartbeat_interval: Duration,
}

impl EventService {
    pub fn new(
        workspace_dao: Arc<WorkspaceDao>,
        chain_heartbeat_interval: Duration,
    ) -> Self {
        Self {
            workspace_dao,
            send_to_host: Mutex::new(None),
            send_to_instance: Mutex::new(None),
            is_host_connected: Mutex::new(None),
            is_instance_connected: Mutex::new(None),
            get_instance_state: Mutex::new(None),
            connected_instances: Mutex::new(None),
            try_status_transition: Mutex::new(None),
            on_output_packet: Mutex::new(None),
            on_turn_completed: Mutex::new(None),
            links: Mutex::new(HashMap::new()),
            instance_chains: Mutex::new(HashMap::new()),
            conversation_instances: Mutex::new(HashMap::new()),
            active_run_ids: RwLock::new(HashMap::new()),
            run_id_to_workspace_id: RwLock::new(HashMap::new()),
            flat_agents: Mutex::new(HashMap::new()),
            pending_auto_start: Mutex::new(HashSet::new()),
            hierarchies: Mutex::new(HashMap::new()),
            pending_timers: Mutex::new(HashMap::new()),
            pending_bubbles: Mutex::new(HashMap::new()),
            chain_heartbeat_handle: Mutex::new(None),
            chain_heartbeat_interval,
        }
    }

    pub fn with_default_interval(workspace_dao: Arc<WorkspaceDao>) -> Self {
        Self::new(workspace_dao, Duration::from_secs(30))
    }

    // ── Lifecycle ──

    /// Start periodic chain-alive heartbeats.
    pub async fn start(self: &Arc<Self>) {
        let mut handle = self.chain_heartbeat_handle.lock().await;
        if let Some(h) = handle.take() {
            h.abort();
        }
        let service = Arc::clone(self);
        let interval = self.chain_heartbeat_interval;
        *handle = Some(tokio::spawn(async move {
            let mut ticker = tokio::time::interval(interval);
            loop {
                ticker.tick().await;
                service.send_chain_heartbeats().await;
            }
        }));
        tracing::info!(
            interval_secs = self.chain_heartbeat_interval.as_secs(),
            "EventService started"
        );
    }

    /// Stop heartbeats, fail all pending chains.
    pub async fn dispose(&self) {
        let mut handle = self.chain_heartbeat_handle.lock().await;
        if let Some(h) = handle.take() {
            h.abort();
        }

        // Fail all pending chain links.
        let request_ids: Vec<String> = {
            let links = self.links.lock().await;
            links.keys().cloned().collect()
        };
        for request_id in request_ids {
            self.fail_link(&request_id, "Server shutting down.").await;
        }

        // Cancel all inquiry timers.
        let mut timers = self.pending_timers.lock().await;
        for (_, handle) in timers.drain() {
            handle.abort();
        }
        self.pending_bubbles.lock().await.clear();
        self.hierarchies.lock().await.clear();
        self.flat_agents.lock().await.clear();
        self.conversation_instances.lock().await.clear();
        self.instance_chains.lock().await.clear();

        tracing::info!("EventService disposed");
    }

    // ── Active run tracking ──

    pub fn register_workspace_run(&self, workspace_id: &str, run_id: &str) {
        self.active_run_ids
            .write()
            .unwrap_or_else(|e| e.into_inner())
            .insert(workspace_id.to_string(), run_id.to_string());
        self.run_id_to_workspace_id
            .write()
            .unwrap_or_else(|e| e.into_inner())
            .insert(run_id.to_string(), workspace_id.to_string());
    }

    pub fn deregister_workspace_run(&self, workspace_id: &str) {
        let run_id = self.active_run_ids.write().unwrap_or_else(|e| e.into_inner()).remove(workspace_id);
        if let Some(run_id) = run_id {
            self.run_id_to_workspace_id.write().unwrap_or_else(|e| e.into_inner()).remove(&run_id);
        }
        // pending_auto_start still uses tokio::sync::Mutex, so we spawn to clean it.
        // However since this method is now sync, we do a blocking lock on the tokio mutex.
        // Actually, pending_auto_start is only used in async contexts, so let's just
        // leave this as a separate async call or use try_lock.
        if let Ok(mut pending) = self.pending_auto_start.try_lock() {
            pending.retain(|(ws, _)| ws != workspace_id);
        }
        // Clean up in-memory maps to prevent unbounded growth across run restarts.
        // These maps use tokio::sync::Mutex; use try_lock (non-blocking) since
        // deregister_workspace_run is called from sync contexts. If the lock is
        // contended, the entries will be cleaned up lazily on the next run start
        // or via dispose().
        if let Ok(mut links) = self.links.try_lock() {
            links.retain(|_, link| link.workspace_id != workspace_id);
        }
        if let Ok(mut conv) = self.conversation_instances.try_lock() {
            conv.retain(|(ws, _, _), _| ws != workspace_id);
        }
        if let Ok(mut bubbles) = self.pending_bubbles.try_lock() {
            bubbles.retain(|_, b| b.workspace_id != workspace_id);
        }
        // Note: instance_chains is keyed by instance_id with no workspace reference;
        // it is cleaned up by clear_workspace_chains() (called on stop) or dispose().
        tracing::debug!(workspace_id, "Cleaned up in-memory maps for workspace run");
    }

    /// Sync-safe active run ID lookup.
    pub fn active_run_id(&self, workspace_id: &str) -> Option<String> {
        self.active_run_ids
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .get(workspace_id)
            .cloned()
    }

    /// Sync-safe workspace ID lookup by run ID.
    pub fn workspace_id_for_run(&self, run_id: &str) -> Option<String> {
        self.run_id_to_workspace_id
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .get(run_id)
            .cloned()
    }

    // ── Workspace registration ──

    pub async fn register_workspace(
        &self,
        workspace_id: &str,
        agents: &[FlatAgent],
    ) {
        let mut hierarchy = HashMap::new();
        let mut agent_map = HashMap::new();
        for agent in agents {
            hierarchy.insert(agent.agent_key.clone(), agent.parent_key.clone());
            agent_map.insert(agent.agent_key.clone(), agent.clone());
        }
        self.hierarchies
            .lock()
            .await
            .insert(workspace_id.to_string(), hierarchy);
        self.flat_agents
            .lock()
            .await
            .insert(workspace_id.to_string(), agent_map);
    }

    pub async fn remove_workspace(&self, workspace_id: &str) {
        self.deregister_workspace_run(workspace_id);
        self.hierarchies.lock().await.remove(workspace_id);
        self.flat_agents.lock().await.remove(workspace_id);

        let to_remove: Vec<String> = {
            let bubbles = self.pending_bubbles.lock().await;
            bubbles
                .iter()
                .filter(|(_, b)| b.workspace_id == workspace_id)
                .map(|(id, _)| id.clone())
                .collect()
        };
        for id in &to_remove {
            if let Some(handle) = self.pending_timers.lock().await.remove(id) {
                handle.abort();
            }
            self.pending_bubbles.lock().await.remove(id);
        }
    }

    // ── Pending auto-start ──

    pub async fn mark_pending_auto_start(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) {
        let agents = self.flat_agents.lock().await;
        let agent = agents
            .get(workspace_id)
            .and_then(|m| m.get(agent_key));
        if let Some(agent) = agent {
            if !agent.auto_start {
                return;
            }
        } else {
            return;
        }
        drop(agents);

        self.pending_auto_start
            .lock()
            .await
            .insert((workspace_id.to_string(), agent_key.to_string()));
        tracing::info!(
            agent_key,
            "Marked pending auto-start (waiting for heartbeat)"
        );
    }

    pub async fn auto_start_if_needed(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) {
        // Remove matching entry from pending.
        let key = (workspace_id.to_string(), agent_key.to_string());
        let mut pending = self.pending_auto_start.lock().await;
        if !pending.remove(&key) {
            return;
        }
        drop(pending);

        // Check if agent already has a running instance.
        let connected = {
            let ci = self.connected_instances.lock().await;
            if let Some(ref ci) = *ci {
                ci(workspace_id, agent_key)
            } else {
                vec![]
            }
        };
        if !connected.is_empty() {
            let iic = self.is_instance_connected.lock().await;
            if let Some(ref iic) = *iic {
                if connected.iter().any(|id| iic(workspace_id, agent_key, id)) {
                    tracing::info!(
                        agent_key,
                        "Skipping auto-start -- instance already alive"
                    );
                    return;
                }
            }
        }

        let agents = self.flat_agents.lock().await;
        let flat_agent = agents
            .get(workspace_id)
            .and_then(|m| m.get(agent_key))
            .cloned();
        drop(agents);

        if let Some(flat_agent) = flat_agent {
            if flat_agent.parent_key.is_none() {
                // Root agent -- start root instance.
                match self
                    .start_root_instance(workspace_id, agent_key)
                    .await
                {
                    Ok(_) => tracing::info!(
                        agent_key,
                        "Auto-started root instance"
                    ),
                    Err(e) => tracing::error!(
                        agent_key,
                        error = %e,
                        "Failed to auto-start root instance"
                    ),
                }
            }
        }
    }

    // ── Event dispatch ──

    pub async fn handle_event(
        self: &Arc<Self>,
        workspace_id: &str,
        agent_key: &str,
        event: Package,
    ) -> Option<Package> {
        match event {
            Package::Register(ref _r) => {
                let run_id = self.active_run_ids.read().unwrap_or_else(|e| e.into_inner());
                if run_id.get(workspace_id).is_none() {
                    tracing::warn!(
                        workspace_id,
                        agent_key,
                        "Register event for workspace with no active run"
                    );
                }
                None
            }
            Package::Message(ref pkg) => {
                self.handle_output(workspace_id, agent_key, &event, pkg.instance_id.as_str())
                    .await;
                None
            }
            Package::PromptReceived(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event, &_pkg.instance_id)
                    .await;
                None
            }
            Package::Activity(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event, &_pkg.instance_id)
                    .await;
                None
            }
            Package::Log(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event, &_pkg.instance_id)
                    .await;
                None
            }
            Package::Usage(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event, &_pkg.instance_id)
                    .await;
                None
            }
            Package::Files(ref _pkg) => {
                self.handle_output(workspace_id, agent_key, &event, &_pkg.instance_id)
                    .await;
                None
            }
            Package::TalkToRequest(ref pkg) => {
                self.handle_talk_to_request(workspace_id, agent_key, pkg.clone())
                    .await;
                None
            }
            Package::TalkToResponse(ref pkg) => {
                self.handle_talk_to_response(workspace_id, agent_key, pkg.clone())
                    .await;
                None
            }
            Package::InquiryRequest(ref pkg) => {
                self.handle_inquiry_create(workspace_id, agent_key, pkg)
                    .await;
                None
            }
            Package::InquiryResponse(ref pkg) => {
                self.handle_inquiry_response(workspace_id, agent_key, pkg)
                    .await;
                None
            }
            Package::InstanceSpawned(ref pkg) => {
                tracing::info!(
                    agent_key,
                    instance_id = pkg.instance_id.as_str(),
                    "Instance spawned ack"
                );
                None
            }
            Package::Drain(ref pkg) => {
                tracing::info!(
                    agent_key,
                    instance_id = pkg.instance_id.as_str(),
                    "Drain signal received -- forwarding to host"
                );
                let sth = self.send_to_host.lock().await;
                if let Some(ref sth) = *sth {
                    sth(workspace_id, agent_key, &event);
                }
                None
            }
            Package::Heartbeat(_) | Package::StateReport(_) | Package::Auth(_) => None,
            Package::Unknown(ref u) => {
                tracing::warn!(raw_type = u.raw_type.as_str(), "Unknown agent event type");
                None
            }
            _ => None,
        }
    }

    async fn handle_output(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: &Package,
        _instance_id: &str,
    ) {
        let run_id = {
            let ids = self.active_run_ids.read().unwrap_or_else(|e| e.into_inner());
            match ids.get(workspace_id) {
                Some(id) => id.clone(),
                None => return,
            }
        };

        let cb = self.on_output_packet.lock().await;
        if let Some(ref cb) = *cb {
            cb(
                workspace_id.to_string(),
                agent_key.to_string(),
                run_id,
                event.clone(),
            );
        }
    }

    // ── talk_to handling ──

    async fn handle_talk_to_request(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: TalkToRequestPackage,
    ) {
        let target_agent = &event.target_agent;
        let request_id = &event.request_id;
        let caller_instance_id = if event.instance_id.is_empty() {
            "host".to_string()
        } else {
            event.instance_id.clone()
        };
        let chain = {
            let chains = self.instance_chains.lock().await;
            chains
                .get(&event.instance_id)
                .cloned()
                .unwrap_or_default()
        };

        // 1. Cycle detection.
        if let Some(cycle_error) =
            Self::detect_cycle(target_agent, agent_key, &chain)
        {
            self.send_request_failed(
                workspace_id,
                agent_key,
                &event.instance_id,
                &RequestFailedPackage {
                    instance_id: event.instance_id.clone(),
                    request_id: request_id.clone(),
                    reason: cycle_error,
                },
            )
            .await;
            return;
        }

        // 2. Check if target host is connected.
        let host_connected = {
            let ihc = self.is_host_connected.lock().await;
            if let Some(ref ihc) = *ihc {
                ihc(workspace_id, target_agent)
            } else {
                false
            }
        };
        if !host_connected {
            self.send_request_failed(
                workspace_id,
                agent_key,
                &event.instance_id,
                &RequestFailedPackage {
                    instance_id: event.instance_id.clone(),
                    request_id: request_id.clone(),
                    reason: format!("Agent \"{}\" is not connected.", target_agent),
                },
            )
            .await;
            return;
        }

        let mut extended_chain = chain;
        extended_chain.push(agent_key.to_string());

        // 3. Register chain link and transition caller to WaitingForAgent.
        let (tx, rx) = oneshot::channel::<TalkToResponsePackage>();
        {
            let mut links = self.links.lock().await;
            links.insert(
                request_id.to_string(),
                ChainLink {
                    request_id: request_id.to_string(),
                    workspace_id: workspace_id.to_string(),
                    caller_agent: agent_key.to_string(),
                    caller_instance: if event.instance_id.is_empty() {
                        None
                    } else {
                        Some(event.instance_id.clone())
                    },
                    target_agent: target_agent.to_string(),
                    chain: extended_chain.clone(),
                    sender: Some(tx),
                },
            );
        }

        // Transition caller to WaitingForAgent.
        if !event.instance_id.is_empty() {
            self.try_status_transition_async(
                workspace_id,
                agent_key,
                &event.instance_id,
                AgentState::WaitingForAgent,
                "register_link",
            )
            .await;
        }

        // 4. Determine target instance.
        let continue_conv = event.continue_conversation;
        let conv_key = (
            workspace_id.to_string(),
            caller_instance_id.clone(),
            target_agent.to_string(),
        );

        let existing_instance_id = {
            let ci = self.conversation_instances.lock().await;
            ci.get(&conv_key).cloned()
        };

        let instance_alive = if let Some(ref eid) = existing_instance_id {
            let iic = self.is_instance_connected.lock().await;
            if let Some(ref iic) = *iic {
                iic(workspace_id, target_agent, eid)
            } else {
                false
            }
        } else {
            false
        };

        let target_instance_id = if instance_alive && continue_conv {
            // Case A: continue existing conversation.
            existing_instance_id.unwrap()
        } else if instance_alive && !continue_conv {
            // Case C: old instance alive but continue=false.
            // Send TerminatePackage, wait for instance gone, then open new.
            let old_id = existing_instance_id.unwrap();
            {
                let sth = self.send_to_host.lock().await;
                if let Some(ref sth) = *sth {
                    let terminate_pkg = Package::Terminate(TerminatePackage {
                        instance_id: old_id.clone(),
                    });
                    sth(workspace_id, target_agent, &terminate_pkg);
                }
            }
            self.wait_for_instance_gone(workspace_id, target_agent, &old_id)
                .await;
            self.open_new_instance(workspace_id, target_agent, &conv_key, &extended_chain)
                .await
        } else {
            // Case B: no existing instance or not alive.
            self.open_new_instance(workspace_id, target_agent, &conv_key, &extended_chain)
                .await
        };

        // 5. Send the message to the target instance.
        {
            let sti = self.send_to_instance.lock().await;
            if let Some(ref sti) = *sti {
                let forward = Package::TalkToRequest(TalkToRequestPackage {
                    instance_id: target_instance_id.clone(),
                    target_agent: event.target_agent.clone(),
                    text: event.text.clone(),
                    request_id: request_id.clone(),
                    caller_agent: Some(agent_key.to_string()),
                    continue_conversation: event.continue_conversation,
                });
                sti(workspace_id, target_agent, &target_instance_id, &forward);
            }
        }

        // 6. Wait for the result, then assemble transcript as the response
        //    (mirrors Dart SDK's _assembleResponseTranscript approach).
        match rx.await {
            Ok(result) => {
                // Build response from transcript if we have instance_id + turn_id.
                let response_text = if !result.instance_id.is_empty() {
                    if let Some(ref turn_id) = result.turn_id {
                        let transcript = self
                            .assemble_transcript(&result.instance_id, turn_id)
                            .await;
                        if transcript.is_empty() {
                            result.response.clone()
                        } else {
                            Some(transcript)
                        }
                    } else {
                        result.response.clone()
                    }
                } else {
                    result.response.clone()
                };

                tracing::info!(
                    caller = agent_key,
                    target = target_agent.as_str(),
                    has_response = response_text.is_some(),
                    response_len = response_text.as_ref().map(|r| r.len()).unwrap_or(0),
                    "Relaying talk_to response back to caller (transcript-assembled)"
                );
                let response = Package::TalkToResponse(TalkToResponsePackage {
                    instance_id: event.instance_id.clone(),
                    request_id: request_id.clone(),
                    turn_id: result.turn_id.clone(),
                    response: response_text,
                    error: None,
                });
                self.send_to_caller(
                    workspace_id,
                    agent_key,
                    &event.instance_id,
                    &response,
                )
                .await;
            }
            Err(_) => {
                let response = Package::TalkToResponse(TalkToResponsePackage {
                    instance_id: event.instance_id.clone(),
                    request_id: request_id.clone(),
                    turn_id: None,
                    response: None,
                    error: Some("Chain link cancelled.".to_string()),
                });
                self.send_to_caller(
                    workspace_id,
                    agent_key,
                    &event.instance_id,
                    &response,
                )
                .await;
            }
        }
    }

    async fn handle_talk_to_response(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: TalkToResponsePackage,
    ) {
        tracing::info!(
            agent_key,
            request_id = event.request_id.as_str(),
            has_response = event.response.is_some(),
            response_len = event.response.as_ref().map(|r| r.len()).unwrap_or(0),
            "Received talk_to response from target"
        );

        // Insert InstanceResult row if we have a turn_id.
        if let Some(ref turn_id) = event.turn_id {
            let run_id = self.active_run_id(workspace_id);
            if let Some(ref run_id) = run_id {
                let result_id = new_id();
                let _ = self.workspace_dao.insert_instance_result(
                    &result_id,
                    run_id,
                    agent_key,
                    &event.instance_id,
                    turn_id,
                    Some(&event.request_id),
                );

                // Assemble transcript and fire on_turn_completed.
                let transcript = self.assemble_transcript(&event.instance_id, turn_id).await;
                let cb = self.on_turn_completed.lock().await;
                if let Some(ref cb) = *cb {
                    cb(
                        workspace_id.to_string(),
                        agent_key.to_string(),
                        event.instance_id.clone(),
                        turn_id.clone(),
                        transcript,
                    );
                }
                // Table invalidation handles notification to consumers.
            }
        }

        let completed = self
            .complete_link(&event.request_id, event.clone())
            .await;
        if !completed {
            tracing::warn!(
                request_id = event.request_id.as_str(),
                "Instance result for unknown/completed request"
            );
        }
    }

    async fn handle_inquiry_create(
        self: &Arc<Self>,
        workspace_id: &str,
        agent_key: &str,
        event: &InquiryRequestPackage,
    ) {
        let run_id = {
            let ids = self.active_run_ids.read().unwrap_or_else(|e| e.into_inner());
            match ids.get(workspace_id) {
                Some(id) => id.clone(),
                None => return,
            }
        };

        // Transition agent to WaitingForInquiry.
        if !event.instance_id.is_empty() {
            self.try_status_transition_async(
                workspace_id,
                agent_key,
                &event.instance_id,
                AgentState::WaitingForInquiry,
                "handle_inquiry_create",
            )
            .await;
        }

        // Create inquiry in DB.
        let priority = match event.priority {
            WireInquiryPriority::Normal => crate::domain::enums::InquiryPriority::Normal,
            WireInquiryPriority::High => crate::domain::enums::InquiryPriority::High,
            WireInquiryPriority::Urgent => crate::domain::enums::InquiryPriority::Urgent,
        };
        let inquiry = crate::domain::models::WorkspaceInquiry {
            id: event.inquiry_id.clone(),
            run_id: run_id.clone(),
            agent_key: agent_key.to_string(),
            instance_id: event.instance_id.clone(),
            status: crate::domain::enums::InquiryStatus::Pending,
            priority,
            content_markdown: event.content_markdown.clone(),
            attachments_json: None,
            suggestions_json: if event.suggestions.is_empty() {
                None
            } else {
                Some(serde_json::to_string(&event.suggestions).unwrap_or_default())
            },
            response_text: None,
            response_suggestion_index: None,
            responded_by_agent_key: None,
            forwarding_chain_json: None,
            created_at: chrono::Utc::now().naive_utc(),
            responded_at: None,
        };
        let _ = self.workspace_dao.insert_workspace_inquiry(&inquiry);

        // Try to forward to supervisor; if no supervisor found, surface to user.
        self.try_forward_to_supervisor(
            workspace_id,
            &event.inquiry_id,
            agent_key,
            &event.instance_id,
            agent_key,
            event,
            vec![],
        )
        .await;
    }

    async fn handle_inquiry_response(
        &self,
        workspace_id: &str,
        agent_key: &str,
        event: &InquiryResponsePackage,
    ) {
        self.handle_supervisor_response(
            workspace_id,
            &event.inquiry_id,
            agent_key,
            &event.instance_id,
            event.response_text.as_deref().unwrap_or(""),
            event.response_suggestion_index,
        )
        .await;
    }

    // ── Instance lifecycle ──

    pub async fn start_root_instance(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) -> Result<String, String> {
        let new_instance_id = new_id();
        tracing::info!(
            agent_key,
            instance_id = new_instance_id.as_str(),
            "Starting root instance"
        );

        let sth = self.send_to_host.lock().await;
        if let Some(ref sth) = *sth {
            let pkg = Package::SpawnInstance(SpawnInstancePackage {
                instance_id: new_instance_id.clone(),
            });
            if !sth(workspace_id, agent_key, &pkg) {
                return Err(format!(
                    "Failed to send spawn_instance to \"{}\".",
                    agent_key
                ));
            }
        } else {
            return Err("send_to_host not set".to_string());
        }
        drop(sth);

        self.instance_chains
            .lock()
            .await
            .insert(new_instance_id.clone(), vec![]);

        // Wait for instance to appear in heartbeat and create DB row.
        self.wait_for_instance_alive(workspace_id, agent_key, &new_instance_id)
            .await;
        self.create_instance_row(workspace_id, agent_key, &new_instance_id, AgentState::Idle)
            .await;

        Ok(new_instance_id)
    }

    /// Start a sub-instance for the given agent. Creates the DB row first,
    /// tracks an empty chain, sends SpawnInstance, and fires a background
    /// wait for alive.
    pub async fn start_sub_instance(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) -> Result<String, String> {
        let new_instance_id = new_id();
        tracing::info!(
            agent_key,
            instance_id = new_instance_id.as_str(),
            "Starting sub-instance"
        );

        // Create DB row first.
        self.create_instance_row(workspace_id, agent_key, &new_instance_id, AgentState::Idle)
            .await;

        // Track empty chain.
        self.instance_chains
            .lock()
            .await
            .insert(new_instance_id.clone(), vec![]);

        // Send SpawnInstance.
        let sth = self.send_to_host.lock().await;
        if let Some(ref sth) = *sth {
            let pkg = Package::SpawnInstance(SpawnInstancePackage {
                instance_id: new_instance_id.clone(),
            });
            sth(workspace_id, agent_key, &pkg);
        }
        drop(sth);

        // Fire-and-forget wait for alive.
        let ws_id = workspace_id.to_string();
        let ak = agent_key.to_string();
        let iid = new_instance_id.clone();
        let iic = self.is_instance_connected.lock().await.clone();
        tokio::spawn(async move {
            Self::poll_instance_alive(&iic, &ws_id, &ak, &iid, Duration::from_secs(30)).await;
        });

        Ok(new_instance_id)
    }

    pub async fn interrupt_instance(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
    ) {
        tracing::info!(agent_key, instance_id, "Interrupting instance generation");

        let sth = self.send_to_host.lock().await;
        if let Some(ref sth) = *sth {
            let pkg = Package::Interrupt(InterruptPackage {
                instance_id: instance_id.to_string(),
            });
            sth(workspace_id, agent_key, &pkg);
        }
    }

    pub async fn stop_instance(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
    ) {
        tracing::info!(agent_key, instance_id, "Stopping instance");

        let sth = self.send_to_host.lock().await;
        if let Some(ref sth) = *sth {
            let pkg = Package::Terminate(TerminatePackage {
                instance_id: instance_id.to_string(),
            });
            sth(workspace_id, agent_key, &pkg);
        }
        drop(sth);

        // Clean up conversation tracking.
        self.conversation_instances.lock().await.retain(|k, v| {
            !(k.0 == workspace_id && k.2 == agent_key && v == instance_id)
        });
        self.instance_chains.lock().await.remove(instance_id);

        // Fail pending chain links involving this instance.
        let to_fail: Vec<String> = {
            let links = self.links.lock().await;
            links
                .iter()
                .filter(|(_, link)| {
                    link.workspace_id == workspace_id
                        && link.caller_instance.as_deref() == Some(instance_id)
                })
                .map(|(id, _)| id.clone())
                .collect()
        };
        for request_id in to_fail {
            self.fail_link(
                &request_id,
                &format!("Instance \"{}\" stopped.", instance_id),
            )
            .await;
        }
    }

    /// Deletes a stale disconnected instance row from the DB.
    pub async fn cleanup_instance(
        &self,
        _workspace_id: &str,
        _agent_key: &str,
        instance_id: &str,
    ) {
        let _ = self
            .workspace_dao
            .delete_workspace_agent_by_instance_id(instance_id);
        tracing::info!(instance_id, "Cleaned up stale instance row");
    }

    /// Deletes ALL disconnected instance rows for an agent. Returns count deleted.
    pub async fn cleanup_stale_instances(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) -> usize {
        let run_id = match self.active_run_id(workspace_id) {
            Some(id) => id,
            None => return 0,
        };

        let agents = match self.workspace_dao.get_workspace_agents(&run_id) {
            Ok(a) => a,
            Err(_) => return 0,
        };

        let mut count = 0;
        for agent in agents {
            if agent.agent_key == agent_key && agent.status == AgentState::Disconnected {
                let _ = self
                    .workspace_dao
                    .delete_workspace_agent_by_instance_id(&agent.instance_id);
                count += 1;
            }
        }
        if count > 0 {
            tracing::info!(agent_key, count, "Cleaned up stale instances");
        }
        count
    }

    /// Restore instance chains from DB for active agents in a run.
    pub async fn restore_instance_chains(&self, run_id: &str) {
        let agents = match self.workspace_dao.get_workspace_agents(run_id) {
            Ok(a) => a,
            Err(_) => return,
        };

        let mut chains = self.instance_chains.lock().await;
        for agent in agents {
            if agent.status.is_terminal() || agent.status == AgentState::Disconnected {
                continue;
            }
            if !agent.chain_json.is_empty() {
                if let Ok(chain) = serde_json::from_str::<Vec<String>>(&agent.chain_json) {
                    chains.insert(agent.instance_id, chain);
                }
            } else {
                chains.insert(agent.instance_id, vec![]);
            }
        }
        tracing::info!(run_id, "Restored instance chains from DB");
    }

    /// Fail all chain links for a workspace and clear conversation instances.
    pub async fn clear_workspace_chains(&self, workspace_id: &str) {
        // Fail all pending chain links for this workspace.
        let to_fail: Vec<String> = {
            let links = self.links.lock().await;
            links
                .iter()
                .filter(|(_, link)| link.workspace_id == workspace_id)
                .map(|(id, _)| id.clone())
                .collect()
        };
        for request_id in to_fail {
            self.fail_link(&request_id, "Workspace chains cleared.").await;
        }

        // Collect instance_ids from conversation tracking BEFORE clearing,
        // so we can also remove their instance chains.
        let conv_instance_ids: Vec<String> = {
            let ci = self.conversation_instances.lock().await;
            ci.iter()
                .filter(|(k, _)| k.0 == workspace_id)
                .map(|(_, v)| v.clone())
                .collect()
        };

        // Clear conversation instances for this workspace.
        self.conversation_instances
            .lock()
            .await
            .retain(|k, _| k.0 != workspace_id);

        // Clear instance chains for conversation instances in this workspace.
        let mut chains = self.instance_chains.lock().await;
        for iid in &conv_instance_ids {
            chains.remove(iid);
        }
    }

    /// Returns the agent that the given agent_key is waiting for (via chain link).
    pub async fn waiting_for(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) -> Option<String> {
        let links = self.links.lock().await;
        for link in links.values() {
            if link.workspace_id == workspace_id && link.caller_agent == agent_key {
                return Some(link.target_agent.clone());
            }
        }
        None
    }

    /// Assembles a compressed transcript from DB records for a given instance
    /// and turn. Only includes the agent's own output messages (role != "user"),
    /// not received prompts. Activities are counted and shown as summary lines
    /// between messages (e.g. "--- 3 activities recorded ---").
    ///
    /// Mirrors the Dart SDK's `assembleTranscript` method.
    pub async fn assemble_transcript(
        &self,
        instance_id: &str,
        turn_id: &str,
    ) -> String {
        // Fetch messages, excluding role=user (prompts / talk_to requests).
        let messages = match self.workspace_dao.get_messages_for_turn(instance_id, turn_id) {
            Ok(all) => all.into_iter().filter(|m| m.role != "user").collect::<Vec<_>>(),
            Err(e) => {
                tracing::warn!(
                    instance_id, turn_id, error = %e,
                    "Failed to fetch messages for transcript assembly"
                );
                Vec::new()
            }
        };

        // Fetch activities (only used for counting, not content).
        let activities = match self
            .workspace_dao
            .get_activities_for_turn(instance_id, turn_id)
        {
            Ok(a) => a,
            Err(e) => {
                tracing::warn!(
                    instance_id, turn_id, error = %e,
                    "Failed to fetch activities for transcript assembly"
                );
                Vec::new()
            }
        };

        // Merge messages and activities by timestamp, then build transcript.
        enum Entry {
            Message { content: String },
            Activity,
        }
        let mut timeline: Vec<(chrono::NaiveDateTime, Entry)> = Vec::new();
        for msg in &messages {
            timeline.push((msg.created_at, Entry::Message { content: msg.content.clone() }));
        }
        for act in &activities {
            timeline.push((act.timestamp, Entry::Activity));
        }
        timeline.sort_by_key(|(ts, _)| *ts);

        let mut buf = String::new();
        let mut activity_count: usize = 0;

        for (_, entry) in &timeline {
            match entry {
                Entry::Message { content } => {
                    if activity_count > 0 {
                        let word = if activity_count == 1 { "activity" } else { "activities" };
                        buf.push_str(&format!("\n--- {} {} recorded ---\n", activity_count, word));
                        activity_count = 0;
                    }
                    if !buf.is_empty() {
                        buf.push('\n');
                    }
                    buf.push_str(content);
                }
                Entry::Activity => {
                    activity_count += 1;
                }
            }
        }
        if activity_count > 0 {
            let word = if activity_count == 1 { "activity" } else { "activities" };
            buf.push_str(&format!("\n--- {} {} recorded ---\n", activity_count, word));
        }

        buf
    }

    // ── Inquiry routing ──

    /// Walks the hierarchy to find a supervisor, optionally spawns a dedicated
    /// instance, and forwards the inquiry. If no supervisor is found, surfaces
    /// to user via `on_inquiry_created`.
    async fn try_forward_to_supervisor(
        self: &Arc<Self>,
        workspace_id: &str,
        inquiry_id: &str,
        origin_agent_key: &str,
        origin_instance_id: &str,
        current_agent_key: &str,
        event: &InquiryRequestPackage,
        forwarding_chain: Vec<String>,
    ) {
        // Look up the supervisor for the current agent.
        let supervisor_key = {
            let hierarchies = self.hierarchies.lock().await;
            match hierarchies.get(workspace_id) {
                Some(h) => h.get(current_agent_key).cloned().flatten(),
                None => {
                    self.surface_to_user(
                        workspace_id,
                        inquiry_id,
                        &forwarding_chain,
                        &event.priority,
                        origin_agent_key,
                    )
                    .await;
                    return;
                }
            }
        };

        let supervisor_key = match supervisor_key {
            Some(k) => k,
            None => {
                self.surface_to_user(
                    workspace_id,
                    inquiry_id,
                    &forwarding_chain,
                    &event.priority,
                    origin_agent_key,
                )
                .await;
                return;
            }
        };

        // Check if supervisor is connected.
        let host_connected = {
            let ihc = self.is_host_connected.lock().await;
            if let Some(ref ihc) = *ihc {
                ihc(workspace_id, &supervisor_key)
            } else {
                false
            }
        };

        if !host_connected {
            tracing::info!(
                supervisor = supervisor_key.as_str(),
                inquiry_id,
                "Supervisor host not connected, surfacing inquiry to user"
            );
            self.surface_to_user(
                workspace_id,
                inquiry_id,
                &forwarding_chain,
                &event.priority,
                origin_agent_key,
            )
            .await;
            return;
        }

        // Build the forward event (instanceId blank — will be injected by transport).
        let forward_event = InquiryRequestPackage {
            instance_id: String::new(),
            inquiry_id: inquiry_id.to_string(),
            content_markdown: event.content_markdown.clone(),
            suggestions: event.suggestions.clone(),
            file_paths: event.file_paths.clone(),
            priority: event.priority.clone(),
        };

        // Path A: Supervisor has an instance in the same conversation chain.
        let chain_instance_id = self
            .find_supervisor_instance_in_chain(workspace_id, &supervisor_key, current_agent_key)
            .await;

        let mut sent = false;
        let mut spawned_instance_id: Option<String> = None;

        if let Some(ref chain_iid) = chain_instance_id {
            tracing::info!(
                supervisor = supervisor_key.as_str(),
                instance_id = chain_iid.as_str(),
                inquiry_id,
                "Supervisor instance is in the same conversation chain — forwarding inline"
            );
            let sti = self.send_to_instance.lock().await;
            if let Some(ref sti) = *sti {
                sent = sti(
                    workspace_id,
                    &supervisor_key,
                    chain_iid,
                    &Package::InquiryRequest(forward_event.clone()),
                );
            }
        }

        // Path B: Supervisor NOT in chain — spawn a dedicated instance.
        if !sent {
            tracing::info!(
                supervisor = supervisor_key.as_str(),
                inquiry_id,
                "Supervisor not in conversation chain — spawning dedicated inquiry instance"
            );
            spawned_instance_id = self
                .open_inquiry_instance(workspace_id, &supervisor_key, &forward_event)
                .await;
            sent = spawned_instance_id.is_some();
        }

        if !sent {
            self.surface_to_user(
                workspace_id,
                inquiry_id,
                &forwarding_chain,
                &event.priority,
                origin_agent_key,
            )
            .await;
            return;
        }

        tracing::info!(
            inquiry_id,
            origin_agent_key,
            supervisor = supervisor_key.as_str(),
            spawned = ?spawned_instance_id,
            "Forwarded inquiry to supervisor"
        );

        // Store pending bubble metadata.
        self.pending_bubbles.lock().await.insert(
            inquiry_id.to_string(),
            PendingInquiryBubble {
                workspace_id: workspace_id.to_string(),
                inquiry_id: inquiry_id.to_string(),
                origin_agent_key: origin_agent_key.to_string(),
                origin_instance_id: origin_instance_id.to_string(),
                current_supervisor_key: supervisor_key.clone(),
                event: event.clone(),
                forwarding_chain,
                spawned_instance_id,
            },
        );

        // Start 60-second bubble timeout timer.
        let self_clone = Arc::clone(self);
        let ws_id = workspace_id.to_string();
        let inq_id = inquiry_id.to_string();
        let sup_key = supervisor_key.clone();
        let timer_handle = tokio::spawn(async move {
            tokio::time::sleep(Duration::from_secs(60)).await;
            tracing::info!(
                inquiry_id = inq_id.as_str(),
                supervisor = sup_key.as_str(),
                "Inquiry timed out waiting for supervisor, auto-bubbling"
            );
            // Use Box::pin to break the indirect async recursion cycle
            // (try_forward_to_supervisor -> timer -> handle_supervisor_bubble -> try_forward_to_supervisor).
            Box::pin(self_clone.handle_supervisor_bubble(&ws_id, &inq_id, &sup_key)).await;
        });
        self.pending_timers
            .lock()
            .await
            .insert(inquiry_id.to_string(), timer_handle);
    }

    /// Routes a supervisor's response back to the origin agent, updates DB, and
    /// closes any spawned inquiry instance.
    pub async fn handle_supervisor_response(
        &self,
        workspace_id: &str,
        inquiry_id: &str,
        responding_agent_key: &str,
        _responding_instance_id: &str,
        response_text: &str,
        response_suggestion_index: Option<i64>,
    ) {
        // Cancel bubble timer.
        if let Some(handle) = self.pending_timers.lock().await.remove(inquiry_id) {
            handle.abort();
        }

        // Look up pending bubble metadata.
        let forward = self.pending_bubbles.lock().await.remove(inquiry_id);
        let Some(forward) = forward else {
            tracing::warn!(inquiry_id, "Supervisor response for unknown inquiry");
            return;
        };

        // Update DB with forwarding chain.
        let chain: Vec<String> = {
            let mut c = forward.forwarding_chain.clone();
            c.push(responding_agent_key.to_string());
            c
        };
        let chain_json = serde_json::to_string(&chain).unwrap_or_default();
        let _ = self.workspace_dao.update_workspace_inquiry_response(
            inquiry_id,
            Some(response_text),
            response_suggestion_index,
            &crate::domain::enums::InquiryStatus::Responded,
        );
        let _ = self
            .workspace_dao
            .update_workspace_inquiry_forwarding_chain(inquiry_id, &chain_json);

        // Send InquiryResponse to origin agent via sendToHost (preserves instance_id).
        let response_pkg = Package::InquiryResponse(InquiryResponsePackage {
            instance_id: forward.origin_instance_id.clone(),
            inquiry_id: inquiry_id.to_string(),
            turn_id: None,
            response_text: Some(response_text.to_string()),
            response_suggestion_index,
        });
        let sent = {
            let sth = self.send_to_host.lock().await;
            if let Some(ref sth) = *sth {
                sth(workspace_id, &forward.origin_agent_key, &response_pkg)
            } else {
                false
            }
        };

        if sent {
            let _ = self.workspace_dao.update_workspace_inquiry_status(
                inquiry_id,
                "delivered",
            );
        } else {
            tracing::warn!(
                origin_agent = forward.origin_agent_key.as_str(),
                inquiry_id,
                "Could not route inquiry response to origin agent"
            );
        }

        // Transition origin instance back to generating.
        self.try_status_transition_async(
            workspace_id,
            &forward.origin_agent_key,
            &forward.origin_instance_id,
            AgentState::Generating,
            "event-service",
        )
        .await;

        // Close spawned inquiry instance if any.
        if let Some(ref spawned_id) = forward.spawned_instance_id {
            self.close_spawned_inquiry_instance(
                &forward.workspace_id,
                &forward.current_supervisor_key,
                spawned_id,
            )
            .await;
        }

        // Table invalidation handles notification to consumers.
    }

    /// Cancels pending timer, closes spawned instance, re-calls
    /// `try_forward_to_supervisor` with updated chain.
    ///
    /// Returns a boxed future to break the async type cycle between
    /// `try_forward_to_supervisor` and this method (they call each other
    /// indirectly via `tokio::spawn`).
    pub fn handle_supervisor_bubble(
        self: &Arc<Self>,
        workspace_id: &str,
        inquiry_id: &str,
        bubbling_agent_key: &str,
    ) -> std::pin::Pin<Box<dyn std::future::Future<Output = ()> + Send + '_>> {
        let workspace_id = workspace_id.to_string();
        let inquiry_id = inquiry_id.to_string();
        let bubbling_agent_key = bubbling_agent_key.to_string();
        let this = Arc::clone(self);

        Box::pin(async move {
            // Cancel pending timer for this inquiry.
            if let Some(handle) = this.pending_timers.lock().await.remove(&inquiry_id) {
                handle.abort();
            }

            // Get bubble metadata.
            let forward = this.pending_bubbles.lock().await.remove(&inquiry_id);
            let Some(forward) = forward else {
                tracing::warn!(inquiry_id = inquiry_id.as_str(), "Supervisor bubble for unknown inquiry");
                return;
            };

            // Close spawned instance.
            if let Some(ref spawned_id) = forward.spawned_instance_id {
                this.close_spawned_inquiry_instance(
                    &forward.workspace_id,
                    &forward.current_supervisor_key,
                    spawned_id,
                )
                .await;
            }

            // Re-forward with updated chain.
            let mut new_chain = forward.forwarding_chain.clone();
            new_chain.push(bubbling_agent_key.to_string());

            this.try_forward_to_supervisor(
                &workspace_id,
                &inquiry_id,
                &forward.origin_agent_key,
                &forward.origin_instance_id,
                &bubbling_agent_key,
                &forward.event,
                new_chain,
            )
            .await;
        })
    }

    /// Spawn a dedicated supervisor instance to handle an inquiry.
    ///
    /// Opens a new instance on the supervisor's host, waits for it to become
    /// alive, creates the DB row, then sends the InquiryRequestPackage.
    /// Returns the spawned instance ID, or None if spawn/send failed.
    async fn open_inquiry_instance(
        &self,
        workspace_id: &str,
        supervisor_key: &str,
        forward_event: &InquiryRequestPackage,
    ) -> Option<String> {
        let host_connected = {
            let ihc = self.is_host_connected.lock().await;
            if let Some(ref ihc) = *ihc {
                ihc(workspace_id, supervisor_key)
            } else {
                false
            }
        };
        if !host_connected {
            tracing::warn!(
                supervisor_key,
                "Cannot spawn inquiry instance: host not connected"
            );
            return None;
        }

        let new_instance_id = new_id();
        tracing::info!(
            supervisor_key,
            instance_id = new_instance_id.as_str(),
            inquiry_id = forward_event.inquiry_id.as_str(),
            "Spawning inquiry-dedicated instance"
        );

        // Send SpawnInstance.
        let spawn_sent = {
            let sth = self.send_to_host.lock().await;
            if let Some(ref sth) = *sth {
                sth(
                    workspace_id,
                    supervisor_key,
                    &Package::SpawnInstance(SpawnInstancePackage {
                        instance_id: new_instance_id.clone(),
                    }),
                )
            } else {
                false
            }
        };
        if !spawn_sent {
            tracing::warn!(
                supervisor_key,
                instance_id = new_instance_id.as_str(),
                "Failed to send spawn_instance for inquiry instance"
            );
            return None;
        }

        // Track empty chain for inquiry-dedicated instances.
        self.instance_chains
            .lock()
            .await
            .insert(new_instance_id.clone(), vec![]);

        // Wait for instance to appear in heartbeat.
        self.wait_for_instance_alive(workspace_id, supervisor_key, &new_instance_id)
            .await;

        // Create DB row with the actual heartbeat-reported state.
        let live_state = {
            let gis = self.get_instance_state.lock().await;
            if let Some(ref gis) = *gis {
                gis(workspace_id, supervisor_key, &new_instance_id)
                    .and_then(|s| AgentState::from_wire(&s))
            } else {
                None
            }
        };
        self.create_instance_row(
            workspace_id,
            supervisor_key,
            &new_instance_id,
            live_state.unwrap_or(AgentState::Idle),
        )
        .await;

        // Send InquiryRequest to the spawned instance.
        let forwarded = {
            let sti = self.send_to_instance.lock().await;
            if let Some(ref sti) = *sti {
                sti(
                    workspace_id,
                    supervisor_key,
                    &new_instance_id,
                    &Package::InquiryRequest(forward_event.clone()),
                )
            } else {
                false
            }
        };
        if !forwarded {
            tracing::warn!(
                supervisor_key,
                instance_id = new_instance_id.as_str(),
                "Failed to send inquiry_request to spawned instance"
            );
            // Clean up the instance we just spawned.
            self.close_spawned_inquiry_instance(workspace_id, supervisor_key, &new_instance_id)
                .await;
            return None;
        }

        Some(new_instance_id)
    }

    /// Surface an inquiry to the user when no supervisor can handle it.
    async fn surface_to_user(
        &self,
        _workspace_id: &str,
        inquiry_id: &str,
        forwarding_chain: &[String],
        _priority: &WireInquiryPriority,
        _origin_agent_key: &str,
    ) {
        if !forwarding_chain.is_empty() {
            if let Ok(chain_json) = serde_json::to_string(forwarding_chain) {
                let _ = self
                    .workspace_dao
                    .update_workspace_inquiry_forwarding_chain(inquiry_id, &chain_json);
            }
        }

        // Table invalidation handles notification to consumers.
    }

    /// Walks chain links (BFS) to find supervisor's instance ID in the same
    /// conversation chain as the origin agent.
    async fn find_supervisor_instance_in_chain(
        &self,
        workspace_id: &str,
        supervisor_key: &str,
        origin_agent_key: &str,
    ) -> Option<String> {
        let links = self.links.lock().await;
        let mut visited = std::collections::HashSet::new();
        let mut queue = vec![origin_agent_key.to_string()];

        while let Some(current) = queue.first().cloned() {
            queue.remove(0);
            if visited.contains(&current) {
                continue;
            }
            visited.insert(current.clone());

            for link in links.values() {
                if link.workspace_id != workspace_id {
                    continue;
                }
                if link.target_agent != current {
                    continue;
                }
                // This link's caller is talking to `current`.
                if link.caller_agent == supervisor_key {
                    return link.caller_instance.clone();
                }
                // Continue tracing upward through callers.
                queue.push(link.caller_agent.clone());
            }
        }
        None
    }

    /// Sends TerminatePackage to close inquiry-spawned instances.
    async fn close_spawned_inquiry_instance(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
    ) {
        tracing::info!(
            agent_key,
            instance_id,
            "Closing inquiry-spawned instance"
        );
        let sth = self.send_to_host.lock().await;
        if let Some(ref sth) = *sth {
            let pkg = Package::Terminate(TerminatePackage {
                instance_id: instance_id.to_string(),
            });
            sth(workspace_id, agent_key, &pkg);
        }
    }

    // ── Chain tracking ──

    async fn complete_link(
        &self,
        request_id: &str,
        result: TalkToResponsePackage,
    ) -> bool {
        let link = {
            let mut links = self.links.lock().await;
            match links.remove(request_id) {
                Some(l) => l,
                None => return false,
            }
        };

        // If no more pending links for caller, transition back to Generating.
        if let Some(ref caller_instance) = link.caller_instance {
            let has_more = {
                let links = self.links.lock().await;
                links.values().any(|l| {
                    l.workspace_id == link.workspace_id
                        && l.caller_instance.as_deref() == Some(caller_instance)
                })
            };
            if !has_more {
                self.try_status_transition_async(
                    &link.workspace_id,
                    &link.caller_agent,
                    caller_instance,
                    AgentState::Generating,
                    "complete_link",
                )
                .await;
            }
        }

        if let Some(sender) = link.sender {
            let _ = sender.send(result);
        }
        tracing::info!(
            caller = link.caller_agent.as_str(),
            target = link.target_agent.as_str(),
            request_id,
            "Chain link completed"
        );
        true
    }

    pub async fn fail_link(&self, request_id: &str, error: &str) {
        let link = {
            let mut links = self.links.lock().await;
            match links.remove(request_id) {
                Some(l) => l,
                None => return,
            }
        };

        // If no more pending links for caller, transition back to Generating.
        if let Some(ref caller_instance) = link.caller_instance {
            let has_more = {
                let links = self.links.lock().await;
                links.values().any(|l| {
                    l.workspace_id == link.workspace_id
                        && l.caller_instance.as_deref() == Some(caller_instance)
                })
            };
            if !has_more {
                self.try_status_transition_async(
                    &link.workspace_id,
                    &link.caller_agent,
                    caller_instance,
                    AgentState::Generating,
                    "fail_link",
                )
                .await;
            }
        }

        // Send RequestFailed to the caller.
        let event = RequestFailedPackage {
            instance_id: link.caller_instance.clone().unwrap_or_default(),
            request_id: request_id.to_string(),
            reason: error.to_string(),
        };

        self.send_to_caller(
            &link.workspace_id,
            &link.caller_agent,
            link.caller_instance.as_deref().unwrap_or(""),
            &Package::RequestFailed(event),
        )
        .await;

        // Drop the sender to signal cancellation to the receiver.
        drop(link.sender);

        tracing::info!(
            caller = link.caller_agent.as_str(),
            target = link.target_agent.as_str(),
            request_id,
            error,
            "Chain link failed"
        );
    }

    /// Detect if adding a talk_to would create a cycle.
    pub fn detect_cycle(
        target_agent: &str,
        _caller_agent: &str,
        chain: &[String],
    ) -> Option<String> {
        if chain.iter().any(|a| a == target_agent) {
            let mut path = chain.to_vec();
            path.push(_caller_agent.to_string());
            path.push(target_agent.to_string());
            Some(format!(
                "Cyclic talk_to rejected: {}",
                path.join(" \u{2192} ")
            ))
        } else {
            None
        }
    }

    /// Called when a specific instance disappears from heartbeat.
    pub async fn on_instance_gone(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
    ) {
        // Fail links where this instance is the target or caller.
        let to_fail: Vec<String> = {
            let links = self.links.lock().await;
            links
                .iter()
                .filter(|(_, link)| {
                    link.workspace_id == workspace_id
                        && (link.target_agent == agent_key
                            || link.caller_instance.as_deref() == Some(instance_id))
                })
                .map(|(id, _)| id.clone())
                .collect()
        };
        for request_id in &to_fail {
            self.fail_link(
                request_id,
                &format!(
                    "Instance \"{}\" ({}) is gone.",
                    instance_id, agent_key
                ),
            )
            .await;
        }

        self.instance_chains.lock().await.remove(instance_id);
        self.conversation_instances
            .lock()
            .await
            .retain(|_, v| v != instance_id);
    }

    /// Called when an agent disconnects.
    pub async fn on_agent_disconnected(
        &self,
        workspace_id: &str,
        agent_key: &str,
    ) {
        let to_fail: Vec<String> = {
            let links = self.links.lock().await;
            links
                .iter()
                .filter(|(_, link)| {
                    link.workspace_id == workspace_id
                        && (link.target_agent == agent_key
                            || link.caller_agent == agent_key)
                })
                .map(|(id, _)| id.clone())
                .collect()
        };
        for request_id in &to_fail {
            self.fail_link(
                request_id,
                &format!(
                    "Agent \"{}\" disconnected while processing request.",
                    agent_key
                ),
            )
            .await;
        }

        // Clean up conversation instances.
        let mut conv = self.conversation_instances.lock().await;
        let mut chains = self.instance_chains.lock().await;
        conv.retain(|k, instance_id| {
            if k.0 == workspace_id && k.2 == agent_key {
                chains.remove(instance_id);
                false
            } else {
                true
            }
        });
    }

    // ── Internal helpers ──

    /// Spawns a new instance, waits for it to appear in heartbeat, creates
    /// the DB row, and persists chain data. Returns the new instance ID.
    async fn open_new_instance(
        &self,
        workspace_id: &str,
        target_agent: &str,
        conv_key: &(String, String, String),
        extended_chain: &[String],
    ) -> String {
        let new_id = new_id();
        let sth = self.send_to_host.lock().await;
        if let Some(ref sth) = *sth {
            let spawn_pkg = Package::SpawnInstance(SpawnInstancePackage {
                instance_id: new_id.clone(),
            });
            sth(workspace_id, target_agent, &spawn_pkg);
        }
        drop(sth);

        // Wait for instance alive.
        self.wait_for_instance_alive(workspace_id, target_agent, &new_id)
            .await;

        // Create DB row.
        self.create_instance_row(workspace_id, target_agent, &new_id, AgentState::Idle)
            .await;

        // Persist chain.
        self.instance_chains
            .lock()
            .await
            .insert(new_id.clone(), extended_chain.to_vec());
        self.conversation_instances
            .lock()
            .await
            .insert(conv_key.clone(), new_id.clone());

        // Persist chain_json to DB.
        if let Ok(chain_json) = serde_json::to_string(extended_chain) {
            let _ = self.workspace_dao.update_agent_chain_json(&new_id, &chain_json);
        }

        new_id
    }

    /// Poll loop (250ms interval, 30s timeout) until instance appears in
    /// heartbeat state.
    async fn wait_for_instance_alive(
        &self,
        workspace_id: &str,
        agent_name: &str,
        instance_id: &str,
    ) {
        let iic = self.is_instance_connected.lock().await.clone();
        Self::poll_instance_alive(&iic, workspace_id, agent_name, instance_id, Duration::from_secs(30)).await;
    }

    /// Poll loop (250ms interval, 15s timeout) until instance disappears
    /// from heartbeat state.
    async fn wait_for_instance_gone(
        &self,
        workspace_id: &str,
        agent_name: &str,
        instance_id: &str,
    ) {
        let timeout = Duration::from_secs(15);
        let interval = Duration::from_millis(250);
        let deadline = tokio::time::Instant::now() + timeout;

        loop {
            let is_connected = {
                let iic = self.is_instance_connected.lock().await;
                if let Some(ref iic) = *iic {
                    iic(workspace_id, agent_name, instance_id)
                } else {
                    false
                }
            };
            if !is_connected {
                return;
            }
            if tokio::time::Instant::now() >= deadline {
                tracing::warn!(
                    instance_id,
                    "Timed out waiting for instance gone"
                );
                return;
            }
            tokio::time::sleep(interval).await;
        }
    }

    /// Shared polling logic for waiting until an instance is alive.
    async fn poll_instance_alive(
        iic: &Option<IsInstanceConnectedFn>,
        workspace_id: &str,
        agent_name: &str,
        instance_id: &str,
        timeout: Duration,
    ) {
        let interval = Duration::from_millis(250);
        let deadline = tokio::time::Instant::now() + timeout;

        loop {
            let is_connected = {
                if let Some(ref iic) = iic {
                    iic(workspace_id, agent_name, instance_id)
                } else {
                    false
                }
            };
            if is_connected {
                return;
            }
            if tokio::time::Instant::now() >= deadline {
                tracing::warn!(
                    instance_id,
                    "Timed out waiting for instance alive"
                );
                return;
            }
            tokio::time::sleep(interval).await;
        }
    }

    /// Creates a WorkspaceAgent DB row with generated display name and status.
    ///
    /// Idempotent — skips insertion if a row for this instance_id already exists.
    pub async fn create_instance_row(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
        initial_state: AgentState,
    ) {
        let run_id = match self.active_run_id(workspace_id) {
            Some(id) => id,
            None => return,
        };

        // Skip if a row already exists (race between heartbeat and spawn).
        if let Ok(Some(_)) = self.workspace_dao.find_workspace_agent_by_instance_id(&run_id, instance_id) {
            return;
        }

        // Generate a short 4-char hex display name.
        let display_name = format!("{:04x}", rand::random::<u16>());

        let now = chrono::Utc::now().naive_utc();
        let agent = WorkspaceAgent {
            id: new_id(),
            run_id,
            agent_key: agent_key.to_string(),
            instance_id: instance_id.to_string(),
            display_name,
            chain_json: String::new(),
            status: initial_state,
            created_at: now,
            updated_at: now,
        };
        let _ = self.workspace_dao.insert_workspace_agent(&agent);
        // Table invalidation handles notification to consumers.
    }

    /// Helper to call try_status_transition delegate.
    async fn try_status_transition_async(
        &self,
        workspace_id: &str,
        agent_key: &str,
        instance_id: &str,
        new_status: AgentState,
        tag: &str,
    ) {
        let tst = self.try_status_transition.lock().await;
        if let Some(ref tst) = *tst {
            let handle = tst(
                workspace_id.to_string(),
                agent_key.to_string(),
                instance_id.to_string(),
                new_status,
                tag.to_string(),
            );
            let _ = handle.await;
        }
    }

    async fn send_to_caller(
        &self,
        workspace_id: &str,
        caller_agent: &str,
        caller_instance: &str,
        event: &Package,
    ) {
        if !caller_instance.is_empty() {
            let sti = self.send_to_instance.lock().await;
            if let Some(ref sti) = *sti {
                sti(workspace_id, caller_agent, caller_instance, event);
            }
        } else {
            let sth = self.send_to_host.lock().await;
            if let Some(ref sth) = *sth {
                sth(workspace_id, caller_agent, event);
            }
        }
    }

    async fn send_request_failed(
        &self,
        workspace_id: &str,
        caller_agent: &str,
        caller_instance: &str,
        event: &RequestFailedPackage,
    ) {
        tracing::info!(
            caller_agent,
            request_id = event.request_id.as_str(),
            reason = event.reason.as_str(),
            "Sending request_failed"
        );
        self.send_to_caller(
            workspace_id,
            caller_agent,
            caller_instance,
            &Package::RequestFailed(event.clone()),
        )
        .await;
    }

    async fn send_chain_heartbeats(&self) {
        // Collect link data first, then release the lock before iterating.
        let link_data: Vec<(String, Option<String>, String, String)> = {
            let links = self.links.lock().await;
            links.values().map(|l| {
                (l.request_id.clone(), l.caller_instance.clone(), l.caller_agent.clone(), l.workspace_id.clone())
            }).collect()
        };

        for (request_id, caller_instance, caller_agent, workspace_id) in &link_data {
            let event = Package::RequestAlive(RequestAlivePackage {
                instance_id: caller_instance.clone().unwrap_or_default(),
                request_id: request_id.clone(),
            });

            if let Some(ref ci) = caller_instance {
                let sti = self.send_to_instance.lock().await;
                if let Some(ref sti) = *sti {
                    sti(workspace_id, caller_agent, ci, &event);
                }
            } else {
                let sth = self.send_to_host.lock().await;
                if let Some(ref sth) = *sth {
                    sth(workspace_id, caller_agent, &event);
                }
            }
        }

        // Collect bubble data first, then release the lock before iterating.
        let bubble_data: Vec<(String, String, String, String)> = {
            let bubbles = self.pending_bubbles.lock().await;
            bubbles.values().map(|b| {
                (b.workspace_id.clone(), b.origin_agent_key.clone(), b.origin_instance_id.clone(), b.inquiry_id.clone())
            }).collect()
        };

        for (workspace_id, origin_agent_key, origin_instance_id, inquiry_id) in &bubble_data {
            let event = Package::InquiryAlive(InquiryAlivePackage {
                instance_id: origin_instance_id.clone(),
                inquiry_id: inquiry_id.clone(),
            });
            let sti = self.send_to_instance.lock().await;
            if let Some(ref sti) = *sti {
                sti(
                    workspace_id,
                    origin_agent_key,
                    origin_instance_id,
                    &event,
                );
            }
        }
    }
}
