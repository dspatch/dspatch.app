//! Agent Instance Router — state machine, inbound routing, turn ID stack, buffer.
//!
//! Ported from:
//! - `packages/agent-sdk/sdk.python/dspatch/state_manager.py`
//! - `packages/agent-sdk/sdk.python/dspatch/instance_router.py`

use thiserror::Error;
use tokio::sync::mpsc;

// ── State machine ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum InstanceState {
    Idle,
    Generating,
    WaitingForAgent,
    WaitingForInquiry,
}

impl InstanceState {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Idle => "idle",
            Self::Generating => "generating",
            Self::WaitingForAgent => "waiting_for_agent",
            Self::WaitingForInquiry => "waiting_for_inquiry",
        }
    }

    fn valid_transitions(&self) -> &[InstanceState] {
        match self {
            Self::Idle => &[Self::Generating],
            Self::Generating => &[Self::Idle, Self::WaitingForAgent, Self::WaitingForInquiry],
            Self::WaitingForAgent => &[],
            Self::WaitingForInquiry => &[],
        }
    }
}

impl std::fmt::Display for InstanceState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

#[derive(Debug, Clone)]
pub struct PendingWait {
    pub wait_type: String,
    pub request_id: String,
    pub peer: Option<String>,
}

#[derive(Error, Debug)]
pub enum StateError {
    #[error("Invalid transition: {from} -> {to}")]
    InvalidTransition { from: InstanceState, to: InstanceState },
    #[error("No pending wait for request_id {0}")]
    WrongRequestId(String),
    #[error("exit_waiting called in state {0}")]
    NotWaiting(InstanceState),
}

type StateCallback = Box<dyn Fn(InstanceState, InstanceState) + Send + Sync>;

pub struct StateMachine {
    state: InstanceState,
    pending_wait: Option<PendingWait>,
    on_state_changed: Option<StateCallback>,
}

impl StateMachine {
    pub fn new() -> Self {
        Self {
            state: InstanceState::Idle,
            pending_wait: None,
            on_state_changed: None,
        }
    }

    pub fn state(&self) -> InstanceState {
        self.state
    }

    pub fn pending_wait(&self) -> Option<&PendingWait> {
        self.pending_wait.as_ref()
    }

    pub fn set_on_state_changed<F>(&mut self, f: F)
    where
        F: Fn(InstanceState, InstanceState) + Send + Sync + 'static,
    {
        self.on_state_changed = Some(Box::new(f));
    }

    pub fn enter_generating(&mut self) -> Result<(), StateError> {
        self.transition(InstanceState::Generating)
    }

    pub fn enter_idle(&mut self) -> Result<(), StateError> {
        self.transition(InstanceState::Idle)
    }

    pub fn enter_waiting_for_agent(
        &mut self,
        request_id: String,
        peer: String,
    ) -> Result<(), StateError> {
        self.transition(InstanceState::WaitingForAgent)?;
        self.pending_wait = Some(PendingWait {
            wait_type: "talk_to".into(),
            request_id,
            peer: Some(peer),
        });
        Ok(())
    }

    pub fn enter_waiting_for_inquiry(&mut self, inquiry_id: String) -> Result<(), StateError> {
        self.transition(InstanceState::WaitingForInquiry)?;
        self.pending_wait = Some(PendingWait {
            wait_type: "inquiry".into(),
            request_id: inquiry_id,
            peer: None,
        });
        Ok(())
    }

    pub fn exit_waiting(&mut self, consumed_request_id: &str) -> Result<(), StateError> {
        if !matches!(
            self.state,
            InstanceState::WaitingForAgent | InstanceState::WaitingForInquiry
        ) {
            return Err(StateError::NotWaiting(self.state));
        }
        match &self.pending_wait {
            Some(pw) if pw.request_id == consumed_request_id => {}
            _ => return Err(StateError::WrongRequestId(consumed_request_id.into())),
        }
        self.pending_wait = None;
        self.set_state(InstanceState::Generating);
        Ok(())
    }

    pub fn receive_unexpected(&mut self) {
        self.set_state(InstanceState::Generating);
    }

    fn transition(&mut self, to: InstanceState) -> Result<(), StateError> {
        if !self.state.valid_transitions().contains(&to) {
            return Err(StateError::InvalidTransition {
                from: self.state,
                to,
            });
        }
        self.set_state(to);
        Ok(())
    }

    fn set_state(&mut self, new: InstanceState) {
        let old = self.state;
        self.state = new;
        if let Some(cb) = &self.on_state_changed {
            cb(old, new);
        }
    }
}

// ── Feed item classification ─────────────────────────────────────────────

#[derive(Debug, Clone)]
pub enum FeedItemKind {
    Response,
    InquiryInterrupt,
    Input,
    Termination,
}

#[derive(Debug, Clone)]
pub struct FeedItem {
    pub kind: FeedItemKind,
    pub event: serde_json::Value,
}

const RESPONSE_EVENTS: &[&str] = &[
    "agent.event.talk_to.response",
    "agent.event.inquiry.response",
];
const INQUIRY_EVENTS: &[&str] = &["agent.event.inquiry.request"];
const TERMINATION_EVENTS: &[&str] = &[
    "agent.event.request.failed",
    "agent.event.inquiry.failed",
];
const CONTROL_EVENTS: &[&str] = &[
    "agent.signal.state_query",
    "agent.signal.terminate",
    "agent.signal.drain",
    "agent.signal.interrupt",
];
const KEEPALIVE_EVENTS: &[&str] = &[
    "agent.event.request.alive",
    "agent.event.inquiry.alive",
];
const OUTPUT_PREFIX: &str = "agent.output.";
const RESPONSE_OUTBOUND: &[&str] = &[
    "agent.event.talk_to.response",
    "agent.event.inquiry.response",
];

fn classify(event_type: &str) -> FeedItemKind {
    if RESPONSE_EVENTS.contains(&event_type) {
        FeedItemKind::Response
    } else if INQUIRY_EVENTS.contains(&event_type) {
        FeedItemKind::InquiryInterrupt
    } else if TERMINATION_EVENTS.contains(&event_type) {
        FeedItemKind::Termination
    } else {
        FeedItemKind::Input
    }
}

// ── Instance Router ──────────────────────────────────────────────────────

const MAX_BUFFER_SIZE: usize = 5000;
const FEED_CHANNEL_SIZE: usize = 5000;

pub struct InstanceRouter {
    instance_id: String,
    sm: parking_lot::Mutex<StateMachine>,
    buffer: parking_lot::Mutex<Vec<FeedItem>>,
    turn_stack: parking_lot::Mutex<Vec<String>>,
    feed_tx: mpsc::Sender<FeedItem>,
}

impl InstanceRouter {
    pub fn new(instance_id: String) -> (Self, mpsc::Receiver<FeedItem>) {
        let (tx, rx) = mpsc::channel(FEED_CHANNEL_SIZE);
        let router = Self {
            instance_id,
            sm: parking_lot::Mutex::new(StateMachine::new()),
            buffer: parking_lot::Mutex::new(Vec::new()),
            turn_stack: parking_lot::Mutex::new(Vec::new()),
            feed_tx: tx,
        };
        (router, rx)
    }

    pub fn instance_id(&self) -> &str {
        &self.instance_id
    }

    pub fn state_machine(&self) -> &parking_lot::Mutex<StateMachine> {
        &self.sm
    }

    pub fn buffer_len(&self) -> usize {
        self.buffer.lock().len()
    }

    pub fn peek_buffer(&self) -> Vec<FeedItem> {
        self.buffer.lock().clone()
    }

    // ── Turn ID stack ────────────────────────────────────────────────

    pub fn current_turn_id(&self) -> Option<String> {
        self.turn_stack.lock().last().cloned()
    }

    pub fn push_turn(&self, turn_id: Option<String>) -> String {
        let tid = turn_id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string()[..12].to_string());
        self.turn_stack.lock().push(tid.clone());
        tid
    }

    pub fn pop_turn(&self) -> Option<String> {
        self.turn_stack.lock().pop()
    }

    // ── Outbound tagging ─────────────────────────────────────────────

    pub fn tag_outbound(&self, mut event: serde_json::Value) -> serde_json::Value {
        let stack = self.turn_stack.lock();
        if let Some(tid) = stack.last() {
            if let Some(etype) = event.get("type").and_then(|t| t.as_str()) {
                if etype.starts_with(OUTPUT_PREFIX) || RESPONSE_OUTBOUND.contains(&etype) {
                    event["turn_id"] = serde_json::Value::String(tid.clone());
                }
            }
        }
        event
    }

    // ── Inbound routing ──────────────────────────────────────────────

    pub fn receive(&self, event: serde_json::Value) {
        let event_type = event.get("type").and_then(|t| t.as_str()).unwrap_or("");

        if CONTROL_EVENTS.contains(&event_type) || KEEPALIVE_EVENTS.contains(&event_type) {
            return;
        }

        let item = FeedItem {
            kind: classify(event_type),
            event,
        };

        let state = self.sm.lock().state();

        match state {
            InstanceState::Idle => {
                if matches!(item.kind, FeedItemKind::Input | FeedItemKind::InquiryInterrupt) {
                    self.feed_put(item);
                } else {
                    self.buffer_insert_capped(item);
                }
            }
            InstanceState::Generating => {
                self.buffer_insert_capped(item);
            }
            InstanceState::WaitingForAgent | InstanceState::WaitingForInquiry => {
                if matches!(
                    item.kind,
                    FeedItemKind::Response | FeedItemKind::Termination | FeedItemKind::InquiryInterrupt
                ) {
                    self.feed_put(item);
                } else {
                    self.buffer_insert_capped(item);
                }
            }
        }
    }

    pub fn flush(&self) {
        let mut buf = self.buffer.lock();
        let state = self.sm.lock().state();
        let mut remaining = Vec::new();
        for item in buf.drain(..) {
            if should_deliver(&item, state) {
                self.feed_put(item);
            } else {
                remaining.push(item);
            }
        }
        *buf = remaining;
    }

    fn feed_put(&self, item: FeedItem) {
        if self.feed_tx.try_send(item).is_err() {
            tracing::warn!(instance = %self.instance_id, "Feed channel full, dropping item");
        }
    }

    fn buffer_insert_capped(&self, item: FeedItem) {
        let mut buf = self.buffer.lock();
        if buf.len() >= MAX_BUFFER_SIZE {
            if let Some(pos) = buf.iter().position(|i| matches!(i.kind, FeedItemKind::Input)) {
                buf.remove(pos);
            } else {
                buf.remove(0);
            }
        }
        if matches!(item.kind, FeedItemKind::InquiryInterrupt) {
            if let Some(pos) = buf.iter().position(|i| matches!(i.kind, FeedItemKind::Input)) {
                buf.insert(pos, item);
                return;
            }
        }
        buf.push(item);
    }
}

fn should_deliver(item: &FeedItem, state: InstanceState) -> bool {
    match state {
        InstanceState::Idle => matches!(item.kind, FeedItemKind::Input | FeedItemKind::InquiryInterrupt),
        InstanceState::WaitingForAgent | InstanceState::WaitingForInquiry => {
            matches!(item.kind, FeedItemKind::Response | FeedItemKind::Termination | FeedItemKind::InquiryInterrupt)
        }
        InstanceState::Generating => false,
    }
}
