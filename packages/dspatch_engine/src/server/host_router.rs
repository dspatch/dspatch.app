// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Central routing facade for the dspatch Host Router.
//!
//! Composes ConnectionService, EventService, CommunicationService,
//! StatusService, and PackageInspectorService. Handles all delegate wiring
//! so that EmbeddedAgentServer stays a thin HTTP shell.
//!
//! Ported from `server/host_router.dart`.

use std::collections::{HashMap, HashSet};
use std::sync::Arc;

use parking_lot::Mutex as ParkingMutex;

use axum::extract::ws::WebSocket;

use crate::db::dao::WorkspaceDao;
use crate::domain::enums::{AgentState, LogLevel, LogSource};
use crate::domain::models::AgentLog;
use crate::util::new_id;
use crate::workspace_config::flat_agent::FlatAgent;

use super::communication::CommunicationService;
use super::connection::ConnectionService;
use super::event::EventService;
use crate::db::dao::workspace_run_status_dao::WorkspaceRunStatusDao;

use super::inspector::PackageInspectorService;
use super::status::StatusService;

/// Central routing facade for the dspatch Host Router.
///
/// Composes all server services and wires their callbacks.
pub struct HostRouter {
    pub connection_service: Arc<ConnectionService>,
    pub event_service: Arc<EventService>,
    pub communication_service: Arc<CommunicationService>,
    pub status_service: Arc<StatusService>,
    pub package_inspector: Arc<PackageInspectorService>,
    workspace_dao: Arc<WorkspaceDao>,

    /// Runs that have already been promoted from "starting" -> "running".
    promoted_runs: tokio::sync::Mutex<HashSet<String>>,

    /// Tracks the last time a heartbeat was logged per (run_id, agent_name).
    /// Used to throttle heartbeat logging to once per 3 minutes.
    heartbeat_log_times: ParkingMutex<HashMap<(String, String), std::time::Instant>>,

    /// Tracks all spawned tasks so panics can be detected and tasks can be
    /// joined on shutdown rather than abandoned fire-and-forget.
    ///
    /// Uses a sync `parking_lot::Mutex` so that the `Fn` closures wired into
    /// the service delegates (which are sync) can call `JoinSet::spawn`
    /// (which is also sync and only requires `&mut JoinSet`) without needing
    /// to `.await` a lock.
    join_set: ParkingMutex<tokio::task::JoinSet<()>>,
}

impl HostRouter {
    pub fn new(
        workspace_dao: Arc<WorkspaceDao>,
        dev_mode: bool,
    ) -> Arc<Self> {
        let inspector = Arc::new(if dev_mode {
            PackageInspectorService::default_enabled()
        } else {
            PackageInspectorService::default_disabled()
        });

        let connection_service = Arc::new(ConnectionService::new(Some(Arc::clone(&inspector))));
        let event_service = Arc::new(EventService::with_default_interval(
            Arc::clone(&workspace_dao),
        ));
        let communication_service = Arc::new(CommunicationService::new(
            Arc::clone(&workspace_dao),
        ));
        let status_service = Arc::new(StatusService::new(
            Arc::clone(&workspace_dao),
            Arc::clone(&event_service),
        ));

        Arc::new(Self {
            connection_service,
            event_service,
            communication_service,
            status_service,
            package_inspector: inspector,
            workspace_dao,
            promoted_runs: tokio::sync::Mutex::new(HashSet::new()),
            heartbeat_log_times: ParkingMutex::new(HashMap::new()),
            join_set: ParkingMutex::new(tokio::task::JoinSet::new()),
        })
    }

    // ── Lifecycle ──

    pub async fn start(self: &Arc<Self>) {
        // Wire all delegates before starting the event service to avoid
        // a race where the router is used before wiring completes.
        self.wire_services().await;
        self.event_service.start().await;
    }

    pub async fn dispose(&self) {
        self.event_service.dispose().await;
        // Move the JoinSet out of the Mutex so we can await it freely without
        // holding the parking_lot lock across await points.
        let mut js = std::mem::replace(
            &mut *self.join_set.lock(),
            tokio::task::JoinSet::new(),
        );
        while let Some(result) = js.join_next().await {
            if let Err(e) = result {
                tracing::error!("Host router task panicked on shutdown: {e:?}");
            }
        }
    }

    /// Drain any completed tasks and log panics. Call this from a hot path to
    /// surface task failures without blocking.
    fn drain_join_set(&self) {
        let mut js = self.join_set.lock();
        while let Some(result) = js.try_join_next() {
            if let Err(e) = result {
                tracing::error!("Host router task panicked: {e:?}");
            }
        }
    }

    /// Spawn a future into the tracked JoinSet.
    ///
    /// Using a method rather than `self.join_set.lock().spawn(fut)` inline
    /// avoids borrow-checker conflicts: the guard borrows `self` only for the
    /// duration of this call, while `fut` may already hold a clone of
    /// `Arc<Self>` that was captured before this call.
    fn spawn_task<F>(&self, fut: F)
    where
        F: std::future::Future<Output = ()> + Send + 'static,
    {
        self.join_set.lock().spawn(fut);
    }

    // ── Run management ──

    pub async fn register_run(&self, run_id: &str, api_key: &str) {
        self.connection_service.register_run(run_id, api_key).await;
    }

    pub async fn deregister_run(&self, run_id: &str) {
        self.connection_service.deregister_run(run_id).await;
        self.package_inspector.clear_run(run_id);
        self.promoted_runs.lock().await.remove(run_id);
    }

    // ── WebSocket handler ──

    pub async fn handle_agent(
        self: &Arc<Self>,
        ws: WebSocket,
        run_id: String,
        agent_name: String,
    ) {
        self.connection_service
            .handle_agent(ws, run_id, agent_name)
            .await;
    }

    // ── Workspace registration (delegates to EventService) ──

    pub async fn register_workspace(
        &self,
        workspace_id: &str,
        agents: &[FlatAgent],
    ) {
        self.event_service
            .register_workspace(workspace_id, agents)
            .await;
    }

    pub fn register_workspace_run(
        &self,
        workspace_id: &str,
        run_id: &str,
    ) {
        self.event_service
            .register_workspace_run(workspace_id, run_id);
    }

    pub fn deregister_workspace_run(&self, workspace_id: &str) {
        self.event_service
            .deregister_workspace_run(workspace_id);
    }

    // ── Internal: promote run ──

    async fn promote_run_if_starting(&self, run_id: &str) {
        {
            let promoted = self.promoted_runs.lock().await;
            if promoted.contains(run_id) {
                return;
            }
        }

        let now = chrono::Utc::now().naive_utc();
        if self
            .workspace_dao
            .update_run_status(run_id, "running", Some(&now))
            .is_ok()
        {
            self.promoted_runs
                .lock()
                .await
                .insert(run_id.to_string());
            tracing::info!("Workspace run promoted: starting -> running (first heartbeat)");
            let conn = self.workspace_dao.db().conn();
            let _ = WorkspaceRunStatusDao::new().upsert(&conn, run_id, "running");
        }
    }

    // ── Internal wiring ──

    async fn wire_services(self: &Arc<Self>) {
        // EventService.on_output_packet -> CommunicationService
        {
            let comm = Arc::clone(&self.communication_service);
            *self.event_service.on_output_packet.lock().await = Some(Arc::new(
                move |workspace_id: String,
                      agent_key: String,
                      run_id: String,
                      event: super::packages::Package| {
                    comm.handle_output_packet(&workspace_id, &agent_key, &run_id, &event);
                },
            ));
        }

        // EventService.on_turn_completed -> StatusService.handle_turn_completed
        {
            let ss = Arc::clone(&self.status_service);
            let router1 = Arc::clone(self);
            *self.event_service.on_turn_completed.lock().await = Some(Arc::new(
                move |workspace_id: String,
                      agent_name: String,
                      instance_id: String,
                      turn_id: String,
                      transcript: String| {
                    let ss = Arc::clone(&ss);
                    let router = Arc::clone(&router1);
                    router.spawn_task(async move {
                        ss.handle_turn_completed(
                            &workspace_id,
                            &agent_name,
                            &instance_id,
                            &turn_id,
                            &transcript,
                        )
                        .await;
                    });
                },
            ));
        }

        // EventService.try_status_transition -> StatusService.try_transition
        //
        // This callback must return `JoinHandle<()>` because event.rs awaits it
        // as a synchronization point (`try_status_transition_async` does
        // `let _ = handle.await`).  We cannot use JoinSet::spawn here since it
        // returns AbortHandle, not JoinHandle.  Instead we use tokio::spawn
        // directly; if the task panics, event.rs sees the JoinError when it
        // awaits the handle (the error is discarded with `let _`, which is
        // pre-existing behaviour and acceptable for this callback).
        {
            let ss = Arc::clone(&self.status_service);
            *self.event_service.try_status_transition.lock().await = Some(Arc::new(
                move |workspace_id: String,
                      agent_key: String,
                      instance_id: String,
                      new_status: AgentState,
                      tag: String| {
                    let ss = Arc::clone(&ss);
                    tokio::spawn(async move {
                        ss.try_transition(
                            &workspace_id,
                            &agent_key,
                            &instance_id,
                            new_status,
                            &tag,
                        )
                        .await;
                    })
                },
            ));
        }

        // EventService transport delegates -> ConnectionService
        //
        // NOTE: send_to_host and send_to_instance use spawn_task() for async
        // operations, so they can return synchronously from the callback.
        {
            let conn = Arc::clone(&self.connection_service);
            let es = Arc::clone(&self.event_service);
            let router3 = Arc::clone(self);
            *self.event_service.send_to_host.lock().await = Some(Arc::new(
                move |workspace_id: &str,
                      agent_name: &str,
                      event: &super::packages::Package| {
                    let conn = Arc::clone(&conn);
                    let es_clone = Arc::clone(&es);
                    let ws_id = workspace_id.to_string();
                    let an = agent_name.to_string();
                    let evt = event.clone();
                    let router = Arc::clone(&router3);
                    router.spawn_task(async move {
                        let run_id = es_clone.active_run_id(&ws_id);
                        if let Some(run_id) = run_id {
                            conn.send_to_agent(&run_id, &an, &evt).await;
                        }
                    });
                    true
                },
            ));
        }

        {
            let conn = Arc::clone(&self.connection_service);
            let es = Arc::clone(&self.event_service);
            let router4 = Arc::clone(self);
            *self.event_service.send_to_instance.lock().await = Some(Arc::new(
                move |workspace_id: &str,
                      agent_name: &str,
                      instance_id: &str,
                      event: &super::packages::Package| {
                    let conn = Arc::clone(&conn);
                    let es_clone = Arc::clone(&es);
                    let ws_id = workspace_id.to_string();
                    let an = agent_name.to_string();
                    let iid = instance_id.to_string();
                    let evt = event.clone();
                    let router = Arc::clone(&router4);
                    router.spawn_task(async move {
                        let run_id = es_clone.active_run_id(&ws_id);
                        if let Some(run_id) = run_id {
                            // Inject instance_id into payload.
                            if let Ok(mut json_str) = evt.to_json() {
                                if let Ok(mut val) =
                                    serde_json::from_str::<serde_json::Value>(&json_str)
                                {
                                    val["instance_id"] =
                                        serde_json::Value::String(iid);
                                    json_str =
                                        serde_json::to_string(&val).unwrap_or(json_str);
                                }
                                conn.send_json_to_agent(&run_id, &an, &json_str).await;
                            }
                        }
                    });
                    true
                },
            ));
        }

        // is_host_connected: now fully sync since both active_run_id and
        // is_connected use std::sync::RwLock — no thread spawning needed.
        {
            let conn = Arc::clone(&self.connection_service);
            let es = Arc::clone(&self.event_service);
            *self.event_service.is_host_connected.lock().await = Some(Arc::new(
                move |workspace_id: &str, agent_name: &str| {
                    if let Some(run_id) = es.active_run_id(workspace_id) {
                        conn.is_connected(&run_id, agent_name)
                    } else {
                        false
                    }
                },
            ));
        }

        {
            let conn = Arc::clone(&self.connection_service);
            let es = Arc::clone(&self.event_service);
            *self.event_service.is_instance_connected.lock().await = Some(Arc::new(
                move |workspace_id: &str, agent_name: &str, instance_id: &str| {
                    if let Some(run_id) = es.active_run_id(workspace_id) {
                        conn.is_instance_alive(&run_id, agent_name, instance_id)
                    } else {
                        false
                    }
                },
            ));
        }

        {
            let conn = Arc::clone(&self.connection_service);
            let es = Arc::clone(&self.event_service);
            *self.event_service.get_instance_state.lock().await = Some(Arc::new(
                move |workspace_id: &str, agent_name: &str, instance_id: &str| {
                    if let Some(run_id) = es.active_run_id(workspace_id) {
                        conn.get_instance_state(&run_id, agent_name, instance_id)
                    } else {
                        None
                    }
                },
            ));
        }

        // EventService.connected_instances -> ConnectionService.connected_instances
        {
            let conn = Arc::clone(&self.connection_service);
            let es = Arc::clone(&self.event_service);
            *self.event_service.connected_instances.lock().await = Some(Arc::new(
                move |workspace_id: &str, agent_name: &str| {
                    if let Some(run_id) = es.active_run_id(workspace_id) {
                        conn.connected_instances(&run_id, agent_name)
                    } else {
                        vec![]
                    }
                },
            ));
        }

        // ConnectionService callbacks -> EventService, StatusService
        {
            let es = Arc::clone(&self.event_service);
            let router5 = Arc::clone(self);
            *self.connection_service.on_event_received.lock().await = Some(Arc::new(
                move |run_id: String,
                      agent_name: String,
                      event: super::packages::Package| {
                    let es = Arc::clone(&es);
                    let r_id = run_id.clone();
                    let router = Arc::clone(&router5);
                    router.spawn_task(async move {
                        let workspace_id = es.workspace_id_for_run(&r_id);
                        if let Some(workspace_id) = workspace_id {
                            es.handle_event(&workspace_id, &agent_name, event).await;
                        }
                    });
                },
            ));

            let es2 = Arc::clone(&self.event_service);
            let ss2 = Arc::clone(&self.status_service);
            let router6 = Arc::clone(self);
            *self.connection_service.on_agent_connected.lock().await = Some(Arc::new(
                move |run_id: String, agent_name: String| {
                    let es = Arc::clone(&es2);
                    let ss = Arc::clone(&ss2);
                    let router = Arc::clone(&router6);
                    router.spawn_task(async move {
                        let workspace_id = es.workspace_id_for_run(&run_id);
                        if let Some(ref ws_id) = workspace_id {
                            ss.handle_agent_connected(ws_id, &agent_name).await;
                            es.mark_pending_auto_start(ws_id, &agent_name).await;
                        }
                    });
                },
            ));

            let es3 = Arc::clone(&self.event_service);
            let ss3 = Arc::clone(&self.status_service);
            let router7 = Arc::clone(self);
            *self.connection_service.on_agent_disconnected.lock().await = Some(Arc::new(
                move |run_id: String, agent_name: String| {
                    let es = Arc::clone(&es3);
                    let ss = Arc::clone(&ss3);
                    let router = Arc::clone(&router7);
                    router.spawn_task(async move {
                        let workspace_id = es.workspace_id_for_run(&run_id);
                        if let Some(ref ws_id) = workspace_id {
                            ss.handle_agent_disconnected(ws_id, &agent_name).await;
                            es.on_agent_disconnected(ws_id, &agent_name).await;
                        }
                    });
                },
            ));

            let es4 = Arc::clone(&self.event_service);
            let dao = Arc::clone(&self.workspace_dao);
            let router_self = Arc::clone(self);
            *self.connection_service.on_heartbeat_received.lock().await = Some(Arc::new(
                move |run_id: String,
                      agent_name: String,
                      instances: std::collections::HashMap<String, String>| {
                    let es = Arc::clone(&es4);
                    let dao = Arc::clone(&dao);
                    let router = Arc::clone(&router_self);
                    let router_task = Arc::clone(&router);
                    let r_id = run_id.clone();
                    // Drain completed tasks on each heartbeat to surface panics promptly.
                    router.drain_join_set();
                    router.spawn_task(async move {
                        let router = router_task;
                        // Log heartbeat summary — throttled to once per 3 minutes.
                        let should_log = {
                            let mut times = router.heartbeat_log_times.lock();
                            let key = (r_id.clone(), agent_name.clone());
                            let now = std::time::Instant::now();
                            match times.get(&key) {
                                Some(last) if now.duration_since(*last).as_secs() < 180 => false,
                                _ => {
                                    times.insert(key, now);
                                    true
                                }
                            }
                        };
                        if should_log {
                            let summary: String = instances
                                .iter()
                                .map(|(k, v)| {
                                    let short = if k.len() > 6 { &k[..6] } else { k };
                                    format!("{}={}", short, v)
                                })
                                .collect::<Vec<_>>()
                                .join(", ");
                            let _ = dao.insert_agent_log(&AgentLog {
                                id: new_id(),
                                run_id: r_id.clone(),
                                agent_key: agent_name.clone(),
                                instance_id: String::new(),
                                turn_id: None,
                                level: LogLevel::Info,
                                message: format!("[heartbeat] {}", summary),
                                source: LogSource::Engine,
                                timestamp: chrono::Utc::now().naive_utc(),
                            });
                        }

                        let workspace_id = es.workspace_id_for_run(&r_id);
                        if let Some(ref ws_id) = workspace_id {
                            router.promote_run_if_starting(&r_id).await;
                            es.auto_start_if_needed(ws_id, &agent_name).await;
                        }
                    });
                },
            ));

            let es5 = Arc::clone(&self.event_service);
            let ss5 = Arc::clone(&self.status_service);
            let router8 = Arc::clone(self);
            *self
                .connection_service
                .on_instance_state_changed
                .lock()
                .await = Some(Arc::new(
                move |run_id: String,
                      agent_key: String,
                      instance_id: String,
                      old_state: Option<String>,
                      new_state: String| {
                    let es = Arc::clone(&es5);
                    let ss = Arc::clone(&ss5);
                    let router = Arc::clone(&router8);
                    router.spawn_task(async move {
                        let workspace_id = es.workspace_id_for_run(&run_id);
                        if let Some(ref ws_id) = workspace_id {
                            ss.handle_instance_state_changed(
                                ws_id,
                                &agent_key,
                                &instance_id,
                                old_state.as_deref(),
                                &new_state,
                            )
                            .await;
                        }
                    });
                },
            ));

            let es6 = Arc::clone(&self.event_service);
            let ss6 = Arc::clone(&self.status_service);
            let router9 = Arc::clone(self);
            *self.connection_service.on_instance_gone.lock().await = Some(Arc::new(
                move |run_id: String,
                      agent_name: String,
                      instance_id: String,
                      last_state: String| {
                    let es = Arc::clone(&es6);
                    let ss = Arc::clone(&ss6);
                    let router = Arc::clone(&router9);
                    router.spawn_task(async move {
                        let workspace_id = es.workspace_id_for_run(&run_id);
                        if let Some(ref ws_id) = workspace_id {
                            ss.handle_instance_gone(
                                ws_id,
                                &agent_name,
                                &instance_id,
                                &last_state,
                            )
                            .await;
                            es.on_instance_gone(ws_id, &agent_name, &instance_id)
                                .await;
                        }
                    });
                },
            ));
        }
    }
}
