// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! In-memory session token store for the client API.

use std::collections::HashMap;
use std::sync::{Arc, RwLock};

use chrono::Utc;
use rand::Rng;

use crate::hub::HubApiClient;

/// Authentication mode for a session.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthMode {
    Anonymous,
    Connected,
}

/// A validated client session.
#[derive(Debug, Clone)]
pub struct Session {
    pub auth_mode: AuthMode,
    pub username: Option<String>,
    pub backend_token: Option<String>,
    pub expires_at: Option<i64>,
    pub device_id: Option<String>,
    pub identity_key_seed: Option<String>,
}

/// Thread-safe in-memory store mapping session tokens to sessions.
///
/// When a hub client is registered via [`set_hub_client`](Self::set_hub_client),
/// any backend token written through this store is automatically propagated
/// to the hub client's `Authorization` header.
pub struct SessionStore {
    sessions: RwLock<HashMap<String, Session>>,
    hub_client: RwLock<Option<Arc<HubApiClient>>>,
}

impl SessionStore {
    pub fn new() -> Self {
        Self {
            sessions: RwLock::new(HashMap::new()),
            hub_client: RwLock::new(None),
        }
    }

    /// Registers the hub client so that backend token updates are
    /// automatically forwarded to it.
    pub fn set_hub_client(&self, client: Arc<HubApiClient>) {
        *self.hub_client.write().unwrap() = Some(client);
    }

    /// Propagates a backend token to the hub client, if one is registered.
    fn sync_hub_token(&self, token: Option<&String>) {
        if let Some(hub) = self.hub_client.read().unwrap().as_ref() {
            hub.set_auth_token(token.cloned());
        }
    }

    pub fn create_session(
        &self,
        auth_mode: AuthMode,
        username: Option<String>,
        backend_token: Option<String>,
        expires_at: Option<i64>,
        device_id: Option<String>,
        identity_key_seed: Option<String>,
    ) -> String {
        self.sync_hub_token(backend_token.as_ref());
        let token = generate_token();
        let session = Session {
            auth_mode,
            username,
            backend_token,
            expires_at,
            device_id,
            identity_key_seed,
        };
        self.sessions.write().unwrap().insert(token.clone(), session);
        token
    }

    pub fn validate(&self, token: &str) -> Option<Session> {
        let session = self.sessions.read().unwrap().get(token).cloned()?;

        if let Some(exp) = session.expires_at {
            if Utc::now().timestamp() >= exp {
                self.sessions.write().unwrap().remove(token);
                return None;
            }
        }

        Some(session)
    }

    pub fn has_sessions(&self) -> bool {
        !self.sessions.read().unwrap().is_empty()
    }

    pub fn remove(&self, token: &str) {
        self.sessions.write().unwrap().remove(token);
    }

    pub fn update_session(
        &self,
        token: &str,
        backend_token: Option<String>,
        expires_at: Option<i64>,
    ) -> bool {
        self.sync_hub_token(backend_token.as_ref());
        let mut sessions = self.sessions.write().unwrap();
        match sessions.get_mut(token) {
            Some(session) => {
                session.backend_token = backend_token;
                session.expires_at = expires_at;
                true
            }
            None => false,
        }
    }

    pub fn update_credentials(
        &self,
        session_token: &str,
        backend_token: String,
        device_id: Option<String>,
        identity_key_seed: Option<String>,
    ) {
        self.sync_hub_token(Some(&backend_token));
        if let Some(session) = self.sessions.write().unwrap().get_mut(session_token) {
            session.backend_token = Some(backend_token);
            if let Some(id) = device_id {
                session.device_id = Some(id);
            }
            if let Some(seed) = identity_key_seed {
                session.identity_key_seed = Some(seed);
            }
        }
    }

    /// Clears sensitive credential fields (device_id, identity_key_seed)
    /// from a session without removing it. Called on WS disconnect so
    /// credentials don't linger in memory.
    pub fn clear_credentials(&self, session_token: &str) {
        if let Some(session) = self.sessions.write().unwrap().get_mut(session_token) {
            session.device_id = None;
            session.identity_key_seed = None;
        }
    }

    pub fn remove_expired(&self) {
        let now = Utc::now().timestamp();
        self.sessions
            .write()
            .unwrap()
            .retain(|_, session| match session.expires_at {
                Some(exp) => now < exp,
                None => true,
            });
    }

    pub fn backend_token(&self, session_token: &str) -> Option<String> {
        self.sessions
            .read()
            .unwrap()
            .get(session_token)
            .and_then(|s| s.backend_token.clone())
    }
}

fn generate_token() -> String {
    let mut bytes = [0u8; 32];
    rand::rng().fill(&mut bytes);
    hex::encode(bytes)
}
