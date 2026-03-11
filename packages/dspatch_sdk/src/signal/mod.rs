// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Signal-inspired E2E encryption for P2P device sync.
//!
//! Uses X25519 for key exchange, Ed25519 for identity signing, and AES-256-GCM
//! for symmetric encryption. Implements a simplified Double Ratchet protocol
//! where each message exchange ratchets the shared secret forward using
//! HKDF-SHA256.
//!
//! All key material is persisted to SQLite via the store types.

pub mod identity_store;
pub mod prekey_store;
pub mod signed_prekey_store;
pub mod session_store;
pub mod sender_key_store;
pub mod protocol;

pub use identity_store::SqliteIdentityStore;
pub use prekey_store::SqlitePreKeyStore;
pub use signed_prekey_store::SqliteSignedPreKeyStore;
pub use session_store::SqliteSessionStore;
pub use sender_key_store::SqliteSenderKeyStore;
pub use protocol::SignalManager;
