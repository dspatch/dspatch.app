//! Wire protocol package types for WebSocket communication with the engine.
//!
//! Based on `packages/dspatch_engine/dspatch/PACKAGES.md`.
//! The router treats most packages as opaque JSON — only inspecting
//! `type` and `instance_id` for routing decisions.

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone)]
pub struct WirePackage {
    inner: Value,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct HeartbeatInstance {
    pub instance_id: String,
    pub state: String,
}

impl WirePackage {
    pub fn from_json(json: Value) -> Result<Self, &'static str> {
        if json.get("type").is_none() {
            return Err("Missing 'type' field");
        }
        Ok(Self { inner: json })
    }

    pub fn to_json(&self) -> Value {
        self.inner.clone()
    }

    pub fn to_string(&self) -> String {
        self.inner.to_string()
    }

    pub fn package_type(&self) -> &str {
        self.inner["type"].as_str().unwrap_or("")
    }

    pub fn instance_id(&self) -> Option<&str> {
        self.inner.get("instance_id").and_then(|v| v.as_str())
    }

    pub fn is_output(&self) -> bool {
        self.package_type().starts_with("agent.output.")
    }

    pub fn is_event(&self) -> bool {
        self.package_type().starts_with("agent.event.")
    }

    pub fn is_signal(&self) -> bool {
        self.package_type().starts_with("agent.signal.")
    }

    pub fn is_connection(&self) -> bool {
        self.package_type().starts_with("connection.")
    }

    pub fn auth(api_key: &str) -> Self {
        Self {
            inner: serde_json::json!({
                "type": "connection.auth",
                "api_key": api_key,
            }),
        }
    }

    pub fn register(name: &str, role: &str) -> Self {
        Self {
            inner: serde_json::json!({
                "type": "connection.register",
                "name": name,
                "role": role,
            }),
        }
    }

    pub fn heartbeat(instances: Vec<HeartbeatInstance>) -> Self {
        Self {
            inner: serde_json::json!({
                "type": "connection.heartbeat",
                "instances": instances,
            }),
        }
    }

    pub fn state_report(instance_id: &str, state: &str) -> Self {
        Self {
            inner: serde_json::json!({
                "type": "agent.signal.state_report",
                "instance_id": instance_id,
                "state": state,
            }),
        }
    }

    pub fn instance_spawned(agent_key: &str, instance_id: &str) -> Self {
        Self {
            inner: serde_json::json!({
                "type": "agent.signal.instance_spawned",
                "instance_id": instance_id,
                "agent_key": agent_key,
            }),
        }
    }

    pub fn set_field(&mut self, key: &str, value: Value) {
        self.inner[key] = value;
    }
}
