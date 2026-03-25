//! End-to-end test: gRPC client → router → verify output.
//! Does NOT test WebSocket (no engine running). Tests the gRPC path in isolation.

use dspatch_router::config::AgentMeta;
use dspatch_router::grpc_service::DspatchRouterService;
use dspatch_router::host_router::HostRouter;
use dspatch_router::proto::dspatch_router_server::DspatchRouter;
use dspatch_router::proto::*;
use std::collections::HashMap;
use std::sync::Arc;
use tonic::Request;

fn setup() -> (DspatchRouterService, Arc<HostRouter>) {
    let mut agents = HashMap::new();
    agents.insert("lead".into(), AgentMeta {
        is_root: true,
        peers: vec!["coder".into()],
        fields: HashMap::new(),
    });
    agents.insert("coder".into(), AgentMeta {
        is_root: false,
        peers: vec!["lead".into()],
        fields: HashMap::new(),
    });
    let router = Arc::new(HostRouter::new(agents));
    let svc = DspatchRouterService::new(router.clone());
    (svc, router)
}

#[tokio::test]
async fn full_lifecycle_register_stream_output_complete() {
    let (svc, router) = setup();

    // 1. Register
    let resp = svc
        .register(Request::new(RegisterRequest {
            name: "lead".into(),
            role: "host".into(),
            capabilities: vec![],
        }))
        .await
        .unwrap();
    assert!(resp.into_inner().ok);

    // 2. Spawn instance (simulating engine command)
    router.spawn_instance("lead", "lead-0", vec![]);

    // 3. Send output
    let resp = svc
        .send_output(Request::new(OutputEvent {
            instance_id: "lead-0".into(),
            output: Some(output_event::Output::Message(MessageOutput {
                id: "msg-1".into(),
                role: "assistant".into(),
                content: "Hello world".into(),
                is_delta: false,
                model: None,
                input_tokens: None,
                output_tokens: None,
                sender_name: None,
            })),
        }))
        .await
        .unwrap();
    assert!(resp.into_inner().ok);

    // 4. Complete turn
    {
        let ir = router.get_instance_router("lead-0").unwrap();
        ir.state_machine().lock().enter_generating().unwrap();
    }
    let resp = svc
        .complete_turn(Request::new(CompleteTurnRequest {
            instance_id: "lead-0".into(),
            turn_id: "t1".into(),
            result: None,
        }))
        .await
        .unwrap();
    assert!(resp.into_inner().ok);

    // Verify back to idle
    let ir = router.get_instance_router("lead-0").unwrap();
    assert_eq!(
        ir.state_machine().lock().state(),
        dspatch_router::instance_router::InstanceState::Idle
    );
}

#[tokio::test]
async fn talk_to_cycle_detection() {
    let (svc, router) = setup();
    router.spawn_instance("lead", "lead-0", vec![]);
    router.spawn_instance("coder", "coder-0", vec![]);

    // Simulate active chain: lead-0 → coder
    router.add_chain_link("req-existing", "lead", "lead-0", "coder", vec!["lead".into()]);

    // Put coder-0 in generating state
    if let Some(ir) = router.get_instance_router("coder-0") {
        ir.state_machine().lock().enter_generating().unwrap();
    }

    // coder-0 tries to talk back to lead — should be rejected
    let resp = svc
        .talk_to(Request::new(TalkToRpcRequest {
            instance_id: "coder-0".into(),
            target_agent: "lead".into(),
            text: "Need help".into(),
            continue_conversation: false,
        }))
        .await
        .unwrap();

    let inner = resp.into_inner();
    match inner.result {
        Some(talk_to_rpc_response::Result::Error(err)) => {
            assert_eq!(err.reason, "cycle_detected");
        }
        other => panic!("Expected Error with cycle_detected, got {:?}", other),
    }
}
