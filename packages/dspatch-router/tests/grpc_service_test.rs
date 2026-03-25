use dspatch_router::grpc_service::DspatchRouterService;
use dspatch_router::proto::*;
use dspatch_router::proto::dspatch_router_server::DspatchRouter;
use dspatch_router::host_router::HostRouter;
use dspatch_router::config::AgentMeta;
use std::collections::HashMap;
use std::sync::Arc;
use tonic::Request;

fn test_service() -> DspatchRouterService {
    let mut agents = HashMap::new();
    agents.insert("lead".into(), AgentMeta {
        is_root: true,
        peers: vec![],
        fields: HashMap::new(),
    });
    let router = Arc::new(HostRouter::new(agents));
    DspatchRouterService::new(router)
}

#[tokio::test]
async fn register_succeeds() {
    let svc = test_service();
    let req = Request::new(RegisterRequest {
        name: "lead".into(),
        role: "host".into(),
        capabilities: vec![],
    });
    let resp = svc.register(req).await.unwrap();
    assert!(resp.into_inner().ok);
}

#[tokio::test]
async fn send_output_succeeds() {
    let svc = test_service();
    svc.router().spawn_instance("lead", "lead-0", vec![]);

    let req = Request::new(OutputEvent {
        instance_id: "lead-0".into(),
        output: Some(output_event::Output::Log(LogOutput {
            level: "info".into(),
            message: "test log".into(),
        })),
    });
    let resp = svc.send_output(req).await.unwrap();
    assert!(resp.into_inner().ok);
}

#[tokio::test]
async fn complete_turn_transitions_to_idle() {
    let svc = test_service();
    svc.router().spawn_instance("lead", "lead-0", vec![]);

    {
        let ir = svc.router().get_instance_router("lead-0").unwrap();
        ir.state_machine().lock().enter_generating().unwrap();
    }

    let req = Request::new(CompleteTurnRequest {
        instance_id: "lead-0".into(),
        turn_id: "t1".into(),
        result: None,
    });
    let resp = svc.complete_turn(req).await.unwrap();
    assert!(resp.into_inner().ok);

    let ir = svc.router().get_instance_router("lead-0").unwrap();
    assert_eq!(
        ir.state_machine().lock().state(),
        dspatch_router::instance_router::InstanceState::Idle
    );
}
