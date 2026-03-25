use dspatch_router::instance_router::{
    FeedItem, FeedItemKind, InstanceRouter, InstanceState,
};
use serde_json::json;

fn make_user_input(text: &str) -> serde_json::Value {
    json!({"type": "agent.event.user_input", "text": text, "instance_id": "lead-0"})
}

fn make_talk_to_response(request_id: &str) -> serde_json::Value {
    json!({"type": "agent.event.talk_to.response", "request_id": request_id, "response": "ok", "instance_id": "lead-0"})
}

fn make_inquiry_request(inquiry_id: &str) -> serde_json::Value {
    json!({"type": "agent.event.inquiry.request", "inquiry_id": inquiry_id, "content_markdown": "Help?", "instance_id": "lead-0"})
}

#[tokio::test]
async fn idle_delivers_user_input() {
    let (router, mut rx) = InstanceRouter::new("lead-0".into());
    router.receive(make_user_input("hello"));
    let item = rx.recv().await.unwrap();
    assert!(matches!(item.kind, FeedItemKind::Input));
}

#[tokio::test]
async fn generating_buffers_user_input() {
    let (router, mut rx) = InstanceRouter::new("lead-0".into());
    router.state_machine().lock().enter_generating().unwrap();
    router.receive(make_user_input("hello"));
    assert!(rx.try_recv().is_err());
    assert_eq!(router.buffer_len(), 1);
}

#[tokio::test]
async fn state_change_flushes_buffer() {
    let (router, mut rx) = InstanceRouter::new("lead-0".into());
    router.state_machine().lock().enter_generating().unwrap();
    router.receive(make_user_input("hello"));
    assert!(rx.try_recv().is_err());

    router.state_machine().lock().enter_idle().unwrap();
    router.flush();
    let item = rx.recv().await.unwrap();
    assert!(matches!(item.kind, FeedItemKind::Input));
}

#[tokio::test]
async fn waiting_delivers_response() {
    let (router, mut rx) = InstanceRouter::new("lead-0".into());
    {
        let mut sm = router.state_machine().lock();
        sm.enter_generating().unwrap();
        sm.enter_waiting_for_agent("req-1".into(), "coder".into()).unwrap();
    }
    router.receive(make_talk_to_response("req-1"));
    let item = rx.recv().await.unwrap();
    assert!(matches!(item.kind, FeedItemKind::Response));
}

#[tokio::test]
async fn inquiry_interrupt_has_priority() {
    let (router, _rx) = InstanceRouter::new("lead-0".into());
    router.state_machine().lock().enter_generating().unwrap();

    router.receive(make_user_input("hello"));
    router.receive(make_inquiry_request("inq-1"));

    let buffer = router.peek_buffer();
    assert!(matches!(buffer[0].kind, FeedItemKind::InquiryInterrupt));
    assert!(matches!(buffer[1].kind, FeedItemKind::Input));
}

#[test]
fn turn_id_stack() {
    let (router, _rx) = InstanceRouter::new("lead-0".into());
    assert!(router.current_turn_id().is_none());

    let t1 = router.push_turn(Some("turn-1".into()));
    assert_eq!(t1, "turn-1");
    assert_eq!(router.current_turn_id().unwrap(), "turn-1");

    let t2 = router.push_turn(None);
    assert_ne!(t2, "turn-1");
    assert_eq!(router.current_turn_id().unwrap(), t2);

    router.pop_turn();
    assert_eq!(router.current_turn_id().unwrap(), "turn-1");

    router.pop_turn();
    assert!(router.current_turn_id().is_none());
}

#[test]
fn tag_outbound_injects_turn_id() {
    let (router, _rx) = InstanceRouter::new("lead-0".into());
    router.push_turn(Some("turn-1".into()));

    let output = json!({"type": "agent.output.message", "content": "hi"});
    let tagged = router.tag_outbound(output);
    assert_eq!(tagged["turn_id"], "turn-1");

    let signal = json!({"type": "agent.signal.drain"});
    let not_tagged = router.tag_outbound(signal);
    assert!(not_tagged.get("turn_id").is_none());
}
