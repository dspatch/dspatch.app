// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use chrono::NaiveDateTime;
use dspatch_sdk::domain::enums::*;
use dspatch_sdk::domain::models::*;

fn test_dt() -> NaiveDateTime {
    NaiveDateTime::parse_from_str("2026-03-10 12:00:00", "%Y-%m-%d %H:%M:%S").unwrap()
}

// ---------------------------------------------------------------------------
// Serde round-trip tests
// ---------------------------------------------------------------------------

#[test]
fn workspace_serde_roundtrip() {
    let ws = Workspace {
        id: "ws-1".into(),
        name: "My Project".into(),
        project_path: "/home/user/project".into(),
        created_at: test_dt(),
        updated_at: test_dt(),
    };
    let json = serde_json::to_string(&ws).unwrap();
    let back: Workspace = serde_json::from_str(&json).unwrap();
    assert_eq!(ws, back);
}

#[test]
fn recent_project_serde_roundtrip() {
    let rp = RecentProject {
        id: "rp-1".into(),
        path: "/home/user/project".into(),
        name: "project".into(),
        is_git_repo: true,
        last_used_at: test_dt(),
    };
    let json = serde_json::to_string(&rp).unwrap();
    let back: RecentProject = serde_json::from_str(&json).unwrap();
    assert_eq!(rp, back);
}

#[test]
fn recent_project_default_is_git_repo() {
    let json = r#"{"id":"rp-1","path":"/tmp","name":"tmp","lastUsedAt":"2026-03-10T12:00:00"}"#;
    let rp: RecentProject = serde_json::from_str(json).unwrap();
    assert!(!rp.is_git_repo);
}

#[test]
fn env_var_defaults() {
    let json = r#"{"key":"MY_KEY"}"#;
    let ev: EnvVar = serde_json::from_str(json).unwrap();
    assert_eq!(ev.value, "");
    assert!(!ev.is_secret);
    assert!(ev.is_enabled);
}

#[test]
fn env_var_serde_roundtrip() {
    let ev = EnvVar {
        key: "API_KEY".into(),
        value: "{{apikey:OpenAI}}".into(),
        is_secret: true,
        is_enabled: false,
    };
    let json = serde_json::to_string(&ev).unwrap();
    let back: EnvVar = serde_json::from_str(&json).unwrap();
    assert_eq!(ev, back);
}

#[test]
fn volume_mount_default_read_only() {
    let json = r#"{"hostPath":"/src","containerPath":"/workspace"}"#;
    let vm: VolumeMount = serde_json::from_str(json).unwrap();
    assert!(!vm.is_read_only);
}

#[test]
fn agent_template_serde_roundtrip() {
    let tmpl = AgentTemplate {
        id: "tmpl-1".into(),
        name: "Test Agent".into(),
        source_type: SourceType::Local,
        source_path: Some("/src/agent".into()),
        git_url: None,
        git_branch: None,
        entry_point: "main.py".into(),
        description: Some("A test agent".into()),
        readme: None,
        required_env: vec!["OPENAI_API_KEY".into()],
        required_mounts: vec![],
        fields: HashMap::from([("version".into(), "1.0".into())]),
        hub_slug: None,
        hub_author: None,
        hub_category: None,
        hub_tags: vec![],
        hub_version: None,
        hub_repo_url: None,
        hub_commit_hash: None,
        created_at: test_dt(),
        updated_at: test_dt(),
    };
    let json = serde_json::to_string(&tmpl).unwrap();
    let back: AgentTemplate = serde_json::from_str(&json).unwrap();
    assert_eq!(tmpl, back);
}

#[test]
fn agent_template_default_collections() {
    // Verify default empty vecs/maps when not present in JSON
    let json = r#"{
        "id": "t1", "name": "Agent", "sourceType": "local",
        "entryPoint": "main.py",
        "createdAt": "2026-03-10T12:00:00", "updatedAt": "2026-03-10T12:00:00"
    }"#;
    let tmpl: AgentTemplate = serde_json::from_str(json).unwrap();
    assert!(tmpl.required_env.is_empty());
    assert!(tmpl.required_mounts.is_empty());
    assert!(tmpl.fields.is_empty());
    assert!(tmpl.hub_tags.is_empty());
}

#[test]
fn workspace_agent_serde_roundtrip() {
    let wa = WorkspaceAgent {
        id: "wa-1".into(),
        run_id: "run-1".into(),
        agent_key: "coder".into(),
        instance_id: "inst-1".into(),
        display_name: "Coder".into(),
        chain_json: "[]".into(),
        status: AgentState::Idle,
        created_at: test_dt(),
        updated_at: test_dt(),
    };
    let json = serde_json::to_string(&wa).unwrap();
    let back: WorkspaceAgent = serde_json::from_str(&json).unwrap();
    assert_eq!(wa, back);
}

#[test]
fn workspace_inquiry_serde_roundtrip() {
    let inq = WorkspaceInquiry {
        id: "inq-1".into(),
        run_id: "run-1".into(),
        agent_key: "coder".into(),
        instance_id: "inst-1".into(),
        status: InquiryStatus::Pending,
        priority: InquiryPriority::Normal,
        content_markdown: "What should I do?".into(),
        attachments_json: None,
        suggestions_json: Some(r#"["Yes","No"]"#.into()),
        response_text: None,
        response_suggestion_index: None,
        responded_by_agent_key: None,
        forwarding_chain_json: None,
        created_at: test_dt(),
        responded_at: None,
    };
    let json = serde_json::to_string(&inq).unwrap();
    let back: WorkspaceInquiry = serde_json::from_str(&json).unwrap();
    assert_eq!(inq, back);
}

#[test]
fn workspace_run_serde_roundtrip() {
    let run = WorkspaceRun {
        id: "run-1".into(),
        workspace_id: "ws-1".into(),
        run_number: 42,
        status: "running".into(),
        container_id: Some("abc123".into()),
        server_port: Some(8080),
        api_key: None,
        started_at: test_dt(),
        stopped_at: None,
    };
    let json = serde_json::to_string(&run).unwrap();
    let back: WorkspaceRun = serde_json::from_str(&json).unwrap();
    assert_eq!(run, back);
}

#[test]
fn agent_log_serde_roundtrip() {
    let log = AgentLog {
        id: "log-1".into(),
        run_id: "run-1".into(),
        agent_key: "coder".into(),
        instance_id: "inst-1".into(),
        turn_id: None,
        level: LogLevel::Info,
        message: "Hello world".into(),
        source: LogSource::Agent,
        timestamp: test_dt(),
    };
    let json = serde_json::to_string(&log).unwrap();
    let back: AgentLog = serde_json::from_str(&json).unwrap();
    assert_eq!(log, back);
}

#[test]
fn agent_message_serde_roundtrip() {
    let msg = AgentMessage {
        id: "msg-1".into(),
        run_id: "run-1".into(),
        instance_id: "inst-1".into(),
        role: "assistant".into(),
        content: "Here is the code".into(),
        model: Some("claude-3-opus".into()),
        input_tokens: Some(100),
        output_tokens: Some(200),
        turn_id: None,
        sender_name: None,
        created_at: test_dt(),
    };
    let json = serde_json::to_string(&msg).unwrap();
    let back: AgentMessage = serde_json::from_str(&json).unwrap();
    assert_eq!(msg, back);
}

#[test]
fn agent_message_optional_fields_omitted() {
    let msg = AgentMessage {
        id: "msg-1".into(),
        run_id: "run-1".into(),
        instance_id: "inst-1".into(),
        role: "user".into(),
        content: "Hello".into(),
        model: None,
        input_tokens: None,
        output_tokens: None,
        turn_id: None,
        sender_name: None,
        created_at: test_dt(),
    };
    let json = serde_json::to_string(&msg).unwrap();
    assert!(!json.contains("model"));
    assert!(!json.contains("inputTokens"));
    assert!(!json.contains("senderName"));
}

#[test]
fn agent_usage_serde_roundtrip() {
    let usage = AgentUsage {
        id: "u-1".into(),
        run_id: "run-1".into(),
        agent_key: "coder".into(),
        instance_id: "inst-1".into(),
        turn_id: None,
        model: "claude-3-opus".into(),
        input_tokens: 500,
        output_tokens: 1000,
        cache_read_tokens: 50,
        cache_write_tokens: 25,
        cost_usd: 0.015,
        timestamp: test_dt(),
    };
    let json = serde_json::to_string(&usage).unwrap();
    let back: AgentUsage = serde_json::from_str(&json).unwrap();
    assert_eq!(usage, back);
}

#[test]
fn device_serde_roundtrip() {
    let dev = Device {
        id: "dev-1".into(),
        name: "My Laptop".into(),
        platform_type: PlatformType::Windows,
        is_online: true,
        last_seen_at: Some(test_dt()),
    };
    let json = serde_json::to_string(&dev).unwrap();
    let back: Device = serde_json::from_str(&json).unwrap();
    assert_eq!(dev, back);
}

#[test]
fn device_default_is_online() {
    let json = r#"{"id":"d1","name":"PC","platformType":"windows"}"#;
    let dev: Device = serde_json::from_str(json).unwrap();
    assert!(!dev.is_online);
    assert!(dev.last_seen_at.is_none());
}

#[test]
fn docker_status_all_defaults() {
    let json = "{}";
    let ds: DockerStatus = serde_json::from_str(json).unwrap();
    assert!(!ds.is_installed);
    assert!(!ds.is_running);
    assert!(!ds.has_sysbox);
    assert!(!ds.has_nvidia_runtime);
    assert!(!ds.has_runtime_image);
    assert!(ds.runtime_image_size.is_none());
    assert!(ds.docker_version.is_none());
}

#[test]
fn auth_tokens_serde_roundtrip() {
    let tokens = AuthTokens {
        token: "jwt-token-value".into(),
        scope: TokenScope::Full,
        expires_at: Some(test_dt()),
    };
    let json = serde_json::to_string(&tokens).unwrap();
    let back: AuthTokens = serde_json::from_str(&json).unwrap();
    assert_eq!(tokens, back);
}

#[test]
fn backup_codes_data_serde_roundtrip() {
    let bcd = BackupCodesData {
        backup_codes: vec!["ABC123".into(), "DEF456".into()],
        tokens: AuthTokens {
            token: "tok".into(),
            scope: TokenScope::DeviceRegistration,
            expires_at: None,
        },
    };
    let json = serde_json::to_string(&bcd).unwrap();
    let back: BackupCodesData = serde_json::from_str(&json).unwrap();
    assert_eq!(bcd, back);
}

#[test]
fn workspace_template_serde_roundtrip() {
    let wt = WorkspaceTemplate {
        id: "wt-1".into(),
        name: "Starter".into(),
        description: Some("A starter workspace".into()),
        hub_slug: "starter".into(),
        hub_author: "oak".into(),
        hub_category: Some("development".into()),
        hub_tags: vec!["python".into()],
        hub_version: 1,
        config_yaml: "name: Starter\nagents: []".into(),
        agent_refs: vec!["agent-1".into()],
        created_at: test_dt(),
        updated_at: test_dt(),
    };
    let json = serde_json::to_string(&wt).unwrap();
    let back: WorkspaceTemplate = serde_json::from_str(&json).unwrap();
    assert_eq!(wt, back);
}

#[test]
fn inquiry_with_workspace_serde_roundtrip() {
    let iww = InquiryWithWorkspace {
        inquiry: WorkspaceInquiry {
            id: "inq-1".into(),
            run_id: "run-1".into(),
            agent_key: "coder".into(),
            instance_id: "inst-1".into(),
            status: InquiryStatus::Pending,
            priority: InquiryPriority::Normal,
            content_markdown: "Question?".into(),
            attachments_json: None,
            suggestions_json: None,
            response_text: None,
            response_suggestion_index: None,
            responded_by_agent_key: None,
            forwarding_chain_json: None,
            created_at: test_dt(),
            responded_at: None,
        },
        workspace_name: "My Workspace".into(),
        workspace_id: "ws-1".into(),
    };
    let json = serde_json::to_string(&iww).unwrap();
    let back: InquiryWithWorkspace = serde_json::from_str(&json).unwrap();
    assert_eq!(iww, back);
}

// ---------------------------------------------------------------------------
// ApiResponse computed getters
// ---------------------------------------------------------------------------

#[test]
fn api_response_is_success() {
    let r = ApiResponse {
        status_code: 200,
        raw_body: "{}".into(),
        data: None,
    };
    assert!(r.is_success());
    assert!(!r.is_rate_limited());
    assert!(!r.is_stealth_failure());
    assert!(!r.is_validation_error());
    assert!(!r.is_conflict());
}

#[test]
fn api_response_success_range() {
    for code in [200, 201, 204, 299] {
        let r = ApiResponse {
            status_code: code,
            raw_body: String::new(),
            data: None,
        };
        assert!(r.is_success(), "Expected {code} to be success");
    }
    for code in [199, 300, 400, 500] {
        let r = ApiResponse {
            status_code: code,
            raw_body: String::new(),
            data: None,
        };
        assert!(!r.is_success(), "Expected {code} to NOT be success");
    }
}

#[test]
fn api_response_stealth_failure() {
    let r = ApiResponse {
        status_code: 404,
        raw_body: "Not found".into(),
        data: None,
    };
    assert!(r.is_stealth_failure());
    assert!(!r.is_success());
}

#[test]
fn api_response_rate_limited() {
    let r = ApiResponse {
        status_code: 429,
        raw_body: "Too many requests".into(),
        data: None,
    };
    assert!(r.is_rate_limited());
}

#[test]
fn api_response_validation_error() {
    let r = ApiResponse {
        status_code: 400,
        raw_body: "Bad request".into(),
        data: None,
    };
    assert!(r.is_validation_error());
}

#[test]
fn api_response_conflict() {
    let r = ApiResponse {
        status_code: 409,
        raw_body: "Conflict".into(),
        data: None,
    };
    assert!(r.is_conflict());
}

#[test]
fn api_response_serde_roundtrip() {
    let r = ApiResponse {
        status_code: 200,
        raw_body: r#"{"ok":true}"#.into(),
        data: Some(serde_json::json!({"ok": true})),
    };
    let json = serde_json::to_string(&r).unwrap();
    let back: ApiResponse = serde_json::from_str(&json).unwrap();
    assert_eq!(back.status_code, 200);
    assert_eq!(back.data, Some(serde_json::json!({"ok": true})));
}

// ---------------------------------------------------------------------------
// FileEntry ordering
// ---------------------------------------------------------------------------

#[test]
fn file_entry_dirs_before_files() {
    let dir = FileEntry {
        name: "src".into(),
        path: "/project/src".into(),
        relative_path: "src".into(),
        is_directory: true,
        size: 0,
        modified: test_dt(),
    };
    let file = FileEntry {
        name: "README.md".into(),
        path: "/project/README.md".into(),
        relative_path: "README.md".into(),
        is_directory: false,
        size: 1024,
        modified: test_dt(),
    };
    assert!(dir < file);
    assert!(file > dir);
}

#[test]
fn file_entry_alphabetical_case_insensitive() {
    let a = FileEntry {
        name: "alpha.rs".into(),
        path: "/project/alpha.rs".into(),
        relative_path: "alpha.rs".into(),
        is_directory: false,
        size: 100,
        modified: test_dt(),
    };
    let b = FileEntry {
        name: "Beta.rs".into(),
        path: "/project/Beta.rs".into(),
        relative_path: "Beta.rs".into(),
        is_directory: false,
        size: 200,
        modified: test_dt(),
    };
    assert!(a < b);
}

#[test]
fn file_entry_sorting() {
    let mut entries = vec![
        FileEntry {
            name: "main.rs".into(),
            path: "/p/main.rs".into(),
            relative_path: "main.rs".into(),
            is_directory: false,
            size: 100,
            modified: test_dt(),
        },
        FileEntry {
            name: "src".into(),
            path: "/p/src".into(),
            relative_path: "src".into(),
            is_directory: true,
            size: 0,
            modified: test_dt(),
        },
        FileEntry {
            name: "Cargo.toml".into(),
            path: "/p/Cargo.toml".into(),
            relative_path: "Cargo.toml".into(),
            is_directory: false,
            size: 500,
            modified: test_dt(),
        },
        FileEntry {
            name: "tests".into(),
            path: "/p/tests".into(),
            relative_path: "tests".into(),
            is_directory: true,
            size: 0,
            modified: test_dt(),
        },
    ];
    entries.sort();
    assert_eq!(entries[0].name, "src");
    assert_eq!(entries[1].name, "tests");
    assert_eq!(entries[2].name, "Cargo.toml");
    assert_eq!(entries[3].name, "main.rs");
}

#[test]
fn file_entry_equality_by_path() {
    let a = FileEntry {
        name: "file.rs".into(),
        path: "/project/file.rs".into(),
        relative_path: "file.rs".into(),
        is_directory: false,
        size: 100,
        modified: test_dt(),
    };
    let b = FileEntry {
        name: "file.rs".into(),
        path: "/project/file.rs".into(),
        relative_path: "file.rs".into(),
        is_directory: false,
        size: 999, // different size, same path
        modified: test_dt(),
    };
    assert_eq!(a, b);
}

// ---------------------------------------------------------------------------
// DeviceRegistrationRequest integer array serialization
// ---------------------------------------------------------------------------

#[test]
fn device_registration_request_int_array_serde() {
    let req = DeviceRegistrationRequest {
        name: "My PC".into(),
        device_type: "desktop".into(),
        platform: "windows".into(),
        identity_key: vec![1, 2, 3, 4, 5, 6, 7, 8],
        signed_pre_key: vec![10, 20, 30, 40],
        signed_pre_key_id: 42,
        signed_pre_key_signature: vec![100, 200],
        one_time_pre_keys: vec![PreKey {
            key_id: 1,
            key: vec![50, 60, 70],
        }],
    };

    let json = serde_json::to_string(&req).unwrap();

    // Verify integer array encoding (matches Dart's Uint8List.toList())
    assert!(json.contains("[1,2,3,4,5,6,7,8]")); // identity_key
    assert!(json.contains("[10,20,30,40]")); // signed_pre_key
    assert!(json.contains("[100,200]")); // signed_pre_key_signature

    // Verify snake_case field names (matches backend expectations)
    assert!(json.contains("\"identity_key\"")); // not camelCase
    assert!(json.contains("\"device_type\"")); // not camelCase
    assert!(json.contains("\"signed_pre_key_id\"")); // not camelCase

    let back: DeviceRegistrationRequest = serde_json::from_str(&json).unwrap();
    assert_eq!(req, back);
}

#[test]
fn device_registration_request_empty_pre_keys() {
    let req = DeviceRegistrationRequest {
        name: "Phone".into(),
        device_type: "mobile".into(),
        platform: "ios".into(),
        identity_key: vec![0; 32],
        signed_pre_key: vec![0; 32],
        signed_pre_key_id: 1,
        signed_pre_key_signature: vec![0; 64],
        one_time_pre_keys: vec![],
    };
    let json = serde_json::to_string(&req).unwrap();
    let back: DeviceRegistrationRequest = serde_json::from_str(&json).unwrap();
    assert_eq!(req, back);
    assert!(back.one_time_pre_keys.is_empty());
}

// ---------------------------------------------------------------------------
// AuthState factory methods
// ---------------------------------------------------------------------------

#[test]
fn auth_state_anonymous() {
    let state = AuthState::anonymous();
    assert_eq!(state.mode, AuthMode::Anonymous);
    assert!(state.token.is_none());
    assert!(state.token_scope.is_none());
    assert!(state.username.is_none());
    assert!(state.email.is_none());
    assert!(state.device_id.is_none());
}

#[test]
fn auth_state_undetermined() {
    let state = AuthState::undetermined();
    assert_eq!(state.mode, AuthMode::Undetermined);
    assert!(state.token.is_none());
}

#[test]
fn auth_state_serde_roundtrip() {
    let state = AuthState {
        mode: AuthMode::Connected,
        token: Some("jwt-value".into()),
        token_scope: Some(TokenScope::Full),
        username: Some("oak".into()),
        email: Some("oak@example.com".into()),
        device_id: Some("dev-1".into()),
    };
    let json = serde_json::to_string(&state).unwrap();
    let back: AuthState = serde_json::from_str(&json).unwrap();
    assert_eq!(state, back);
}

// ---------------------------------------------------------------------------
// Update request partial update pattern
// ---------------------------------------------------------------------------

#[test]
fn update_agent_template_request_all_none() {
    let req = UpdateAgentTemplateRequest {
        name: None,
        source_type: None,
        source_path: None,
        git_url: None,
        git_branch: None,
        entry_point: None,
        description: None,
        readme: None,
        required_env: None,
        required_mounts: None,
        fields: None,
        hub_slug: None,
        hub_author: None,
        hub_category: None,
        hub_tags: None,
        hub_version: None,
        hub_repo_url: None,
        hub_commit_hash: None,
    };
    let json = serde_json::to_string(&req).unwrap();
    // All None fields should be omitted
    assert_eq!(json, "{}");
}

#[test]
fn update_agent_template_request_partial() {
    let json = r#"{"name":"New Name","entryPoint":"run.py"}"#;
    let req: UpdateAgentTemplateRequest = serde_json::from_str(json).unwrap();
    assert_eq!(req.name, Some("New Name".into()));
    assert_eq!(req.entry_point, Some("run.py".into()));
    assert!(req.source_type.is_none());
    assert!(req.description.is_none());
}
