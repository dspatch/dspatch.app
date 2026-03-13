// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! JSON wire protocol types for the client API WebSocket.

use serde::{Deserialize, Serialize};

/// A frame sent from the client to the engine over WebSocket.
#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "type")]
pub enum ClientFrame {
    #[serde(rename = "command")]
    Command {
        id: String,
        method: String,
        #[serde(default)]
        params: serde_json::Value,
    },
}

/// A frame sent from the engine to the client over WebSocket.
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type")]
pub enum ServerFrame {
    #[serde(rename = "result")]
    Result {
        id: String,
        data: serde_json::Value,
    },

    #[serde(rename = "error")]
    Error {
        #[serde(skip_serializing_if = "Option::is_none")]
        id: Option<String>,
        code: String,
        message: String,
    },

    #[serde(rename = "invalidate")]
    Invalidate {
        tables: Vec<String>,
    },

    #[serde(rename = "event")]
    Event {
        name: String,
        data: serde_json::Value,
    },
}

impl ServerFrame {
    pub fn welcome() -> Self {
        Self::Event {
            name: "welcome".into(),
            data: serde_json::json!({
                "protocol_version": 1
            }),
        }
    }

    pub fn not_implemented(id: &str, method: &str) -> Self {
        Self::Error {
            id: Some(id.to_string()),
            code: "NOT_IMPLEMENTED".into(),
            message: format!("Command '{method}' is not yet implemented"),
        }
    }
}
