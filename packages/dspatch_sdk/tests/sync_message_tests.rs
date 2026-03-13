use dspatch_sdk::sync::message::{RemoteCommand, SyncMessage, CommandResult};

#[test]
fn remote_command_serializes_roundtrip() {
    let cmd = SyncMessage::Command(RemoteCommand {
        command_id: "cmd_1".into(),
        method: "send_user_input".into(),
        params: serde_json::json!({
            "workspace_id": "ws1",
            "run_id": "run1",
            "instance_id": "inst1",
            "content": "Hello"
        }),
    });

    let json = serde_json::to_string(&cmd).unwrap();
    let parsed: SyncMessage = serde_json::from_str(&json).unwrap();

    match parsed {
        SyncMessage::Command(rc) => {
            assert_eq!(rc.command_id, "cmd_1");
            assert_eq!(rc.method, "send_user_input");
        }
        other => panic!("Expected Command, got {other:?}"),
    }
}

#[test]
fn command_result_serializes_roundtrip() {
    let result = SyncMessage::CommandResult(CommandResult {
        command_id: "cmd_1".into(),
        success: true,
        error: None,
    });

    let json = serde_json::to_string(&result).unwrap();
    let parsed: SyncMessage = serde_json::from_str(&json).unwrap();

    match parsed {
        SyncMessage::CommandResult(cr) => {
            assert_eq!(cr.command_id, "cmd_1");
            assert!(cr.success);
            assert!(cr.error.is_none());
        }
        other => panic!("Expected CommandResult, got {other:?}"),
    }
}
