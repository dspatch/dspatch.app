//! gRPC service implementation — bridges proto types to HostRouter operations.

use crate::host_router::HostRouter;
use crate::proto::dspatch_router_server::DspatchRouter;
use crate::proto::*;
use std::sync::Arc;
use tokio_stream::wrappers::ReceiverStream;
use tonic::{Request, Response, Status};

pub struct DspatchRouterService {
    router: Arc<HostRouter>,
}

impl DspatchRouterService {
    pub fn new(router: Arc<HostRouter>) -> Self {
        Self { router }
    }

    pub fn router(&self) -> &HostRouter {
        &self.router
    }
}

#[tonic::async_trait]
impl DspatchRouter for DspatchRouterService {
    async fn register(
        &self,
        request: Request<RegisterRequest>,
    ) -> Result<Response<RegisterResponse>, Status> {
        let req = request.into_inner();
        tracing::info!(name = %req.name, role = %req.role, "Agent registered");
        Ok(Response::new(RegisterResponse {
            ok: true,
            router_version: env!("CARGO_PKG_VERSION").to_string(),
        }))
    }

    type EventStreamStream = ReceiverStream<Result<RouterEvent, Status>>;

    async fn event_stream(
        &self,
        request: Request<EventStreamRequest>,
    ) -> Result<Response<Self::EventStreamStream>, Status> {
        let req = request.into_inner();
        let instance_id = req.instance_id.clone();

        let router = self.router.clone();
        let (tx, rx) = tokio::sync::mpsc::channel(256);

        tokio::spawn(async move {
            loop {
                match router.take_feed_item(&instance_id).await {
                    Some(item) => {
                        let event = feed_item_to_router_event(&instance_id, item);
                        if tx.send(Ok(event)).await.is_err() {
                            break;
                        }
                    }
                    None => break,
                }
            }
        });

        Ok(Response::new(ReceiverStream::new(rx)))
    }

    async fn send_output(
        &self,
        request: Request<OutputEvent>,
    ) -> Result<Response<Ack>, Status> {
        let output = request.into_inner();
        let json = output_event_to_json(&output);

        let tagged = if let Some(ir) = self.router.get_instance_router(&output.instance_id) {
            ir.tag_outbound(json)
        } else {
            json
        };

        let mut tagged = tagged;
        tagged["ts"] = serde_json::json!(chrono::Utc::now().timestamp_millis());

        self.router.relay_output(tagged);
        Ok(Response::new(Ack { ok: true }))
    }

    async fn complete_turn(
        &self,
        request: Request<CompleteTurnRequest>,
    ) -> Result<Response<Ack>, Status> {
        let req = request.into_inner();

        if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
            ir.pop_turn();
            let mut sm = ir.state_machine().lock();
            if let Err(e) = sm.enter_idle() {
                tracing::warn!(instance = %req.instance_id, error = %e, "Failed to transition to idle on CompleteTurn");
            }
            drop(sm);
            ir.flush();
        }

        if let Some(_result) = &req.result {
            tracing::debug!(instance = %req.instance_id, "Turn completed with result");
        }

        Ok(Response::new(Ack { ok: true }))
    }

    async fn talk_to(
        &self,
        request: Request<TalkToRpcRequest>,
    ) -> Result<Response<TalkToRpcResponse>, Status> {
        let req = request.into_inner();

        match self.router.initiate_talk_to(
            &req.instance_id,
            &req.target_agent,
            &req.text,
            req.continue_conversation,
        ).await {
            Ok((request_id, rx)) => {
                if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                    let mut sm = ir.state_machine().lock();
                    if let Err(e) = sm.enter_waiting_for_agent(request_id.clone(), req.target_agent.clone()) {
                        return Err(Status::failed_precondition(format!("State error: {}", e)));
                    }
                }

                match rx.await {
                    Ok(response) => {
                        if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                            let mut sm = ir.state_machine().lock();
                            let _ = sm.exit_waiting(&request_id);
                            drop(sm);
                            ir.flush();
                        }

                        let response_text = response.get("response").and_then(|v| v.as_str()).unwrap_or("").to_string();
                        let conv_id = response.get("conversation_id").and_then(|v| v.as_str()).unwrap_or("").to_string();

                        Ok(Response::new(TalkToRpcResponse {
                            result: Some(talk_to_rpc_response::Result::Success(TalkToSuccess {
                                request_id,
                                response: response_text,
                                conversation_id: conv_id,
                            })),
                        }))
                    }
                    Err(_) => {
                        if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                            ir.state_machine().lock().receive_unexpected();
                            ir.flush();
                        }
                        Ok(Response::new(TalkToRpcResponse {
                            result: Some(talk_to_rpc_response::Result::Error(TalkToError {
                                request_id: String::new(),
                                reason: "channel_closed".into(),
                            })),
                        }))
                    }
                }
            }
            Err(reason) => {
                Ok(Response::new(TalkToRpcResponse {
                    result: Some(talk_to_rpc_response::Result::Error(TalkToError {
                        request_id: String::new(),
                        reason,
                    })),
                }))
            }
        }
    }

    async fn resume_talk_to(
        &self,
        request: Request<ResumeTalkToRequest>,
    ) -> Result<Response<TalkToRpcResponse>, Status> {
        let req = request.into_inner();

        match self.router.resume_wait(&req.instance_id, &req.request_id).await {
            Ok(response) => {
                if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                    let mut sm = ir.state_machine().lock();
                    let _ = sm.exit_waiting(&req.request_id);
                    drop(sm);
                    ir.flush();
                }
                let response_text = response.get("response").and_then(|v| v.as_str()).unwrap_or("").to_string();
                let conv_id = response.get("conversation_id").and_then(|v| v.as_str()).unwrap_or("").to_string();
                Ok(Response::new(TalkToRpcResponse {
                    result: Some(talk_to_rpc_response::Result::Success(TalkToSuccess {
                        request_id: req.request_id,
                        response: response_text,
                        conversation_id: conv_id,
                    })),
                }))
            }
            Err(reason) => Ok(Response::new(TalkToRpcResponse {
                result: Some(talk_to_rpc_response::Result::Error(TalkToError {
                    request_id: req.request_id,
                    reason,
                })),
            })),
        }
    }

    async fn inquire(
        &self,
        request: Request<InquireRpcRequest>,
    ) -> Result<Response<InquireRpcResponse>, Status> {
        let req = request.into_inner();
        let inquiry_id = uuid::Uuid::new_v4().to_string();

        if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
            let mut sm = ir.state_machine().lock();
            if let Err(e) = sm.enter_waiting_for_inquiry(inquiry_id.clone()) {
                return Err(Status::failed_precondition(format!("State error: {}", e)));
            }
        }

        let rx = self.router.initiate_inquiry(
            &req.instance_id,
            &inquiry_id,
            &req.content_markdown,
            &req.suggestions,
            &req.file_paths,
            &req.priority,
        ).await;

        match rx.await {
            Ok(response) => {
                if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                    let mut sm = ir.state_machine().lock();
                    let _ = sm.exit_waiting(&inquiry_id);
                    drop(sm);
                    ir.flush();
                }
                let response_text = response.get("response_text").and_then(|v| v.as_str()).map(String::from);
                let suggestion_index = response.get("suggestion_index").and_then(|v| v.as_i64()).map(|v| v as i32);
                Ok(Response::new(InquireRpcResponse {
                    result: Some(inquire_rpc_response::Result::Success(InquireSuccess {
                        inquiry_id,
                        response_text,
                        suggestion_index,
                    })),
                }))
            }
            Err(_) => {
                if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                    ir.state_machine().lock().receive_unexpected();
                    ir.flush();
                }
                Ok(Response::new(InquireRpcResponse {
                    result: Some(inquire_rpc_response::Result::Error(InquireError {
                        inquiry_id,
                        reason: "channel_closed".into(),
                    })),
                }))
            }
        }
    }

    async fn resume_inquire(
        &self,
        request: Request<ResumeInquireRequest>,
    ) -> Result<Response<InquireRpcResponse>, Status> {
        let req = request.into_inner();

        match self.router.resume_wait(&req.instance_id, &req.inquiry_id).await {
            Ok(response) => {
                if let Some(ir) = self.router.get_instance_router(&req.instance_id) {
                    let mut sm = ir.state_machine().lock();
                    let _ = sm.exit_waiting(&req.inquiry_id);
                    drop(sm);
                    ir.flush();
                }
                let response_text = response.get("response_text").and_then(|v| v.as_str()).map(String::from);
                let suggestion_index = response.get("suggestion_index").and_then(|v| v.as_i64()).map(|v| v as i32);
                Ok(Response::new(InquireRpcResponse {
                    result: Some(inquire_rpc_response::Result::Success(InquireSuccess {
                        inquiry_id: req.inquiry_id,
                        response_text,
                        suggestion_index,
                    })),
                }))
            }
            Err(reason) => Ok(Response::new(InquireRpcResponse {
                result: Some(inquire_rpc_response::Result::Error(InquireError {
                    inquiry_id: req.inquiry_id,
                    reason,
                })),
            })),
        }
    }
}

// ── Conversion helpers ───────────────────────────────────────────────────

fn feed_item_to_router_event(
    instance_id: &str,
    item: crate::instance_router::FeedItem,
) -> RouterEvent {
    let event_type = item.event.get("type").and_then(|t| t.as_str()).unwrap_or("");
    let turn_id = item.event.get("turn_id").and_then(|t| t.as_str()).unwrap_or("").to_string();

    let event = match event_type {
        "agent.event.user_input" => {
            let text = item.event.get("text").and_then(|t| t.as_str()).unwrap_or("").to_string();
            let history = item.event.get("history")
                .and_then(|h| h.as_array())
                .map(|arr| arr.iter().filter_map(|m| {
                    Some(HistoryMessage {
                        id: m.get("id")?.as_str()?.to_string(),
                        role: m.get("role")?.as_str()?.to_string(),
                        content: m.get("content")?.as_str()?.to_string(),
                    })
                }).collect())
                .unwrap_or_default();

            router_event::Event::UserInput(UserInputEvent { text, history })
        }
        "agent.event.talk_to.request" => {
            router_event::Event::TalkToRequest(TalkToRequestEvent {
                request_id: item.event.get("request_id").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                caller_agent: item.event.get("caller_agent").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                text: item.event.get("text").and_then(|v| v.as_str()).unwrap_or("").to_string(),
            })
        }
        "agent.event.inquiry.request" => {
            router_event::Event::InquiryRequest(InquiryRequestEvent {
                inquiry_id: item.event.get("inquiry_id").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                from_agent: item.event.get("from_agent").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                content_markdown: item.event.get("content_markdown").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                suggestions: item.event.get("suggestions")
                    .and_then(|v| v.as_array())
                    .map(|arr| arr.iter().filter_map(|s| s.as_str().map(String::from)).collect())
                    .unwrap_or_default(),
                priority: item.event.get("priority").and_then(|v| v.as_str()).unwrap_or("normal").to_string(),
            })
        }
        "agent.signal.drain" => router_event::Event::Drain(DrainSignal {}),
        "agent.signal.terminate" => router_event::Event::Terminate(TerminateSignal {}),
        "agent.signal.interrupt" => router_event::Event::Interrupt(InterruptSignal {}),
        _ => {
            router_event::Event::UserInput(UserInputEvent {
                text: item.event.to_string(),
                history: vec![],
            })
        }
    };

    RouterEvent {
        instance_id: instance_id.to_string(),
        turn_id,
        event: Some(event),
    }
}

fn output_event_to_json(output: &OutputEvent) -> serde_json::Value {
    let instance_id = &output.instance_id;
    match &output.output {
        Some(output_event::Output::Message(m)) => serde_json::json!({
            "type": "agent.output.message",
            "instance_id": instance_id,
            "id": m.id,
            "role": m.role,
            "content": m.content,
            "is_delta": m.is_delta,
            "model": m.model,
            "input_tokens": m.input_tokens,
            "output_tokens": m.output_tokens,
            "sender_name": m.sender_name,
        }),
        Some(output_event::Output::Activity(a)) => serde_json::json!({
            "type": "agent.output.activity",
            "instance_id": instance_id,
            "id": a.id,
            "event_type": a.event_type,
            "content": a.content,
            "is_delta": a.is_delta,
            "data": a.data,
        }),
        Some(output_event::Output::Log(l)) => serde_json::json!({
            "type": "agent.output.log",
            "instance_id": instance_id,
            "level": l.level,
            "message": l.message,
        }),
        Some(output_event::Output::Usage(u)) => serde_json::json!({
            "type": "agent.output.usage",
            "instance_id": instance_id,
            "model": u.model,
            "input_tokens": u.input_tokens,
            "output_tokens": u.output_tokens,
            "cost_usd": u.cost_usd,
        }),
        Some(output_event::Output::Files(f)) => serde_json::json!({
            "type": "agent.output.files",
            "instance_id": instance_id,
            "files": f.files.iter().map(|e| serde_json::json!({
                "path": e.path,
                "action": e.action,
            })).collect::<Vec<_>>(),
        }),
        Some(output_event::Output::PromptReceived(p)) => serde_json::json!({
            "type": "agent.output.prompt_received",
            "instance_id": instance_id,
            "content": p.content,
            "sender_name": p.sender_name,
        }),
        None => serde_json::json!({"type": "unknown", "instance_id": instance_id}),
    }
}
