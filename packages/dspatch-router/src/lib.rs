pub mod agent_host;
pub mod config;
pub mod grpc_service;
pub mod host_router;
pub mod instance_router;
pub mod wal;
pub mod wire;
pub mod ws_client;

pub mod proto {
    tonic::include_proto!("dspatch.router");
}
