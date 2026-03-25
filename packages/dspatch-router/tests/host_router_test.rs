use dspatch_router::host_router::HostRouter;
use dspatch_router::config::AgentMeta;
use std::collections::HashMap;
use serde_json::json;

fn test_agents() -> HashMap<String, AgentMeta> {
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
    agents
}

#[tokio::test]
async fn spawn_instance_creates_agent_host() {
    let router = HostRouter::new(test_agents());
    router.spawn_instance("lead", "lead-0", vec![]);
    assert!(router.instance_exists("lead-0"));
}

#[tokio::test]
async fn cycle_detection_prevents_loop() {
    let router = HostRouter::new(test_agents());
    router.spawn_instance("lead", "lead-0", vec![]);
    router.spawn_instance("coder", "coder-0", vec![]);

    let _result = router.initiate_talk_to("lead-0", "coder", "hello", false).await;
    assert!(router.has_active_chain("lead-0"));
}

#[tokio::test]
async fn cycle_detection_rejects_cycle() {
    let router = HostRouter::new(test_agents());
    router.spawn_instance("lead", "lead-0", vec![]);
    router.spawn_instance("coder", "coder-0", vec![]);

    router.add_chain_link("req-1", "lead", "lead-0", "coder", vec!["lead".into()]);

    let has_cycle = router.would_create_cycle("coder-0", "lead");
    assert!(has_cycle);
}

#[tokio::test]
async fn inquiry_bubbling_to_supervisor() {
    let router = HostRouter::new(test_agents());
    router.spawn_instance("lead", "lead-0", vec![]);
    router.spawn_instance("coder", "coder-0", vec![]);

    let supervisor = router.supervisor_for("coder");
    assert_eq!(supervisor, Some("lead".to_string()));
}

#[tokio::test]
async fn route_inbound_to_correct_agent_host() {
    let router = HostRouter::new(test_agents());
    router.spawn_instance("lead", "lead-0", vec![]);

    let event = json!({
        "type": "agent.event.user_input",
        "instance_id": "lead-0",
        "text": "hello"
    });
    router.route_from_engine(event);

    let item = router.take_feed_item("lead-0").await;
    assert!(item.is_some());
}
