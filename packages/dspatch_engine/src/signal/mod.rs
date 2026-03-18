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

/// Creates Signal Protocol tables if they don't exist.
pub fn ensure_schema(conn: &rusqlite::Connection) -> rusqlite::Result<()> {
    conn.execute_batch(include_str!("../../shared/schema/signal_identities.sql"))?;
    conn.execute_batch(include_str!("../../shared/schema/signal_prekeys.sql"))?;
    conn.execute_batch(include_str!("../../shared/schema/signal_signed_prekeys.sql"))?;
    conn.execute_batch(include_str!("../../shared/schema/signal_sessions.sql"))?;
    conn.execute_batch(include_str!("../../shared/schema/signal_sender_keys.sql"))?;
    conn.execute_batch(include_str!("../../shared/schema/signal_kyber_prekeys.sql"))?;
    Ok(())
}
