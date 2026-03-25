use dspatch_router::agent_host::AgentHostRouter;
use dspatch_router::instance_router::InstanceState;
use serde_json::json;

#[tokio::test]
async fn spawn_instance_creates_router() {
    let host = AgentHostRouter::new("lead".into());
    assert_eq!(host.instance_count(), 0);

    host.spawn_instance("lead-0".into(), vec![]);
    assert_eq!(host.instance_count(), 1);
    assert_eq!(host.instance_state("lead-0"), Some(InstanceState::Idle));
}

#[tokio::test]
async fn dispatch_routes_to_correct_instance() {
    let host = AgentHostRouter::new("coder".into());
    host.spawn_instance("coder-0".into(), vec![]);
    host.spawn_instance("coder-1".into(), vec![]);

    let event = json!({
        "type": "agent.event.user_input",
        "instance_id": "coder-1",
        "text": "hello"
    });
    host.dispatch(event);

    let feed = host.take_feed_item("coder-1").await;
    assert!(feed.is_some());
}

#[tokio::test]
async fn heartbeat_aggregates_all_instances() {
    let host = AgentHostRouter::new("lead".into());
    host.spawn_instance("lead-0".into(), vec![]);
    host.spawn_instance("lead-1".into(), vec![]);

    let hb = host.collect_heartbeat();
    assert_eq!(hb.len(), 2);
    assert!(hb.iter().any(|h| h.instance_id == "lead-0"));
    assert!(hb.iter().any(|h| h.instance_id == "lead-1"));
}

#[tokio::test]
async fn kill_instance_removes_it() {
    let host = AgentHostRouter::new("lead".into());
    host.spawn_instance("lead-0".into(), vec![]);
    assert_eq!(host.instance_count(), 1);

    host.kill_instance("lead-0");
    assert_eq!(host.instance_count(), 0);
}
