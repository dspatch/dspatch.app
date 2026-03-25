use dspatch_router::instance_router::{InstanceState, StateMachine, PendingWait};

#[test]
fn initial_state_is_idle() {
    let sm = StateMachine::new();
    assert_eq!(sm.state(), InstanceState::Idle);
    assert!(sm.pending_wait().is_none());
}

#[test]
fn idle_to_generating() {
    let mut sm = StateMachine::new();
    sm.enter_generating().unwrap();
    assert_eq!(sm.state(), InstanceState::Generating);
}

#[test]
fn generating_to_waiting_for_agent() {
    let mut sm = StateMachine::new();
    sm.enter_generating().unwrap();
    sm.enter_waiting_for_agent("req-1".into(), "coder".into()).unwrap();
    assert_eq!(sm.state(), InstanceState::WaitingForAgent);
    let pw = sm.pending_wait().unwrap();
    assert_eq!(pw.request_id, "req-1");
    assert_eq!(pw.peer.as_deref(), Some("coder"));
}

#[test]
fn exit_waiting_clears_pending() {
    let mut sm = StateMachine::new();
    sm.enter_generating().unwrap();
    sm.enter_waiting_for_agent("req-1".into(), "coder".into()).unwrap();
    sm.exit_waiting("req-1").unwrap();
    assert_eq!(sm.state(), InstanceState::Generating);
    assert!(sm.pending_wait().is_none());
}

#[test]
fn exit_waiting_wrong_id_fails() {
    let mut sm = StateMachine::new();
    sm.enter_generating().unwrap();
    sm.enter_waiting_for_agent("req-1".into(), "coder".into()).unwrap();
    assert!(sm.exit_waiting("wrong-id").is_err());
}

#[test]
fn invalid_transition_fails() {
    let mut sm = StateMachine::new();
    assert!(sm.enter_waiting_for_agent("req-1".into(), "coder".into()).is_err());
}

#[test]
fn receive_unexpected_preserves_pending_wait() {
    let mut sm = StateMachine::new();
    sm.enter_generating().unwrap();
    sm.enter_waiting_for_agent("req-1".into(), "coder".into()).unwrap();
    sm.receive_unexpected();
    assert_eq!(sm.state(), InstanceState::Generating);
    assert!(sm.pending_wait().is_some());
    assert_eq!(sm.pending_wait().unwrap().request_id, "req-1");
}

#[test]
fn state_change_callback_fires() {
    use std::sync::{Arc, Mutex};

    let changes: Arc<Mutex<Vec<(InstanceState, InstanceState)>>> = Arc::new(Mutex::new(vec![]));
    let changes_clone = changes.clone();

    let mut sm = StateMachine::new();
    sm.set_on_state_changed(move |old, new| {
        changes_clone.lock().unwrap().push((old, new));
    });

    sm.enter_generating().unwrap();
    sm.enter_idle().unwrap();

    let recorded = changes.lock().unwrap();
    assert_eq!(recorded.len(), 2);
    assert_eq!(recorded[0], (InstanceState::Idle, InstanceState::Generating));
    assert_eq!(recorded[1], (InstanceState::Generating, InstanceState::Idle));
}
