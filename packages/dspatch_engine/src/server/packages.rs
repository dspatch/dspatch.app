// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Unified Package hierarchy for the dspatch WebSocket wire protocol.
//!
//! Every WebSocket message is a [`Package`] variant. The `type` string
//! determines the package category via its prefix:
//!   - `agent.output.*`  -> OutputPackage structs
//!   - `agent.event.*`   -> EventPackage structs
//!   - `agent.signal.*`  -> SignalPackage structs
//!   - `connection.*`    -> ConnectionPackage structs

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::domain::enums::{AgentState, LogLevel};

// ── Wire-only enums ─────────────────────────────────────────────────

/// Role of a message on the wire protocol.
/// Note: the domain `MessageRole` may differ; this is the wire representation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MessageRole {
    Assistant,
    User,
    Tool,
}

impl Default for MessageRole {
    fn default() -> Self {
        Self::Assistant
    }
}

/// Inquiry priority on the wire protocol.
/// Note: the wire version includes `urgent`, which the domain enum may not have.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum WireInquiryPriority {
    Normal,
    High,
    Urgent,
}

impl Default for WireInquiryPriority {
    fn default() -> Self {
        Self::Normal
    }
}

// ── Package enum ────────────────────────────────────────────────────

/// The top-level wire protocol package.
///
/// Serialization uses the `type` field as a tag to determine the variant.
/// Deserialization falls back to [`Package::Unknown`] for unrecognized types.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum Package {
    // -- Output packages (6) --
    #[serde(rename = "agent.output.message")]
    Message(MessagePackage),

    #[serde(rename = "agent.output.activity")]
    Activity(ActivityPackage),

    #[serde(rename = "agent.output.log")]
    Log(LogPackage),

    #[serde(rename = "agent.output.usage")]
    Usage(UsagePackage),

    #[serde(rename = "agent.output.files")]
    Files(FilesPackage),

    #[serde(rename = "agent.output.prompt_received")]
    PromptReceived(PromptReceivedPackage),

    // -- Event packages (9) --
    #[serde(rename = "agent.event.user_input")]
    UserInput(UserInputPackage),

    #[serde(rename = "agent.event.talk_to.request")]
    TalkToRequest(TalkToRequestPackage),

    #[serde(rename = "agent.event.talk_to.response")]
    TalkToResponse(TalkToResponsePackage),

    #[serde(rename = "agent.event.request.alive")]
    RequestAlive(RequestAlivePackage),

    #[serde(rename = "agent.event.request.failed")]
    RequestFailed(RequestFailedPackage),

    #[serde(rename = "agent.event.inquiry.request")]
    InquiryRequest(InquiryRequestPackage),

    #[serde(rename = "agent.event.inquiry.response")]
    InquiryResponse(InquiryResponsePackage),

    #[serde(rename = "agent.event.inquiry.alive")]
    InquiryAlive(InquiryAlivePackage),

    #[serde(rename = "agent.event.inquiry.failed")]
    InquiryFailed(InquiryFailedPackage),

    // -- Signal packages (6) --
    #[serde(rename = "agent.signal.drain")]
    Drain(DrainPackage),

    #[serde(rename = "agent.signal.terminate")]
    Terminate(TerminatePackage),

    #[serde(rename = "agent.signal.interrupt")]
    Interrupt(InterruptPackage),

    #[serde(rename = "agent.signal.state_query")]
    StateQuery(StateQueryPackage),

    #[serde(rename = "agent.signal.state_report")]
    StateReport(StateReportPackage),

    #[serde(rename = "agent.signal.instance_spawned")]
    InstanceSpawned(InstanceSpawnedPackage),

    // -- Connection packages (8) --
    #[serde(rename = "connection.auth")]
    Auth(AuthPackage),

    #[serde(rename = "connection.auth_ack")]
    AuthAck(AuthAckPackage),

    #[serde(rename = "connection.auth_error")]
    AuthError(AuthErrorPackage),

    #[serde(rename = "connection.register")]
    Register(RegisterPackage),

    #[serde(rename = "connection.heartbeat")]
    Heartbeat(HeartbeatPackage),

    #[serde(rename = "connection.spawn_instance")]
    SpawnInstance(SpawnInstancePackage),

    #[serde(rename = "connection.ack")]
    Ack(AckPackage),

    // -- Fallback --
    // Not deserializable via serde tag; handled by Package::from_json().
    #[serde(skip)]
    Unknown(UnknownPackage),
}

impl Package {
    /// Deserialize a package from a JSON string.
    ///
    /// Falls back to [`Package::Unknown`] for unrecognized `type` values,
    /// rather than returning an error.
    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        match serde_json::from_str::<Package>(json) {
            Ok(pkg) => Ok(pkg),
            Err(_) => {
                // Try to parse as a generic Value and extract the type
                let raw: serde_json::Value = serde_json::from_str(json)?;
                let raw_type = raw
                    .get("type")
                    .and_then(|t| t.as_str())
                    .unwrap_or("null")
                    .to_string();
                Ok(Package::Unknown(UnknownPackage { raw_type, raw }))
            }
        }
    }

    /// Serialize this package to a JSON string.
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        match self {
            Package::Unknown(u) => serde_json::to_string(&u.raw),
            other => serde_json::to_string(other),
        }
    }

    /// Returns `true` if this is an output package (`agent.output.*`).
    pub fn is_output(&self) -> bool {
        matches!(
            self,
            Package::Message(_)
                | Package::Activity(_)
                | Package::Log(_)
                | Package::Usage(_)
                | Package::Files(_)
                | Package::PromptReceived(_)
        )
    }

    /// Returns `true` if this is an event package (`agent.event.*`).
    pub fn is_event(&self) -> bool {
        matches!(
            self,
            Package::UserInput(_)
                | Package::TalkToRequest(_)
                | Package::TalkToResponse(_)
                | Package::RequestAlive(_)
                | Package::RequestFailed(_)
                | Package::InquiryRequest(_)
                | Package::InquiryResponse(_)
                | Package::InquiryAlive(_)
                | Package::InquiryFailed(_)
        )
    }

    /// Returns `true` if this is a signal package (`agent.signal.*`).
    pub fn is_signal(&self) -> bool {
        matches!(
            self,
            Package::Drain(_)
                | Package::Terminate(_)
                | Package::Interrupt(_)
                | Package::StateQuery(_)
                | Package::StateReport(_)
                | Package::InstanceSpawned(_)
        )
    }

    /// Returns `true` if this is a connection package (`connection.*`).
    pub fn is_connection(&self) -> bool {
        matches!(
            self,
            Package::Auth(_)
                | Package::AuthAck(_)
                | Package::AuthError(_)
                | Package::Register(_)
                | Package::Heartbeat(_)
                | Package::SpawnInstance(_)
                | Package::Ack(_)
        )
    }

    /// Returns the `instance_id` if this package carries one (agent packages
    /// and `SpawnInstance`).
    pub fn instance_id(&self) -> Option<&str> {
        match self {
            // Output
            Package::Message(p) => Some(&p.instance_id),
            Package::Activity(p) => Some(&p.instance_id),
            Package::Log(p) => Some(&p.instance_id),
            Package::Usage(p) => Some(&p.instance_id),
            Package::Files(p) => Some(&p.instance_id),
            Package::PromptReceived(p) => Some(&p.instance_id),
            // Event
            Package::UserInput(p) => Some(&p.instance_id),
            Package::TalkToRequest(p) => Some(&p.instance_id),
            Package::TalkToResponse(p) => Some(&p.instance_id),
            Package::RequestAlive(p) => Some(&p.instance_id),
            Package::RequestFailed(p) => Some(&p.instance_id),
            Package::InquiryRequest(p) => Some(&p.instance_id),
            Package::InquiryResponse(p) => Some(&p.instance_id),
            Package::InquiryAlive(p) => Some(&p.instance_id),
            Package::InquiryFailed(p) => Some(&p.instance_id),
            // Signal
            Package::Drain(p) => Some(&p.instance_id),
            Package::Terminate(p) => Some(&p.instance_id),
            Package::Interrupt(p) => Some(&p.instance_id),
            Package::StateQuery(p) => Some(&p.instance_id),
            Package::StateReport(p) => Some(&p.instance_id),
            Package::InstanceSpawned(p) => Some(&p.instance_id),
            // Connection (only SpawnInstance has instance_id)
            Package::SpawnInstance(p) => Some(&p.instance_id),
            Package::Auth(_)
            | Package::AuthAck(_)
            | Package::AuthError(_)
            | Package::Register(_)
            | Package::Heartbeat(_)
            | Package::Ack(_)
            | Package::Unknown(_) => None,
        }
    }

    /// Returns the wire type string for this package (e.g. `"agent.output.message"`).
    pub fn type_str(&self) -> &str {
        match self {
            Package::Message(_) => "agent.output.message",
            Package::Activity(_) => "agent.output.activity",
            Package::Log(_) => "agent.output.log",
            Package::Usage(_) => "agent.output.usage",
            Package::Files(_) => "agent.output.files",
            Package::PromptReceived(_) => "agent.output.prompt_received",
            Package::UserInput(_) => "agent.event.user_input",
            Package::TalkToRequest(_) => "agent.event.talk_to.request",
            Package::TalkToResponse(_) => "agent.event.talk_to.response",
            Package::RequestAlive(_) => "agent.event.request.alive",
            Package::RequestFailed(_) => "agent.event.request.failed",
            Package::InquiryRequest(_) => "agent.event.inquiry.request",
            Package::InquiryResponse(_) => "agent.event.inquiry.response",
            Package::InquiryAlive(_) => "agent.event.inquiry.alive",
            Package::InquiryFailed(_) => "agent.event.inquiry.failed",
            Package::Drain(_) => "agent.signal.drain",
            Package::Terminate(_) => "agent.signal.terminate",
            Package::Interrupt(_) => "agent.signal.interrupt",
            Package::StateQuery(_) => "agent.signal.state_query",
            Package::StateReport(_) => "agent.signal.state_report",
            Package::InstanceSpawned(_) => "agent.signal.instance_spawned",
            Package::Auth(_) => "connection.auth",
            Package::AuthAck(_) => "connection.auth_ack",
            Package::AuthError(_) => "connection.auth_error",
            Package::Register(_) => "connection.register",
            Package::Heartbeat(_) => "connection.heartbeat",
            Package::SpawnInstance(_) => "connection.spawn_instance",
            Package::Ack(_) => "connection.ack",
            Package::Unknown(u) => &u.raw_type,
        }
    }
}

// ── Output package structs (6) ──────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessagePackage {
    #[serde(default)]
    pub instance_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub ts: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,

    #[serde(default)]
    pub role: MessageRole,

    pub content: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_tokens: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub output_tokens: Option<i64>,

    #[serde(default)]
    pub is_delta: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub sender_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActivityPackage {
    #[serde(default)]
    pub instance_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub ts: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,

    pub event_type: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub content: Option<String>,

    #[serde(default)]
    pub is_delta: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogPackage {
    #[serde(default)]
    pub instance_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub ts: Option<i64>,

    pub level: LogLevel,

    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UsagePackage {
    #[serde(default)]
    pub instance_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub ts: Option<i64>,

    pub model: String,

    pub input_tokens: i64,

    pub output_tokens: i64,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_read_tokens: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_write_tokens: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub cost_usd: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FilesPackage {
    #[serde(default)]
    pub instance_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub ts: Option<i64>,

    pub files: Vec<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PromptReceivedPackage {
    #[serde(default)]
    pub instance_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub ts: Option<i64>,

    pub content: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub sender_name: Option<String>,
}

// ── Event package structs (9) ───────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserInputPackage {
    #[serde(default)]
    pub instance_id: String,

    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TalkToRequestPackage {
    #[serde(default)]
    pub instance_id: String,

    pub target_agent: String,

    pub text: String,

    pub request_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub caller_agent: Option<String>,

    #[serde(default)]
    pub continue_conversation: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TalkToResponsePackage {
    #[serde(default)]
    pub instance_id: String,

    pub request_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub response: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RequestAlivePackage {
    #[serde(default)]
    pub instance_id: String,

    pub request_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RequestFailedPackage {
    #[serde(default)]
    pub instance_id: String,

    pub request_id: String,

    pub reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InquiryRequestPackage {
    #[serde(default)]
    pub instance_id: String,

    pub content_markdown: String,

    pub inquiry_id: String,

    #[serde(default)]
    pub suggestions: Vec<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub file_paths: Option<Vec<String>>,

    #[serde(default)]
    pub priority: WireInquiryPriority,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InquiryResponsePackage {
    #[serde(default)]
    pub instance_id: String,

    pub inquiry_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_id: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub response_text: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub response_suggestion_index: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InquiryAlivePackage {
    #[serde(default)]
    pub instance_id: String,

    pub inquiry_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InquiryFailedPackage {
    #[serde(default)]
    pub instance_id: String,

    pub inquiry_id: String,

    pub reason: String,
}

// ── Signal package structs (5) ──────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DrainPackage {
    #[serde(default)]
    pub instance_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TerminatePackage {
    #[serde(default)]
    pub instance_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InterruptPackage {
    #[serde(default)]
    pub instance_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateQueryPackage {
    #[serde(default)]
    pub instance_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateReportPackage {
    #[serde(default)]
    pub instance_id: String,

    pub state: AgentState,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub instances: Option<HashMap<String, AgentState>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstanceSpawnedPackage {
    #[serde(default)]
    pub instance_id: String,
}

// ── Connection package structs (8) ──────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthPackage {
    pub api_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthAckPackage {}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthErrorPackage {
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegisterPackage {
    pub name: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub role: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub capabilities: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeartbeatPackage {
    pub instances: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpawnInstancePackage {
    #[serde(default)]
    pub instance_id: String,
}

/// Acknowledgement sent from engine to router after persisting a package.
/// Used by the router's WAL to truncate delivered entries.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AckPackage {
    pub sequence_number: u64,
}

// ── Unknown package (fallback) ──────────────────────────────────────

#[derive(Debug, Clone)]
pub struct UnknownPackage {
    pub raw_type: String,
    pub raw: serde_json::Value,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn message_role_default_is_assistant() {
        assert_eq!(MessageRole::default(), MessageRole::Assistant);
    }

    #[test]
    fn wire_inquiry_priority_default_is_normal() {
        assert_eq!(WireInquiryPriority::default(), WireInquiryPriority::Normal);
    }

    #[test]
    fn ack_package_roundtrip() {
        let pkg = Package::Ack(AckPackage {
            sequence_number: 42,
        });
        let json = pkg.to_json().unwrap();
        let parsed = Package::from_json(&json).unwrap();
        match parsed {
            Package::Ack(ack) => assert_eq!(ack.sequence_number, 42),
            _ => panic!("Expected Ack"),
        }
    }
}
