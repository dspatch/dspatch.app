// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use dspatch_engine::domain::enums::*;

// ── AgentState transition map ──────────────────────────────────────────

#[test]
fn agent_state_valid_transitions_from_disconnected() {
    use AgentState::*;
    let valid = [Generating, Idle, WaitingForInquiry, WaitingForAgent];
    for target in valid {
        assert!(
            Disconnected.can_transition_to(target),
            "disconnected -> {target:?} should be valid"
        );
    }
    let invalid = [Completed, Failed, Crashed];
    for target in invalid {
        assert!(
            !Disconnected.can_transition_to(target),
            "disconnected -> {target:?} should be invalid"
        );
    }
}

#[test]
fn agent_state_valid_transitions_from_idle() {
    use AgentState::*;
    let valid = [Generating, Completed, Failed, Crashed, Disconnected];
    for target in valid {
        assert!(
            Idle.can_transition_to(target),
            "idle -> {target:?} should be valid"
        );
    }
    let invalid = [WaitingForInquiry, WaitingForAgent];
    for target in invalid {
        assert!(
            !Idle.can_transition_to(target),
            "idle -> {target:?} should be invalid"
        );
    }
}

#[test]
fn agent_state_valid_transitions_from_generating() {
    use AgentState::*;
    let valid = [
        Idle,
        WaitingForInquiry,
        WaitingForAgent,
        Completed,
        Failed,
        Crashed,
        Disconnected,
    ];
    for target in valid {
        assert!(
            Generating.can_transition_to(target),
            "generating -> {target:?} should be valid"
        );
    }
    // generating -> generating is not in the map
    assert!(!Generating.can_transition_to(Generating));
}

#[test]
fn agent_state_valid_transitions_from_waiting() {
    use AgentState::*;
    for source in [WaitingForInquiry, WaitingForAgent] {
        let valid = [Generating, Completed, Failed, Crashed, Disconnected];
        for target in valid {
            assert!(
                source.can_transition_to(target),
                "{source:?} -> {target:?} should be valid"
            );
        }
        assert!(
            !source.can_transition_to(Idle),
            "{source:?} -> idle should be invalid"
        );
    }
}

#[test]
fn agent_state_valid_transitions_from_crashed() {
    use AgentState::*;
    assert!(Crashed.can_transition_to(Disconnected));
    assert!(Crashed.can_transition_to(Generating));
    assert!(!Crashed.can_transition_to(Idle));
    assert!(!Crashed.can_transition_to(Completed));
}

#[test]
fn agent_state_terminal_has_no_transitions() {
    use AgentState::*;
    for terminal in [Completed, Failed] {
        for target in [
            Idle,
            Generating,
            WaitingForAgent,
            WaitingForInquiry,
            Disconnected,
            Completed,
            Failed,
            Crashed,
        ] {
            assert!(
                !terminal.can_transition_to(target),
                "{terminal:?} -> {target:?} should be invalid (terminal state)"
            );
        }
    }
}

// ── AgentState computed properties ─────────────────────────────────────

#[test]
fn agent_state_is_terminal() {
    use AgentState::*;
    assert!(Completed.is_terminal());
    assert!(Failed.is_terminal());
    assert!(!Idle.is_terminal());
    assert!(!Generating.is_terminal());
    assert!(!Crashed.is_terminal());
    assert!(!Disconnected.is_terminal());
}

#[test]
fn agent_state_is_active() {
    use AgentState::*;
    assert!(Generating.is_active());
    assert!(Idle.is_active()); // idle is_waiting -> is_active
    assert!(WaitingForAgent.is_active());
    assert!(WaitingForInquiry.is_active());
    assert!(!Completed.is_active());
    assert!(!Failed.is_active());
    assert!(!Disconnected.is_active());
    assert!(!Crashed.is_active());
}

#[test]
fn agent_state_is_waiting() {
    use AgentState::*;
    assert!(Idle.is_waiting());
    assert!(WaitingForInquiry.is_waiting());
    assert!(WaitingForAgent.is_waiting());
    assert!(!Generating.is_waiting());
    assert!(!Completed.is_waiting());
    assert!(!Disconnected.is_waiting());
}

// ── AgentState from_wire / from_db ─────────────────────────────────────

#[test]
fn agent_state_from_wire() {
    assert_eq!(AgentState::from_wire("idle"), Some(AgentState::Idle));
    assert_eq!(
        AgentState::from_wire("generating"),
        Some(AgentState::Generating)
    );
    assert_eq!(
        AgentState::from_wire("waiting_for_agent"),
        Some(AgentState::WaitingForAgent)
    );
    assert_eq!(
        AgentState::from_wire("waiting_for_inquiry"),
        Some(AgentState::WaitingForInquiry)
    );
    // App-only states are not on the wire
    assert_eq!(AgentState::from_wire("completed"), None);
    assert_eq!(AgentState::from_wire("disconnected"), None);
    assert_eq!(AgentState::from_wire("garbage"), None);
}

#[test]
fn agent_state_from_db_current_names() {
    assert_eq!(AgentState::from_db("idle"), Some(AgentState::Idle));
    assert_eq!(
        AgentState::from_db("generating"),
        Some(AgentState::Generating)
    );
    assert_eq!(
        AgentState::from_db("waitingForAgent"),
        Some(AgentState::WaitingForAgent)
    );
    assert_eq!(
        AgentState::from_db("waitingForInquiry"),
        Some(AgentState::WaitingForInquiry)
    );
    assert_eq!(
        AgentState::from_db("disconnected"),
        Some(AgentState::Disconnected)
    );
    assert_eq!(
        AgentState::from_db("completed"),
        Some(AgentState::Completed)
    );
    assert_eq!(AgentState::from_db("failed"), Some(AgentState::Failed));
    assert_eq!(AgentState::from_db("crashed"), Some(AgentState::Crashed));
}

#[test]
fn agent_state_from_db_legacy_names() {
    assert_eq!(
        AgentState::from_db("running"),
        Some(AgentState::Generating)
    );
    assert_eq!(
        AgentState::from_db("waitingForInput"),
        Some(AgentState::Idle)
    );
}

#[test]
fn agent_state_from_db_unknown() {
    assert_eq!(AgentState::from_db("nonexistent"), None);
}

// ── WorkspaceStatus transition map ─────────────────────────────────────

#[test]
fn workspace_status_transitions() {
    use WorkspaceStatus::*;

    // idle -> starting only
    assert!(Idle.can_transition_to(Starting));
    assert!(!Idle.can_transition_to(Running));
    assert!(!Idle.can_transition_to(Failed));

    // starting -> running, failed
    assert!(Starting.can_transition_to(Running));
    assert!(Starting.can_transition_to(Failed));
    assert!(!Starting.can_transition_to(Idle));
    assert!(!Starting.can_transition_to(Stopping));

    // running -> stopping, failed
    assert!(Running.can_transition_to(Stopping));
    assert!(Running.can_transition_to(Failed));
    assert!(!Running.can_transition_to(Idle));
    assert!(!Running.can_transition_to(Starting));

    // stopping -> idle, failed
    assert!(Stopping.can_transition_to(Idle));
    assert!(Stopping.can_transition_to(Failed));
    assert!(!Stopping.can_transition_to(Running));

    // failed -> idle only
    assert!(Failed.can_transition_to(Idle));
    assert!(!Failed.can_transition_to(Starting));
    assert!(!Failed.can_transition_to(Running));
}

#[test]
fn workspace_status_properties() {
    use WorkspaceStatus::*;

    assert!(Failed.is_terminal());
    assert!(!Idle.is_terminal());
    assert!(!Running.is_terminal());

    assert!(Starting.is_active());
    assert!(Running.is_active());
    assert!(Stopping.is_active());
    assert!(!Idle.is_active());
    assert!(!Failed.is_active());
}

// ── Serde round-trip tests ─────────────────────────────────────────────

macro_rules! serde_round_trip {
    ($name:ident, $ty:ty, $variant:expr, $expected_json:expr) => {
        #[test]
        fn $name() {
            let json = serde_json::to_string(&$variant).unwrap();
            assert_eq!(json, $expected_json, "serialization mismatch");
            let deser: $ty = serde_json::from_str(&json).unwrap();
            assert_eq!(deser, $variant, "deserialization mismatch");
        }
    };
}

// AgentState
serde_round_trip!(
    serde_agent_state_idle,
    AgentState,
    AgentState::Idle,
    "\"idle\""
);
serde_round_trip!(
    serde_agent_state_generating,
    AgentState,
    AgentState::Generating,
    "\"generating\""
);
serde_round_trip!(
    serde_agent_state_waiting_for_agent,
    AgentState,
    AgentState::WaitingForAgent,
    "\"waiting_for_agent\""
);
serde_round_trip!(
    serde_agent_state_waiting_for_inquiry,
    AgentState,
    AgentState::WaitingForInquiry,
    "\"waiting_for_inquiry\""
);
serde_round_trip!(
    serde_agent_state_disconnected,
    AgentState,
    AgentState::Disconnected,
    "\"disconnected\""
);
serde_round_trip!(
    serde_agent_state_completed,
    AgentState,
    AgentState::Completed,
    "\"completed\""
);
serde_round_trip!(
    serde_agent_state_failed,
    AgentState,
    AgentState::Failed,
    "\"failed\""
);
serde_round_trip!(
    serde_agent_state_crashed,
    AgentState,
    AgentState::Crashed,
    "\"crashed\""
);

// AuthMode
serde_round_trip!(
    serde_auth_mode_undetermined,
    AuthMode,
    AuthMode::Undetermined,
    "\"undetermined\""
);
serde_round_trip!(
    serde_auth_mode_anonymous,
    AuthMode,
    AuthMode::Anonymous,
    "\"anonymous\""
);
serde_round_trip!(
    serde_auth_mode_connected,
    AuthMode,
    AuthMode::Connected,
    "\"connected\""
);

// DeviceType
serde_round_trip!(
    serde_device_type_desktop,
    DeviceType,
    DeviceType::Desktop,
    "\"desktop\""
);
serde_round_trip!(
    serde_device_type_mobile,
    DeviceType,
    DeviceType::Mobile,
    "\"mobile\""
);

// InquiryPriority
serde_round_trip!(
    serde_inquiry_priority_normal,
    InquiryPriority,
    InquiryPriority::Normal,
    "\"normal\""
);
serde_round_trip!(
    serde_inquiry_priority_high,
    InquiryPriority,
    InquiryPriority::High,
    "\"high\""
);

// InquiryStatus
serde_round_trip!(
    serde_inquiry_status_pending,
    InquiryStatus,
    InquiryStatus::Pending,
    "\"pending\""
);
serde_round_trip!(
    serde_inquiry_status_responded,
    InquiryStatus,
    InquiryStatus::Responded,
    "\"responded\""
);
serde_round_trip!(
    serde_inquiry_status_delivered,
    InquiryStatus,
    InquiryStatus::Delivered,
    "\"delivered\""
);
serde_round_trip!(
    serde_inquiry_status_expired,
    InquiryStatus,
    InquiryStatus::Expired,
    "\"expired\""
);

// LogLevel
serde_round_trip!(
    serde_log_level_debug,
    LogLevel,
    LogLevel::Debug,
    "\"debug\""
);
serde_round_trip!(serde_log_level_info, LogLevel, LogLevel::Info, "\"info\"");
serde_round_trip!(serde_log_level_warn, LogLevel, LogLevel::Warn, "\"warn\"");
serde_round_trip!(
    serde_log_level_error,
    LogLevel,
    LogLevel::Error,
    "\"error\""
);

// LogSource
serde_round_trip!(
    serde_log_source_agent,
    LogSource,
    LogSource::Agent,
    "\"agent\""
);
serde_round_trip!(
    serde_log_source_engine,
    LogSource,
    LogSource::Engine,
    "\"engine\""
);

// PlatformType
serde_round_trip!(
    serde_platform_type_windows,
    PlatformType,
    PlatformType::Windows,
    "\"windows\""
);
serde_round_trip!(
    serde_platform_type_macos,
    PlatformType,
    PlatformType::Macos,
    "\"macos\""
);
serde_round_trip!(
    serde_platform_type_linux,
    PlatformType,
    PlatformType::Linux,
    "\"linux\""
);
serde_round_trip!(
    serde_platform_type_ios,
    PlatformType,
    PlatformType::Ios,
    "\"ios\""
);
serde_round_trip!(
    serde_platform_type_android,
    PlatformType,
    PlatformType::Android,
    "\"android\""
);

// SourceType
serde_round_trip!(
    serde_source_type_local,
    SourceType,
    SourceType::Local,
    "\"local\""
);
serde_round_trip!(
    serde_source_type_git,
    SourceType,
    SourceType::Git,
    "\"git\""
);
serde_round_trip!(
    serde_source_type_hub,
    SourceType,
    SourceType::Hub,
    "\"hub\""
);

// TokenScope
serde_round_trip!(
    serde_token_scope_email_verification,
    TokenScope,
    TokenScope::EmailVerification,
    "\"email_verification\""
);
serde_round_trip!(
    serde_token_scope_partial_2fa,
    TokenScope,
    TokenScope::Partial2fa,
    "\"partial_2fa\""
);
serde_round_trip!(
    serde_token_scope_setup_2fa,
    TokenScope,
    TokenScope::Setup2fa,
    "\"setup_2fa\""
);
serde_round_trip!(
    serde_token_scope_awaiting_backup,
    TokenScope,
    TokenScope::AwaitingBackupConfirmation,
    "\"awaiting_backup_confirmation\""
);
serde_round_trip!(
    serde_token_scope_device_registration,
    TokenScope,
    TokenScope::DeviceRegistration,
    "\"device_registration\""
);
serde_round_trip!(
    serde_token_scope_full,
    TokenScope,
    TokenScope::Full,
    "\"full\""
);

// WorkspaceStatus
serde_round_trip!(
    serde_workspace_status_idle,
    WorkspaceStatus,
    WorkspaceStatus::Idle,
    "\"idle\""
);
serde_round_trip!(
    serde_workspace_status_starting,
    WorkspaceStatus,
    WorkspaceStatus::Starting,
    "\"starting\""
);
serde_round_trip!(
    serde_workspace_status_running,
    WorkspaceStatus,
    WorkspaceStatus::Running,
    "\"running\""
);
serde_round_trip!(
    serde_workspace_status_stopping,
    WorkspaceStatus,
    WorkspaceStatus::Stopping,
    "\"stopping\""
);
serde_round_trip!(
    serde_workspace_status_failed,
    WorkspaceStatus,
    WorkspaceStatus::Failed,
    "\"failed\""
);

// ── LogLevel::try_from_name ────────────────────────────────────────────

#[test]
fn log_level_try_from_name() {
    assert_eq!(LogLevel::try_from_name("debug"), Some(LogLevel::Debug));
    assert_eq!(LogLevel::try_from_name("info"), Some(LogLevel::Info));
    assert_eq!(LogLevel::try_from_name("warn"), Some(LogLevel::Warn));
    assert_eq!(LogLevel::try_from_name("error"), Some(LogLevel::Error));
    assert_eq!(LogLevel::try_from_name("unknown"), None);
    assert_eq!(LogLevel::try_from_name("DEBUG"), None); // case-sensitive
}
