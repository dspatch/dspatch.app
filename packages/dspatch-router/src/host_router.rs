//! Host Router — central routing authority inside the container.
//!
//! Ported from: `app/packages/dspatch_engine/src/server/event.rs` `EventService`
//!
//! Responsibilities:
//! - Cross-agent `talk_to` routing with chain tracking
//! - Conversation chain management (reuse instances for continue_conversation)
//! - Cycle detection (prevents infinite agent loops)
//! - Inquiry bubbling through supervisor hierarchy
//! - Spawn decisions
//! - Engine relay (via WAL + WebSocket)

use crate::agent_host::AgentHostRouter;
use crate::config::AgentMeta;
use crate::instance_router::FeedItem;
use crate::wire::{HeartbeatInstance, WirePackage};
use parking_lot::Mutex;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};

// ── Chain tracking ───────────────────────────────────────────────────────

#[derive(Debug)]
struct ChainLink {
    request_id: String,
    caller_agent: String,
    caller_instance: String,
    target_agent: String,
    chain: Vec<String>,
    response_tx: Option<oneshot::Sender<serde_json::Value>>,
}

#[derive(Debug)]
struct PendingInquiryBubble {
    inquiry_id: String,
    origin_agent_key: String,
    origin_instance_id: String,
    current_supervisor_key: String,
    event: serde_json::Value,
    forwarding_chain: Vec<String>,
}

pub struct HostRouter {
    agents_meta: HashMap<String, AgentMeta>,
    agent_hosts: Mutex<HashMap<String, Arc<AgentHostRouter>>>,
    chain_links: Mutex<HashMap<String, ChainLink>>,
    instance_chains: Mutex<HashMap<String, Vec<String>>>,
    conversation_instances: Mutex<HashMap<(String, String), String>>,
    hierarchy: HashMap<String, Option<String>>,
    pending_bubbles: Mutex<HashMap<String, PendingInquiryBubble>>,
    engine_tx: Mutex<Option<mpsc::Sender<WirePackage>>>,
}

impl HostRouter {
    pub fn new(agents_meta: HashMap<String, AgentMeta>) -> Self {
        let root_keys: Vec<String> = agents_meta
            .iter()
            .filter(|(_, m)| m.is_root)
            .map(|(k, _)| k.clone())
            .collect();
        let root = root_keys.first().cloned();

        let hierarchy: HashMap<String, Option<String>> = agents_meta
            .keys()
            .map(|k| {
                let supervisor = if agents_meta[k].is_root {
                    None
                } else {
                    root.clone()
                };
                (k.clone(), supervisor)
            })
            .collect();

        Self {
            agents_meta,
            agent_hosts: Mutex::new(HashMap::new()),
            chain_links: Mutex::new(HashMap::new()),
            instance_chains: Mutex::new(HashMap::new()),
            conversation_instances: Mutex::new(HashMap::new()),
            hierarchy,
            pending_bubbles: Mutex::new(HashMap::new()),
            engine_tx: Mutex::new(None),
        }
    }

    pub fn set_engine_tx(&self, tx: mpsc::Sender<WirePackage>) {
        *self.engine_tx.lock() = Some(tx);
    }

    // ── Instance management ──────────────────────────────────────────

    pub fn spawn_instance(
        &self,
        agent_key: &str,
        instance_id: &str,
        history: Vec<serde_json::Value>,
    ) {
        let mut hosts = self.agent_hosts.lock();
        let host = hosts
            .entry(agent_key.to_string())
            .or_insert_with(|| Arc::new(AgentHostRouter::new(agent_key.to_string())));
        host.spawn_instance(instance_id.to_string(), history);
    }

    pub fn instance_exists(&self, instance_id: &str) -> bool {
        let hosts = self.agent_hosts.lock();
        hosts.values().any(|h| h.instance_state(instance_id).is_some())
    }

    pub fn agent_key_for_instance(&self, instance_id: &str) -> Option<String> {
        let hosts = self.agent_hosts.lock();
        for (key, host) in hosts.iter() {
            if host.instance_state(instance_id).is_some() {
                return Some(key.clone());
            }
        }
        None
    }

    pub async fn take_feed_item(&self, instance_id: &str) -> Option<FeedItem> {
        let host = {
            let hosts = self.agent_hosts.lock();
            hosts.values().find(|h| h.instance_state(instance_id).is_some()).cloned()
        };
        match host {
            Some(h) => h.take_feed_item(instance_id).await,
            None => None,
        }
    }

    pub fn get_instance_router(
        &self,
        instance_id: &str,
    ) -> Option<Arc<crate::instance_router::InstanceRouter>> {
        let hosts = self.agent_hosts.lock();
        for host in hosts.values() {
            if let Some(router) = host.get_instance_router(instance_id) {
                return Some(router);
            }
        }
        None
    }

    // ── Inbound routing from engine ──────────────────────────────────

    pub fn route_from_engine(&self, event: serde_json::Value) {
        let pkg_type = event.get("type").and_then(|t| t.as_str()).unwrap_or("");
        let instance_id = event.get("instance_id").and_then(|v| v.as_str()).unwrap_or("");

        match pkg_type {
            "connection.spawn_instance" => {
                let agent_key = event.get("agent_key").and_then(|v| v.as_str()).unwrap_or("");
                let history = event.get("history").and_then(|v| v.as_array()).cloned().unwrap_or_default();
                self.spawn_instance(agent_key, instance_id, history);
                self.send_to_engine(WirePackage::instance_spawned(agent_key, instance_id));
            }
            _ if pkg_type.starts_with("agent.") => {
                let hosts = self.agent_hosts.lock();
                for host in hosts.values() {
                    if host.instance_state(instance_id).is_some() {
                        host.dispatch(event);
                        return;
                    }
                }
                tracing::warn!(instance = %instance_id, "No agent host found for instance");
            }
            _ => {
                tracing::debug!(pkg_type = %pkg_type, "Ignoring unrecognized package from engine");
            }
        }
    }

    // ── Chain tracking & cycle detection ─────────────────────────────

    pub fn add_chain_link(
        &self,
        request_id: &str,
        caller_agent: &str,
        caller_instance: &str,
        target_agent: &str,
        chain: Vec<String>,
    ) {
        self.chain_links.lock().insert(
            request_id.to_string(),
            ChainLink {
                request_id: request_id.to_string(),
                caller_agent: caller_agent.to_string(),
                caller_instance: caller_instance.to_string(),
                target_agent: target_agent.to_string(),
                chain,
                response_tx: None,
            },
        );
        self.instance_chains
            .lock()
            .entry(caller_instance.to_string())
            .or_default()
            .push(request_id.to_string());
    }

    pub fn has_active_chain(&self, instance_id: &str) -> bool {
        self.instance_chains
            .lock()
            .get(instance_id)
            .map_or(false, |chains| !chains.is_empty())
    }

    pub fn would_create_cycle(&self, caller_instance_id: &str, target_agent: &str) -> bool {
        // Collect chain info first, then release locks before calling agent_key_for_instance
        let mut visited_agents: Vec<String> = Vec::new();

        let caller_agent = self.agent_key_for_instance(caller_instance_id);

        {
            let chains = self.instance_chains.lock();
            let links = self.chain_links.lock();

            // Check chains originating from this instance
            if let Some(chain_ids) = chains.get(caller_instance_id) {
                for chain_id in chain_ids {
                    if let Some(link) = links.get(chain_id) {
                        visited_agents.extend(link.chain.clone());
                    }
                }
            }

            // Also check any chain that targets the caller's agent — the caller
            // is being invoked as part of that chain, so all agents in that chain
            // are ancestors and must not be called again.
            if let Some(ref caller_key) = caller_agent {
                for link in links.values() {
                    if link.target_agent == *caller_key {
                        visited_agents.extend(link.chain.clone());
                    }
                }
            }
        }

        if let Some(agent_key) = caller_agent {
            visited_agents.push(agent_key);
        }

        visited_agents.contains(&target_agent.to_string())
    }

    pub async fn initiate_talk_to(
        &self,
        caller_instance_id: &str,
        target_agent: &str,
        text: &str,
        continue_conversation: bool,
    ) -> Result<(String, oneshot::Receiver<serde_json::Value>), String> {
        if self.would_create_cycle(caller_instance_id, target_agent) {
            return Err("cycle_detected".into());
        }

        let caller_agent = self
            .agent_key_for_instance(caller_instance_id)
            .ok_or("caller_not_found")?;

        let request_id = uuid::Uuid::new_v4().to_string();
        let chain = {
            let links = self.chain_links.lock();
            let chains = self.instance_chains.lock();
            let mut agent_chain = vec![caller_agent.clone()];
            if let Some(chain_ids) = chains.get(caller_instance_id) {
                for cid in chain_ids {
                    if let Some(link) = links.get(cid) {
                        agent_chain.extend(link.chain.clone());
                    }
                }
            }
            agent_chain
        };

        let (tx, rx) = oneshot::channel();

        self.chain_links.lock().insert(
            request_id.clone(),
            ChainLink {
                request_id: request_id.clone(),
                caller_agent: caller_agent.clone(),
                caller_instance: caller_instance_id.to_string(),
                target_agent: target_agent.to_string(),
                chain,
                response_tx: Some(tx),
            },
        );
        self.instance_chains
            .lock()
            .entry(caller_instance_id.to_string())
            .or_default()
            .push(request_id.clone());
        let request_id_ret = request_id.clone();

        let target_instance = if continue_conversation {
            let key = (caller_instance_id.to_string(), target_agent.to_string());
            self.conversation_instances.lock().get(&key).cloned()
        } else {
            None
        };

        let target_instance = match target_instance {
            Some(id) => id,
            None => {
                let hosts = self.agent_hosts.lock();
                if let Some(host) = hosts.get(target_agent) {
                    let ids = host.instance_ids();
                    ids.first().cloned().unwrap_or_else(|| {
                        format!("{}-0", target_agent)
                    })
                } else {
                    format!("{}-0", target_agent)
                }
            }
        };

        self.conversation_instances.lock().insert(
            (caller_instance_id.to_string(), target_agent.to_string()),
            target_instance.clone(),
        );

        let talk_to_event = serde_json::json!({
            "type": "agent.event.talk_to.request",
            "instance_id": target_instance,
            "request_id": request_id,
            "caller_agent": caller_agent,
            "text": text,
        });

        let hosts = self.agent_hosts.lock();
        if let Some(host) = hosts.get(target_agent) {
            host.dispatch(talk_to_event);
        }

        Ok((request_id_ret, rx))
    }

    pub async fn initiate_inquiry(
        &self,
        instance_id: &str,
        inquiry_id: &str,
        content_markdown: &str,
        suggestions: &[String],
        file_paths: &[String],
        priority: &str,
    ) -> oneshot::Receiver<serde_json::Value> {
        let (_tx, rx) = oneshot::channel();

        self.pending_bubbles.lock().insert(inquiry_id.to_string(), PendingInquiryBubble {
            inquiry_id: inquiry_id.to_string(),
            origin_agent_key: self.agent_key_for_instance(instance_id).unwrap_or_default(),
            origin_instance_id: instance_id.to_string(),
            current_supervisor_key: String::new(),
            event: serde_json::json!({
                "type": "agent.event.inquiry.request",
                "instance_id": instance_id,
                "inquiry_id": inquiry_id,
                "content_markdown": content_markdown,
                "suggestions": suggestions,
                "file_paths": file_paths,
                "priority": priority,
            }),
            forwarding_chain: vec![],
        });

        let agent_key = self.agent_key_for_instance(instance_id).unwrap_or_default();
        if let Some(supervisor) = self.supervisor_for(&agent_key) {
            let hosts = self.agent_hosts.lock();
            if let Some(host) = hosts.get(&supervisor) {
                let ids = host.instance_ids();
                if let Some(sup_instance) = ids.first() {
                    let inq_event = serde_json::json!({
                        "type": "agent.event.inquiry.request",
                        "instance_id": sup_instance,
                        "inquiry_id": inquiry_id,
                        "from_agent": agent_key,
                        "content_markdown": content_markdown,
                        "suggestions": suggestions,
                        "priority": priority,
                    });
                    host.dispatch(inq_event);
                    return rx;
                }
            }
        }

        let pkg = serde_json::json!({
            "type": "agent.event.inquiry.request",
            "instance_id": instance_id,
            "inquiry_id": inquiry_id,
            "content_markdown": content_markdown,
            "suggestions": suggestions,
            "file_paths": file_paths,
            "priority": priority,
        });
        self.relay_output(pkg);
        rx
    }

    pub async fn resume_wait(
        &self,
        _instance_id: &str,
        request_id: &str,
    ) -> Result<serde_json::Value, String> {
        let (tx, rx) = oneshot::channel();

        if let Some(link) = self.chain_links.lock().get_mut(request_id) {
            link.response_tx = Some(tx);
        } else {
            return Err("no_pending_request".into());
        }

        rx.await.map_err(|_| "channel_closed".into())
    }

    pub fn resolve_talk_to(&self, request_id: &str, response: serde_json::Value) {
        if let Some(link) = self.chain_links.lock().remove(request_id) {
            if let Some(chains) = self.instance_chains.lock().get_mut(&link.caller_instance) {
                chains.retain(|id| id != request_id);
            }
            if let Some(tx) = link.response_tx {
                let _ = tx.send(response);
            }
        }
    }

    // ── Inquiry bubbling ─────────────────────────────────────────────

    pub fn supervisor_for(&self, agent_key: &str) -> Option<String> {
        self.hierarchy.get(agent_key).and_then(|s| s.clone())
    }

    pub fn register_pending_inquiry(
        &self,
        inquiry_id: &str,
        agent_key: &str,
        instance_id: &str,
    ) {
        self.pending_bubbles.lock().insert(inquiry_id.to_string(), PendingInquiryBubble {
            inquiry_id: inquiry_id.to_string(),
            origin_agent_key: agent_key.to_string(),
            origin_instance_id: instance_id.to_string(),
            current_supervisor_key: String::new(),
            event: serde_json::json!({
                "type": "agent.event.inquiry.request",
                "inquiry_id": inquiry_id,
                "instance_id": instance_id,
            }),
            forwarding_chain: vec![],
        });
    }

    pub fn resolve_inquiry(&self, inquiry_id: &str, _response: serde_json::Value) -> bool {
        self.pending_bubbles.lock().remove(inquiry_id).is_some()
    }

    // ── Heartbeat ────────────────────────────────────────────────────

    pub fn collect_heartbeat(&self) -> Vec<HeartbeatInstance> {
        let hosts = self.agent_hosts.lock();
        let mut all = Vec::new();
        for host in hosts.values() {
            all.extend(host.collect_heartbeat());
        }
        all
    }

    /// Send RequestAlive heartbeats to all active chain links.
    pub fn send_chain_heartbeats(&self) {
        let links = self.chain_links.lock();
        for (request_id, link) in links.iter() {
            let alive_pkg = serde_json::json!({
                "type": "agent.event.request.alive",
                "instance_id": &link.caller_instance,
                "request_id": request_id,
            });
            let hosts = self.agent_hosts.lock();
            for host in hosts.values() {
                if host.instance_state(&link.caller_instance).is_some() {
                    host.dispatch(alive_pkg.clone());
                    break;
                }
            }
        }
    }

    // ── Engine relay ─────────────────────────────────────────────────

    pub fn send_to_engine(&self, pkg: WirePackage) {
        if let Some(tx) = self.engine_tx.lock().as_ref() {
            if tx.try_send(pkg).is_err() {
                tracing::warn!("Engine channel full, package dropped");
            }
        }
    }

    pub fn relay_output(&self, event: serde_json::Value) {
        if let Ok(pkg) = WirePackage::from_json(event) {
            self.send_to_engine(pkg);
        }
    }
}
