// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Signal Protocol E2E encryption backed by `libsignal-protocol`.

pub mod identity_store;
pub mod prekey_store;
pub mod signed_prekey_store;
pub mod session_store;
pub mod sender_key_store;
pub mod kyber_prekey_store;
pub mod protocol;

pub use identity_store::SqliteIdentityStore;
pub use prekey_store::SqlitePreKeyStore;
pub use signed_prekey_store::SqliteSignedPreKeyStore;
pub use session_store::SqliteSessionStore;
pub use sender_key_store::SqliteSenderKeyStore;
pub use kyber_prekey_store::SqliteKyberPreKeyStore;
pub use protocol::SignalService;
