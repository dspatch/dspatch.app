use dspatch_router::proto::*;

#[test]
fn register_request_roundtrip() {
    let req = RegisterRequest {
        name: "lead".into(),
        role: "host".into(),
        capabilities: vec!["talk_to".into(), "inquire".into()],
    };
    assert_eq!(req.name, "lead");
    assert_eq!(req.role, "host");
    assert_eq!(req.capabilities.len(), 2);
}

#[test]
fn router_event_oneof_variants() {
    let event = RouterEvent {
        instance_id: "lead-0".into(),
        turn_id: "turn-1".into(),
        event: Some(router_event::Event::UserInput(UserInputEvent {
            text: "hello".into(),
            history: vec![],
        })),
    };
    assert!(matches!(
        event.event,
        Some(router_event::Event::UserInput(_))
    ));
}

#[test]
fn talk_to_response_oneof_variants() {
    let resp = TalkToRpcResponse {
        result: Some(talk_to_rpc_response::Result::Success(TalkToSuccess {
            request_id: "req-1".into(),
            response: "done".into(),
            conversation_id: "conv-1".into(),
        })),
    };
    assert!(matches!(
        resp.result,
        Some(talk_to_rpc_response::Result::Success(_))
    ));

    let interrupt_resp = TalkToRpcResponse {
        result: Some(talk_to_rpc_response::Result::Interrupt(InquiryInterrupt {
            inquiry_id: "inq-1".into(),
            from_agent: "coder".into(),
            content_markdown: "Need help".into(),
            suggestions: vec!["Yes".into(), "No".into()],
            priority: "normal".into(),
        })),
    };
    assert!(matches!(
        interrupt_resp.result,
        Some(talk_to_rpc_response::Result::Interrupt(_))
    ));
}

#[test]
fn output_event_oneof_variants() {
    let output = OutputEvent {
        instance_id: "lead-0".into(),
        output: Some(output_event::Output::Message(MessageOutput {
            id: "msg-1".into(),
            role: "assistant".into(),
            content: "Hello".into(),
            is_delta: false,
            model: Some("claude-sonnet-4-5-20250514".into()),
            input_tokens: Some(100),
            output_tokens: Some(50),
            sender_name: None,
        })),
    };
    assert!(matches!(
        output.output,
        Some(output_event::Output::Message(_))
    ));
}
