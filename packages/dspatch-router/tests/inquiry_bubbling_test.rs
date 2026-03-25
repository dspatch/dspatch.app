use dspatch_router::host_router::HostRouter;
use dspatch_router::config::AgentMeta;
use std::collections::HashMap;

fn three_tier_agents() -> HashMap<String, AgentMeta> {
    let mut agents = HashMap::new();
    agents.insert("lead".into(), AgentMeta {
        is_root: true, peers: vec!["coder".into()], fields: HashMap::new(),
    });
    agents.insert("coder".into(), AgentMeta {
        is_root: false, peers: vec!["lead".into(), "intern".into()], fields: HashMap::new(),
    });
    agents.insert("intern".into(), AgentMeta {
        is_root: false, peers: vec!["coder".into()], fields: HashMap::new(),
    });
    agents
}

#[tokio::test]
async fn inquiry_routes_to_supervisor_first() {
    let router = HostRouter::new(three_tier_agents());
    router.spawn_instance("lead", "lead-0", vec![]);
    router.spawn_instance("coder", "coder-0", vec![]);

    let supervisor = router.supervisor_for("coder");
    assert_eq!(supervisor, Some("lead".to_string()));
}

#[tokio::test]
async fn inquiry_surfaces_to_engine_when_no_supervisor() {
    let router = HostRouter::new(three_tier_agents());
    router.spawn_instance("lead", "lead-0", vec![]);

    let supervisor = router.supervisor_for("lead");
    assert!(supervisor.is_none());
}

#[tokio::test]
async fn resolve_inquiry_resolves_pending_bubble() {
    let router = HostRouter::new(three_tier_agents());
    router.spawn_instance("coder", "coder-0", vec![]);

    let inquiry_id = "inq-1";
    router.register_pending_inquiry(inquiry_id, "coder", "coder-0");

    let resolved = router.resolve_inquiry(inquiry_id, serde_json::json!({
        "response_text": "Approved",
    }));
    assert!(resolved);
}
