// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use dspatch_sdk::domain::enums::{AgentState, LogLevel};
use dspatch_sdk::server::packages::*;

// ── Helper ──────────────────────────────────────────────────────────

/// Round-trip: serialize to JSON string, then deserialize back via Package::from_json.
fn round_trip(pkg: &Package) -> Package {
    let json = pkg.to_json().expect("serialize");
    Package::from_json(&json).expect("deserialize")
}

/// Asserts the type string matches after round-trip.
fn assert_round_trip_type(pkg: &Package, expected_type: &str) {
    assert_eq!(pkg.type_str(), expected_type);
    let rt = round_trip(pkg);
    assert_eq!(rt.type_str(), expected_type);
}

// ── Output packages ─────────────────────────────────────────────────

#[test]
fn message_round_trip() {
    let pkg = Package::Message(MessagePackage {
        instance_id: "inst-1".into(),
        turn_id: Some("turn-1".into()),
        ts: Some(1700000000000),
        id: Some("msg-1".into()),
        role: MessageRole::Assistant,
        content: "Hello".into(),
        model: Some("gpt-4".into()),
        input_tokens: Some(100),
        output_tokens: Some(50),
        is_delta: false,
        sender_name: Some("agent-a".into()),
    });
    assert_round_trip_type(&pkg, "agent.output.message");
    assert!(pkg.is_output());
    assert!(!pkg.is_event());
    assert!(!pkg.is_signal());
    assert!(!pkg.is_connection());
    assert_eq!(pkg.instance_id(), Some("inst-1"));
}

#[test]
fn message_defaults() {
    let json = r#"{"type":"agent.output.message","content":"Hi"}"#;
    let pkg = Package::from_json(json).unwrap();
    if let Package::Message(m) = &pkg {
        assert_eq!(m.role, MessageRole::Assistant);
        assert!(!m.is_delta);
        assert_eq!(m.instance_id, "");
    } else {
        panic!("expected Message");
    }
}

#[test]
fn activity_round_trip() {
    let pkg = Package::Activity(ActivityPackage {
        instance_id: "inst-1".into(),
        turn_id: None,
        ts: None,
        id: None,
        event_type: "tool_use".into(),
        data: Some(serde_json::json!({"tool": "bash"})),
        content: Some("running command".into()),
        is_delta: true,
    });
    assert_round_trip_type(&pkg, "agent.output.activity");
    assert!(pkg.is_output());
}

#[test]
fn log_round_trip() {
    let pkg = Package::Log(LogPackage {
        instance_id: "inst-1".into(),
        turn_id: None,
        ts: None,
        level: LogLevel::Warn,
        message: "something happened".into(),
    });
    assert_round_trip_type(&pkg, "agent.output.log");
    assert!(pkg.is_output());
}

#[test]
fn usage_round_trip() {
    let pkg = Package::Usage(UsagePackage {
        instance_id: "inst-1".into(),
        turn_id: None,
        ts: None,
        model: "claude-3".into(),
        input_tokens: 200,
        output_tokens: 100,
        cache_read_tokens: Some(50),
        cache_write_tokens: None,
        cost_usd: Some(0.003),
    });
    assert_round_trip_type(&pkg, "agent.output.usage");
}

#[test]
fn files_round_trip() {
    let pkg = Package::Files(FilesPackage {
        instance_id: "inst-1".into(),
        turn_id: None,
        ts: None,
        files: vec![serde_json::json!({"path": "foo.rs", "content": "bar"})],
    });
    assert_round_trip_type(&pkg, "agent.output.files");
}

#[test]
fn prompt_received_round_trip() {
    let pkg = Package::PromptReceived(PromptReceivedPackage {
        instance_id: "inst-1".into(),
        turn_id: None,
        ts: None,
        content: "do something".into(),
        sender_name: Some("user".into()),
    });
    assert_round_trip_type(&pkg, "agent.output.prompt_received");
}

// ── Event packages ──────────────────────────────────────────────────

#[test]
fn user_input_round_trip() {
    let pkg = Package::UserInput(UserInputPackage {
        instance_id: "inst-1".into(),
        content: "hello agent".into(),
    });
    assert_round_trip_type(&pkg, "agent.event.user_input");
    assert!(pkg.is_event());
    assert!(!pkg.is_output());
}

#[test]
fn talk_to_request_round_trip() {
    let pkg = Package::TalkToRequest(TalkToRequestPackage {
        instance_id: "inst-1".into(),
        target_agent: "agent-b".into(),
        text: "help me".into(),
        request_id: "req-1".into(),
        caller_agent: Some("agent-a".into()),
        continue_conversation: true,
    });
    assert_round_trip_type(&pkg, "agent.event.talk_to.request");
}

#[test]
fn talk_to_request_defaults() {
    let json = r#"{"type":"agent.event.talk_to.request","instance_id":"i","target_agent":"b","text":"hi","request_id":"r"}"#;
    let pkg = Package::from_json(json).unwrap();
    if let Package::TalkToRequest(t) = &pkg {
        assert!(!t.continue_conversation);
        assert!(t.caller_agent.is_none());
    } else {
        panic!("expected TalkToRequest");
    }
}

#[test]
fn talk_to_response_round_trip() {
    let pkg = Package::TalkToResponse(TalkToResponsePackage {
        instance_id: "inst-1".into(),
        request_id: "req-1".into(),
        turn_id: Some("turn-2".into()),
        response: Some("here you go".into()),
        error: None,
    });
    assert_round_trip_type(&pkg, "agent.event.talk_to.response");
}

#[test]
fn request_alive_round_trip() {
    let pkg = Package::RequestAlive(RequestAlivePackage {
        instance_id: "inst-1".into(),
        request_id: "req-1".into(),
    });
    assert_round_trip_type(&pkg, "agent.event.request.alive");
}

#[test]
fn request_failed_round_trip() {
    let pkg = Package::RequestFailed(RequestFailedPackage {
        instance_id: "inst-1".into(),
        request_id: "req-1".into(),
        reason: "timeout".into(),
    });
    assert_round_trip_type(&pkg, "agent.event.request.failed");
}

#[test]
fn inquiry_request_round_trip() {
    let pkg = Package::InquiryRequest(InquiryRequestPackage {
        instance_id: "inst-1".into(),
        content_markdown: "## Question\nWhat?".into(),
        inquiry_id: "inq-1".into(),
        suggestions: vec!["yes".into(), "no".into()],
        file_paths: Some(vec!["foo.rs".into()]),
        priority: WireInquiryPriority::Urgent,
    });
    assert_round_trip_type(&pkg, "agent.event.inquiry.request");
}

#[test]
fn inquiry_request_defaults() {
    let json = r#"{"type":"agent.event.inquiry.request","instance_id":"i","content_markdown":"q","inquiry_id":"iq"}"#;
    let pkg = Package::from_json(json).unwrap();
    if let Package::InquiryRequest(iq) = &pkg {
        assert!(iq.suggestions.is_empty());
        assert!(iq.file_paths.is_none());
        assert_eq!(iq.priority, WireInquiryPriority::Normal);
    } else {
        panic!("expected InquiryRequest");
    }
}

#[test]
fn inquiry_response_round_trip() {
    let pkg = Package::InquiryResponse(InquiryResponsePackage {
        instance_id: "inst-1".into(),
        inquiry_id: "inq-1".into(),
        turn_id: None,
        response_text: Some("answer".into()),
        response_suggestion_index: Some(0),
    });
    assert_round_trip_type(&pkg, "agent.event.inquiry.response");
}

#[test]
fn inquiry_alive_round_trip() {
    let pkg = Package::InquiryAlive(InquiryAlivePackage {
        instance_id: "inst-1".into(),
        inquiry_id: "inq-1".into(),
    });
    assert_round_trip_type(&pkg, "agent.event.inquiry.alive");
}

#[test]
fn inquiry_failed_round_trip() {
    let pkg = Package::InquiryFailed(InquiryFailedPackage {
        instance_id: "inst-1".into(),
        inquiry_id: "inq-1".into(),
        reason: "cancelled".into(),
    });
    assert_round_trip_type(&pkg, "agent.event.inquiry.failed");
}

// ── Signal packages ─────────────────────────────────────────────────

#[test]
fn drain_round_trip() {
    let pkg = Package::Drain(DrainPackage {
        instance_id: "inst-1".into(),
    });
    assert_round_trip_type(&pkg, "agent.signal.drain");
    assert!(pkg.is_signal());
    assert!(!pkg.is_event());
}

#[test]
fn terminate_round_trip() {
    let pkg = Package::Terminate(TerminatePackage {
        instance_id: "inst-1".into(),
    });
    assert_round_trip_type(&pkg, "agent.signal.terminate");
}

#[test]
fn state_query_round_trip() {
    let pkg = Package::StateQuery(StateQueryPackage {
        instance_id: "inst-1".into(),
    });
    assert_round_trip_type(&pkg, "agent.signal.state_query");
}

#[test]
fn state_report_round_trip() {
    let mut instances = HashMap::new();
    instances.insert("child-1".into(), AgentState::Generating);
    instances.insert("child-2".into(), AgentState::Idle);

    let pkg = Package::StateReport(StateReportPackage {
        instance_id: "inst-1".into(),
        state: AgentState::WaitingForAgent,
        instances: Some(instances),
    });
    assert_round_trip_type(&pkg, "agent.signal.state_report");

    let rt = round_trip(&pkg);
    if let Package::StateReport(sr) = &rt {
        assert_eq!(sr.state, AgentState::WaitingForAgent);
        let inst = sr.instances.as_ref().unwrap();
        assert_eq!(inst.get("child-1"), Some(&AgentState::Generating));
        assert_eq!(inst.get("child-2"), Some(&AgentState::Idle));
    } else {
        panic!("expected StateReport");
    }
}

#[test]
fn instance_spawned_round_trip() {
    let pkg = Package::InstanceSpawned(InstanceSpawnedPackage {
        instance_id: "inst-2".into(),
    });
    assert_round_trip_type(&pkg, "agent.signal.instance_spawned");
}

// ── Connection packages ─────────────────────────────────────────────

#[test]
fn auth_round_trip() {
    let pkg = Package::Auth(AuthPackage {
        api_key: "sk-test-123".into(),
    });
    assert_round_trip_type(&pkg, "connection.auth");
    assert!(pkg.is_connection());
    assert!(!pkg.is_output());
    assert!(pkg.instance_id().is_none());
}

#[test]
fn auth_ack_round_trip() {
    let pkg = Package::AuthAck(AuthAckPackage {});
    assert_round_trip_type(&pkg, "connection.auth_ack");
}

#[test]
fn auth_error_round_trip() {
    let pkg = Package::AuthError(AuthErrorPackage {
        message: "invalid key".into(),
    });
    assert_round_trip_type(&pkg, "connection.auth_error");
}

#[test]
fn register_round_trip() {
    let pkg = Package::Register(RegisterPackage {
        name: "my-agent".into(),
        role: Some("worker".into()),
        capabilities: Some(vec!["code".into(), "search".into()]),
    });
    assert_round_trip_type(&pkg, "connection.register");
}

#[test]
fn heartbeat_round_trip() {
    let mut instances = HashMap::new();
    instances.insert("inst-1".into(), "idle".into());
    instances.insert("inst-2".into(), "generating".into());

    let pkg = Package::Heartbeat(HeartbeatPackage { instances });
    assert_round_trip_type(&pkg, "connection.heartbeat");

    let rt = round_trip(&pkg);
    if let Package::Heartbeat(hb) = &rt {
        assert_eq!(hb.instances.get("inst-1"), Some(&"idle".to_string()));
    } else {
        panic!("expected Heartbeat");
    }
}

#[test]
fn spawn_instance_round_trip() {
    let pkg = Package::SpawnInstance(SpawnInstancePackage {
        instance_id: "inst-new".into(),
    });
    assert_round_trip_type(&pkg, "connection.spawn_instance");
    assert!(pkg.is_connection());
    assert_eq!(pkg.instance_id(), Some("inst-new"));
}

// ── Unknown package ─────────────────────────────────────────────────

#[test]
fn unknown_type_falls_back() {
    let json = r#"{"type":"custom.something","foo":"bar"}"#;
    let pkg = Package::from_json(json).unwrap();
    assert!(matches!(pkg, Package::Unknown(_)));
    if let Package::Unknown(u) = &pkg {
        assert_eq!(u.raw_type, "custom.something");
        assert_eq!(u.raw.get("foo").and_then(|v| v.as_str()), Some("bar"));
    }
    assert_eq!(pkg.type_str(), "custom.something");
    assert!(pkg.instance_id().is_none());
}

#[test]
fn unknown_null_type() {
    let json = r#"{"foo":"bar"}"#;
    let pkg = Package::from_json(json).unwrap();
    assert!(matches!(pkg, Package::Unknown(_)));
    if let Package::Unknown(u) = &pkg {
        assert_eq!(u.raw_type, "null");
    }
}

// ── Helper method tests ─────────────────────────────────────────────

#[test]
fn is_output_returns_true_for_all_output_types() {
    let output_packages = [
        Package::Message(MessagePackage {
            instance_id: "i".into(),
            turn_id: None,
            ts: None,
            id: None,
            role: MessageRole::Assistant,
            content: "c".into(),
            model: None,
            input_tokens: None,
            output_tokens: None,
            is_delta: false,
            sender_name: None,
        }),
        Package::Activity(ActivityPackage {
            instance_id: "i".into(),
            turn_id: None,
            ts: None,
            id: None,
            event_type: "e".into(),
            data: None,
            content: None,
            is_delta: false,
        }),
        Package::Log(LogPackage {
            instance_id: "i".into(),
            turn_id: None,
            ts: None,
            level: LogLevel::Info,
            message: "m".into(),
        }),
        Package::Usage(UsagePackage {
            instance_id: "i".into(),
            turn_id: None,
            ts: None,
            model: "m".into(),
            input_tokens: 0,
            output_tokens: 0,
            cache_read_tokens: None,
            cache_write_tokens: None,
            cost_usd: None,
        }),
        Package::Files(FilesPackage {
            instance_id: "i".into(),
            turn_id: None,
            ts: None,
            files: vec![],
        }),
        Package::PromptReceived(PromptReceivedPackage {
            instance_id: "i".into(),
            turn_id: None,
            ts: None,
            content: "c".into(),
            sender_name: None,
        }),
    ];
    for pkg in &output_packages {
        assert!(pkg.is_output(), "expected is_output for {:?}", pkg.type_str());
        assert!(!pkg.is_event());
        assert!(!pkg.is_signal());
        assert!(!pkg.is_connection());
    }
}

#[test]
fn optional_fields_omitted_when_none() {
    let pkg = Package::Message(MessagePackage {
        instance_id: "i".into(),
        turn_id: None,
        ts: None,
        id: None,
        role: MessageRole::Assistant,
        content: "c".into(),
        model: None,
        input_tokens: None,
        output_tokens: None,
        is_delta: false,
        sender_name: None,
    });
    let json = pkg.to_json().unwrap();
    let v: serde_json::Value = serde_json::from_str(&json).unwrap();
    assert!(v.get("turn_id").is_none());
    assert!(v.get("ts").is_none());
    assert!(v.get("id").is_none());
    assert!(v.get("model").is_none());
    assert!(v.get("sender_name").is_none());
    // Required/default fields are present
    assert!(v.get("content").is_some());
    assert!(v.get("role").is_some());
    assert!(v.get("is_delta").is_some());
}

#[test]
fn message_role_serialization() {
    let json = r#"{"type":"agent.output.message","content":"x","role":"tool"}"#;
    let pkg = Package::from_json(json).unwrap();
    if let Package::Message(m) = &pkg {
        assert_eq!(m.role, MessageRole::Tool);
    } else {
        panic!("expected Message");
    }
}

#[test]
fn wire_inquiry_priority_serialization() {
    let json = r#"{"type":"agent.event.inquiry.request","instance_id":"i","content_markdown":"q","inquiry_id":"iq","priority":"urgent"}"#;
    let pkg = Package::from_json(json).unwrap();
    if let Package::InquiryRequest(iq) = &pkg {
        assert_eq!(iq.priority, WireInquiryPriority::Urgent);
    } else {
        panic!("expected InquiryRequest");
    }
}
