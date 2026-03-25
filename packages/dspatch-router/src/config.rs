use anyhow::{Context, Result};
use serde::Deserialize;
use std::collections::HashMap;
use std::env;

#[derive(Debug, Clone, Deserialize)]
pub struct AgentMeta {
    pub is_root: bool,
    pub peers: Vec<String>,
    pub fields: HashMap<String, String>,
}

#[derive(Debug, Clone)]
pub struct RouterConfig {
    pub api_url: String,
    pub api_key: String,
    pub run_id: String,
    pub workspace_id: String,
    pub agents_meta: HashMap<String, AgentMeta>,
    pub wal_path: String,
    pub grpc_socket: String,
}

impl RouterConfig {
    pub fn from_env() -> Result<Self> {
        let agents_meta_json = env::var("DSPATCH_AGENTS_META")
            .context("DSPATCH_AGENTS_META not set")?;
        let agents_meta: HashMap<String, AgentMeta> =
            serde_json::from_str(&agents_meta_json)
                .context("Failed to parse DSPATCH_AGENTS_META")?;

        Ok(Self {
            api_url: env::var("DSPATCH_API_URL").context("DSPATCH_API_URL not set")?,
            api_key: env::var("DSPATCH_API_KEY").context("DSPATCH_API_KEY not set")?,
            run_id: env::var("DSPATCH_RUN_ID").context("DSPATCH_RUN_ID not set")?,
            workspace_id: env::var("DSPATCH_WORKSPACE_ID")
                .context("DSPATCH_WORKSPACE_ID not set")?,
            agents_meta,
            wal_path: env::var("DSPATCH_WAL_PATH")
                .unwrap_or_else(|_| "/data/dspatch.wal".into()),
            grpc_socket: env::var("DSPATCH_GRPC_SOCKET")
                .unwrap_or_else(|_| "/tmp/dspatch.sock".into()),
        })
    }

    pub fn ws_url(&self) -> String {
        let base = self.api_url.replace("http://", "ws://").replace("https://", "wss://");
        format!("{}/ws/{}", base.trim_end_matches('/'), self.run_id)
    }

    pub fn supervision_hierarchy(&self) -> HashMap<String, Option<String>> {
        let root_keys: Vec<&str> = self.agents_meta.iter()
            .filter(|(_, m)| m.is_root)
            .map(|(k, _)| k.as_str())
            .collect();
        let root = root_keys.first().copied();

        self.agents_meta.keys()
            .map(|k| {
                let supervisor = if self.agents_meta[k].is_root {
                    None
                } else {
                    root.map(|r| r.to_string())
                };
                (k.clone(), supervisor)
            })
            .collect()
    }
}
