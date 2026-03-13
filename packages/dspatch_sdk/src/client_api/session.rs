// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! In-memory session token store for the client API.

use std::collections::HashMap;
use std::sync::RwLock;

use rand::Rng;

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
}

/// Thread-safe in-memory store mapping session tokens to sessions.
pub struct SessionStore {
    sessions: RwLock<HashMap<String, Session>>,
}

impl SessionStore {
    pub fn new() -> Self {
        Self {
            sessions: RwLock::new(HashMap::new()),
        }
    }

    pub fn create_session(&self, auth_mode: AuthMode, username: Option<String>) -> String {
        let token = generate_token();
        let session = Session { auth_mode, username };
        self.sessions.write().unwrap().insert(token.clone(), session);
        token
    }

    pub fn validate(&self, token: &str) -> Option<Session> {
        self.sessions.read().unwrap().get(token).cloned()
    }

    pub fn has_sessions(&self) -> bool {
        !self.sessions.read().unwrap().is_empty()
    }

    pub fn remove(&self, token: &str) {
        self.sessions.write().unwrap().remove(token);
    }
}

fn generate_token() -> String {
    let mut bytes = [0u8; 32];
    rand::thread_rng().fill(&mut bytes);
    hex::encode(bytes)
}
