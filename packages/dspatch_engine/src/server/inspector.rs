// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Dev-mode packet logging with ring buffer and roundtrip checking.
//!
//! Ported from `server/package_inspector.dart`.

use std::collections::HashMap;
use std::sync::Mutex;

use chrono::{DateTime, Utc};

use super::packages::Package;

/// Direction of a captured WebSocket frame.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PackageDirection {
    Sent,
    Received,
}

/// A single captured package frame with optional roundtrip check results.
#[derive(Debug, Clone)]
pub struct PackageLogEntry {
    pub timestamp: DateTime<Utc>,
    pub direction: PackageDirection,
    pub raw_json: String,
    pub roundtrip_mismatch: bool,
    pub roundtrip_json: Option<String>,
    pub error: Option<String>,
}

/// In-memory ring buffer that captures raw WebSocket frames for dev inspection.
///
/// All methods are safe to call from multiple threads. When `enabled` is
/// `false`, all logging methods are no-ops.
pub struct PackageInspectorService {
    max_entries: usize,
    enabled: bool,
    buffers: Mutex<HashMap<String, Vec<PackageLogEntry>>>,
    listeners: Mutex<Vec<Box<dyn Fn() + Send + Sync>>>,
}

impl PackageInspectorService {
    pub fn new(max_entries: usize, enabled: bool) -> Self {
        Self {
            max_entries,
            enabled,
            buffers: Mutex::new(HashMap::new()),
            listeners: Mutex::new(Vec::new()),
        }
    }

    /// Creates an inspector with default settings (5000 entries, disabled).
    pub fn default_disabled() -> Self {
        Self::new(5000, false)
    }

    /// Creates an enabled inspector (for testing).
    pub fn default_enabled() -> Self {
        Self::new(5000, true)
    }

    /// Whether this inspector is actively logging.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    pub fn add_listener<F: Fn() + Send + Sync + 'static>(&self, listener: F) {
        if let Ok(mut listeners) = self.listeners.lock() {
            listeners.push(Box::new(listener));
        }
    }

    fn notify_listeners(&self) {
        if let Ok(listeners) = self.listeners.lock() {
            for listener in listeners.iter() {
                listener();
            }
        }
    }

    /// Get all entries for a given run.
    pub fn entries_for_run(&self, run_id: &str) -> Vec<PackageLogEntry> {
        let buffers = self.buffers.lock().unwrap_or_else(|e| e.into_inner());
        buffers.get(run_id).cloned().unwrap_or_default()
    }

    /// Log an inbound (agent->host) raw JSON string.
    pub fn log_inbound(&self, run_id: &str, raw_json_string: &str) {
        if !self.enabled {
            return;
        }
        let entry = Self::build_entry(PackageDirection::Received, raw_json_string);
        self.append(run_id, entry);
    }

    /// Log an outbound (host->agent) JSON value.
    pub fn log_outbound(&self, run_id: &str, json: &serde_json::Value) {
        if !self.enabled {
            return;
        }
        let raw_string = serde_json::to_string(json).unwrap_or_default();
        let entry = Self::build_entry(PackageDirection::Sent, &raw_string);
        self.append(run_id, entry);
    }

    /// Log an outbound package that has already been serialized.
    pub fn log_outbound_str(&self, run_id: &str, raw_json_string: &str) {
        if !self.enabled {
            return;
        }
        let entry = Self::build_entry(PackageDirection::Sent, raw_json_string);
        self.append(run_id, entry);
    }

    /// Clear entries for a specific run (e.g. on deregister).
    pub fn clear_run(&self, run_id: &str) {
        let mut buffers = self.buffers.lock().unwrap_or_else(|e| e.into_inner());
        buffers.remove(run_id);
        drop(buffers);
        self.notify_listeners();
    }

    // -- Internal --

    fn build_entry(direction: PackageDirection, raw_string: &str) -> PackageLogEntry {
        let now = Utc::now();
        match Package::from_json(raw_string) {
            Ok(parsed) => {
                match parsed.to_json() {
                    Ok(roundtripped_str) => {
                        // Compare the raw and roundtripped JSON values.
                        let raw_val: serde_json::Value =
                            serde_json::from_str(raw_string).unwrap_or_default();
                        let roundtripped_val: serde_json::Value =
                            serde_json::from_str(&roundtripped_str).unwrap_or_default();
                        let mismatch = raw_val != roundtripped_val;
                        PackageLogEntry {
                            timestamp: now,
                            direction,
                            raw_json: raw_string.to_string(),
                            roundtrip_mismatch: mismatch,
                            roundtrip_json: if mismatch {
                                Some(roundtripped_str)
                            } else {
                                None
                            },
                            error: None,
                        }
                    }
                    Err(e) => PackageLogEntry {
                        timestamp: now,
                        direction,
                        raw_json: raw_string.to_string(),
                        roundtrip_mismatch: false,
                        roundtrip_json: None,
                        error: Some(e.to_string()),
                    },
                }
            }
            Err(e) => PackageLogEntry {
                timestamp: now,
                direction,
                raw_json: raw_string.to_string(),
                roundtrip_mismatch: false,
                roundtrip_json: None,
                error: Some(e.to_string()),
            },
        }
    }

    fn append(&self, run_id: &str, entry: PackageLogEntry) {
        let mut buffers = self.buffers.lock().unwrap_or_else(|e| e.into_inner());
        let buffer = buffers.entry(run_id.to_string()).or_default();
        buffer.push(entry);
        if buffer.len() > self.max_entries {
            let excess = buffer.len() - self.max_entries;
            buffer.drain(..excess);
        }
        drop(buffers);
        self.notify_listeners();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ring_buffer_respects_max_entries() {
        let inspector = PackageInspectorService::new(3, true);
        let run_id = "run-1";

        for i in 0..5 {
            let json = format!(r#"{{"type":"agent.output.log","instance_id":"i1","level":"info","message":"msg{}"}}"#, i);
            inspector.log_inbound(run_id, &json);
        }

        let entries = inspector.entries_for_run(run_id);
        assert_eq!(entries.len(), 3);
        // Should keep the last 3 entries (msg2, msg3, msg4)
        assert!(entries[0].raw_json.contains("msg2"));
        assert!(entries[1].raw_json.contains("msg3"));
        assert!(entries[2].raw_json.contains("msg4"));
    }

    #[test]
    fn disabled_inspector_does_not_log() {
        let inspector = PackageInspectorService::new(100, false);
        inspector.log_inbound("run-1", r#"{"type":"connection.auth","api_key":"key"}"#);
        assert!(inspector.entries_for_run("run-1").is_empty());
    }

    #[test]
    fn roundtrip_check_detects_mismatch() {
        let inspector = PackageInspectorService::new(100, true);
        // AuthPackage only has api_key — extra fields should be stripped on roundtrip
        let json_with_extra = r#"{"type":"connection.auth","api_key":"key","extra_field":"value"}"#;
        inspector.log_inbound("run-1", json_with_extra);

        let entries = inspector.entries_for_run("run-1");
        assert_eq!(entries.len(), 1);
        assert!(entries[0].roundtrip_mismatch);
        assert!(entries[0].roundtrip_json.is_some());
    }

    #[test]
    fn roundtrip_check_no_mismatch_for_clean_package() {
        let inspector = PackageInspectorService::new(100, true);
        let json = r#"{"type":"connection.auth","api_key":"test-key"}"#;
        inspector.log_inbound("run-1", json);

        let entries = inspector.entries_for_run("run-1");
        assert_eq!(entries.len(), 1);
        assert!(!entries[0].roundtrip_mismatch);
        assert!(entries[0].roundtrip_json.is_none());
    }

    #[test]
    fn clear_run_removes_entries() {
        let inspector = PackageInspectorService::new(100, true);
        inspector.log_inbound("run-1", r#"{"type":"connection.auth","api_key":"key"}"#);
        assert!(!inspector.entries_for_run("run-1").is_empty());

        inspector.clear_run("run-1");
        assert!(inspector.entries_for_run("run-1").is_empty());
    }

    #[test]
    fn serde_json_partial_eq_works() {
        let a: serde_json::Value =
            serde_json::from_str(r#"{"a": 1, "b": [1, 2, {"c": 3}]}"#).unwrap();
        let b: serde_json::Value =
            serde_json::from_str(r#"{"b": [1, 2, {"c": 3}], "a": 1}"#).unwrap();
        assert_eq!(a, b);

        let c: serde_json::Value =
            serde_json::from_str(r#"{"a": 1, "b": [1, 2, {"c": 4}]}"#).unwrap();
        assert_ne!(a, c);
    }

    #[test]
    fn log_outbound_captures_sent_direction() {
        let inspector = PackageInspectorService::new(100, true);
        let json: serde_json::Value =
            serde_json::from_str(r#"{"type":"connection.auth_ack"}"#).unwrap();
        inspector.log_outbound("run-1", &json);

        let entries = inspector.entries_for_run("run-1");
        assert_eq!(entries.len(), 1);
        assert_eq!(entries[0].direction, PackageDirection::Sent);
    }

    #[test]
    fn invalid_json_records_error() {
        let inspector = PackageInspectorService::new(100, true);
        inspector.log_inbound("run-1", "not valid json");

        let entries = inspector.entries_for_run("run-1");
        assert_eq!(entries.len(), 1);
        assert!(entries[0].error.is_some());
    }
}
