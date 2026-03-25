//! Agent Host Router — per-agent-type dispatch, heartbeat aggregation, instance lifecycle.
//!
//! Ported from: `packages/agent-sdk/sdk.python/dspatch/host.py` `AgentHostRouter`

use crate::instance_router::{FeedItem, InstanceRouter, InstanceState};
use crate::wire::HeartbeatInstance;
use parking_lot::Mutex;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::mpsc;

struct InstanceHandle {
    router: Arc<InstanceRouter>,
    feed_rx: tokio::sync::Mutex<mpsc::Receiver<FeedItem>>,
}

pub struct AgentHostRouter {
    agent_key: String,
    instances: Mutex<HashMap<String, Arc<InstanceHandle>>>,
}

impl AgentHostRouter {
    pub fn new(agent_key: String) -> Self {
        Self {
            agent_key,
            instances: Mutex::new(HashMap::new()),
        }
    }

    pub fn agent_key(&self) -> &str {
        &self.agent_key
    }

    pub fn instance_count(&self) -> usize {
        self.instances.lock().len()
    }

    pub fn instance_state(&self, instance_id: &str) -> Option<InstanceState> {
        self.instances
            .lock()
            .get(instance_id)
            .map(|h| h.router.state_machine().lock().state())
    }

    pub fn spawn_instance(&self, instance_id: String, _history: Vec<serde_json::Value>) {
        let (router, feed_rx) = InstanceRouter::new(instance_id.clone());
        let handle = Arc::new(InstanceHandle {
            router: Arc::new(router),
            feed_rx: tokio::sync::Mutex::new(feed_rx),
        });
        self.instances.lock().insert(instance_id, handle);
    }

    pub fn kill_instance(&self, instance_id: &str) {
        self.instances.lock().remove(instance_id);
    }

    pub fn dispatch(&self, event: serde_json::Value) {
        let instance_id = event
            .get("instance_id")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        let handle = self.instances.lock().get(instance_id).cloned();
        if let Some(handle) = handle {
            handle.router.receive(event);
        } else {
            tracing::warn!(
                agent = %self.agent_key,
                instance = %instance_id,
                "Dispatch to unknown instance"
            );
        }
    }

    pub fn get_instance_router(&self, instance_id: &str) -> Option<Arc<InstanceRouter>> {
        self.instances
            .lock()
            .get(instance_id)
            .map(|h| h.router.clone())
    }

    pub async fn take_feed_item(&self, instance_id: &str) -> Option<FeedItem> {
        // Clone the Arc so we don't hold the Mutex across an await point.
        let handle = self.instances.lock().get(instance_id).cloned();
        match handle {
            Some(h) => {
                // Lock the receiver, pull one item, then drop the guard.
                h.feed_rx.lock().await.recv().await
            }
            None => None,
        }
    }

    pub fn collect_heartbeat(&self) -> Vec<HeartbeatInstance> {
        self.instances
            .lock()
            .iter()
            .map(|(id, h)| HeartbeatInstance {
                instance_id: id.clone(),
                state: h.router.state_machine().lock().state().as_str().to_string(),
            })
            .collect()
    }

    pub fn instance_ids(&self) -> Vec<String> {
        self.instances.lock().keys().cloned().collect()
    }
}
