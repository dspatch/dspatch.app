// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! In-memory session token store for the client API.

use std::collections::HashMap;
use std::sync::RwLock;

use chrono::Utc;
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
    pub backend_token: Option<String>,
    pub expires_at: Option<i64>,
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

    pub fn create_session(
        &self,
        auth_mode: AuthMode,
        username: Option<String>,
        backend_token: Option<String>,
        expires_at: Option<i64>,
    ) -> String {
        let token = generate_token();
        let session = Session {
            auth_mode,
            username,
            backend_token,
            expires_at,
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
