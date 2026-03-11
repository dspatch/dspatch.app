// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SignalManager — simplified Double Ratchet E2E encryption for P2P sync.
//!
//! Protocol overview:
//!
//! 1. Each device has an Ed25519 identity keypair and a set of X25519 prekeys.
//! 2. To establish a session, Alice performs X3DH:
//!    - Ephemeral X25519 key exchange with Bob's signed prekey + one-time prekey.
//!    - HKDF derives a shared root key from the DH outputs.
//! 3. Messages are encrypted with AES-256-GCM using a chain key derived via
//!    HKDF from the root key. Each message ratchets the chain key forward.
//!
//! Wire format for encrypted messages:
//!   `version (1) || ephemeral_pub (32) || nonce (12) || ciphertext || tag (16)`
//!
//! Session record format (stored in signal_sessions):
//!   `root_key (32) || chain_key_send (32) || chain_key_recv (32) ||
//!    remote_ratchet_pub (32) || local_ratchet_priv (32) || local_ratchet_pub (32) ||
//!    send_counter (4, LE) || recv_counter (4, LE)`

use std::sync::Arc;

use aes_gcm::aead::{Aead, KeyInit, OsRng};
use aes_gcm::{Aes256Gcm, AeadCore, Nonce};
use ed25519_dalek::{Signer, SigningKey};
use hkdf::Hkdf;
use sha2::Sha256;
use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret as X25519StaticSecret};

use crate::db::Database;
use crate::util::error::AppError;
use crate::util::result::Result;

use super::identity_store::{SqliteIdentityStore, TrustLevel};
use super::prekey_store::SqlitePreKeyStore;
use super::sender_key_store::SqliteSenderKeyStore;
use super::session_store::SqliteSessionStore;
use super::signed_prekey_store::SqliteSignedPreKeyStore;

/// Current wire format version.
const PROTOCOL_VERSION: u8 = 1;

/// Size of the session record blob.
const SESSION_RECORD_SIZE: usize = 32 + 32 + 32 + 32 + 32 + 32 + 4 + 4; // 200 bytes

/// HKDF info strings for domain separation.
const HKDF_INFO_ROOT: &[u8] = b"dspatch-signal-root-key";
const HKDF_INFO_CHAIN: &[u8] = b"dspatch-signal-chain-key";
const HKDF_INFO_MESSAGE: &[u8] = b"dspatch-signal-message-key";

/// Manages E2E encryption state: key generation, session establishment,
/// encrypt/decrypt.
pub struct SignalManager {
    #[allow(dead_code)]
    db: Arc<Database>,
    pub identity_store: SqliteIdentityStore,
    pub prekey_store: SqlitePreKeyStore,
    pub signed_prekey_store: SqliteSignedPreKeyStore,
    pub session_store: SqliteSessionStore,
    pub sender_key_store: SqliteSenderKeyStore,
}

/// Prekey bundle published by a device so that others can establish sessions.
#[derive(Debug, Clone)]
pub struct PreKeyBundle {
    pub registration_id: u32,
    pub device_id: u32,
    pub identity_key: Vec<u8>,
    pub signed_prekey_id: u32,
    pub signed_prekey_public: Vec<u8>,
    pub signed_prekey_signature: Vec<u8>,
    pub prekey_id: Option<u32>,
    pub prekey_public: Option<Vec<u8>>,
}

impl SignalManager {
    /// Creates a new SignalManager backed by the given database.
    pub fn new(
        db: Arc<Database>,
        local_registration_id: u32,
        signing_key: SigningKey,
    ) -> Self {
        let conn = db.conn_arc().clone();
        Self {
            identity_store: SqliteIdentityStore::new(
                Arc::clone(&conn),
                local_registration_id,
                signing_key,
            ),
            prekey_store: SqlitePreKeyStore::new(Arc::clone(&conn)),
            signed_prekey_store: SqliteSignedPreKeyStore::new(Arc::clone(&conn)),
            session_store: SqliteSessionStore::new(Arc::clone(&conn)),
            sender_key_store: SqliteSenderKeyStore::new(Arc::clone(&conn)),
            db,
        }
    }

    /// Generates identity keys, a signed prekey, and a batch of one-time
    /// prekeys. Call once on first run.
    pub fn initialize(&mut self) -> Result<()> {
        // Generate signed prekey (id = 1).
        self.generate_signed_prekey(1)?;
        // Generate initial batch of one-time prekeys.
        self.generate_prekeys(1, 100)?;
        Ok(())
    }

    /// Generates a batch of one-time X25519 prekeys and stores them.
    ///
    /// Each prekey record is `private (32) || public (32)`.
    pub fn generate_prekeys(
        &mut self,
        start_id: u32,
        count: u32,
    ) -> Result<Vec<super::prekey_store::PreKeyRecord>> {
        let mut records = Vec::with_capacity(count as usize);
        for i in 0..count {
            let id = start_id + i;
            let secret = X25519StaticSecret::random_from_rng(&mut OsRng);
            let public = X25519PublicKey::from(&secret);

            let mut record = Vec::with_capacity(64);
            record.extend_from_slice(&secret.to_bytes());
            record.extend_from_slice(public.as_bytes());

            self.prekey_store.save_prekey(id, &record)?;
            records.push(super::prekey_store::PreKeyRecord { id, record });
        }
        Ok(records)
    }

    /// Generates a signed prekey: an X25519 keypair signed by the identity key.
    ///
    /// Record format: `private (32) || public (32) || signature (64)`.
    pub fn generate_signed_prekey(
        &mut self,
        id: u32,
    ) -> Result<super::signed_prekey_store::SignedPreKeyRecord> {
        let secret = X25519StaticSecret::random_from_rng(&mut OsRng);
        let public = X25519PublicKey::from(&secret);

        // Sign the public key with the Ed25519 identity key.
        let signature = self
            .identity_store
            .get_signing_key()
            .sign(public.as_bytes());

        let mut record = Vec::with_capacity(128);
        record.extend_from_slice(&secret.to_bytes());
        record.extend_from_slice(public.as_bytes());
        record.extend_from_slice(&signature.to_bytes());

        let created_at = chrono::Utc::now().to_rfc3339();
        self.signed_prekey_store
            .save_signed_prekey(id, &record, &created_at)?;

        Ok(super::signed_prekey_store::SignedPreKeyRecord {
            id,
            record,
            created_at,
        })
    }

    /// Establishes a session with a remote device using their prekey bundle
    /// (X3DH-inspired key agreement).
    ///
    /// After this call, `encrypt()` can be used for the given address.
    pub fn process_prekey_bundle(
        &mut self,
        address: &str,
        device_id: u32,
        bundle: &PreKeyBundle,
    ) -> Result<()> {
        // Save the remote identity key (trust on first use).
        self.identity_store.save_identity(
            address,
            device_id,
            &bundle.identity_key,
            TrustLevel::TrustedUnverified,
        )?;

        // Generate an ephemeral X25519 keypair for the key agreement.
        let ephemeral_secret = X25519StaticSecret::random_from_rng(&mut OsRng);
        let _ephemeral_public = X25519PublicKey::from(&ephemeral_secret);

        // Parse the signed prekey public from the bundle.
        let signed_prekey_pub = parse_x25519_public(&bundle.signed_prekey_public)?;

        // DH1: ephemeral_secret * signed_prekey_pub
        let dh1 = ephemeral_secret.diffie_hellman(&signed_prekey_pub);

        // If a one-time prekey is available, do DH2.
        let mut key_material = dh1.as_bytes().to_vec();
        if let Some(ref prekey_pub_bytes) = bundle.prekey_public {
            let prekey_pub = parse_x25519_public(prekey_pub_bytes)?;
            let dh2 = ephemeral_secret.diffie_hellman(&prekey_pub);
            key_material.extend_from_slice(dh2.as_bytes());
        }

        // Derive root key and initial chain keys via HKDF.
        let hk = Hkdf::<Sha256>::new(None, &key_material);
        let mut root_key = [0u8; 32];
        let mut chain_key_send = [0u8; 32];
        let mut chain_key_recv = [0u8; 32];
        hk.expand(HKDF_INFO_ROOT, &mut root_key)
            .map_err(|e| AppError::Crypto(format!("HKDF root key derivation failed: {e}")))?;
        hk.expand(HKDF_INFO_CHAIN, &mut chain_key_send)
            .map_err(|e| AppError::Crypto(format!("HKDF chain key derivation failed: {e}")))?;
        // For the initial recv chain, derive from the root key with a different salt.
        let hk2 = Hkdf::<Sha256>::new(Some(&root_key), &key_material);
        hk2.expand(HKDF_INFO_CHAIN, &mut chain_key_recv)
            .map_err(|e| AppError::Crypto(format!("HKDF recv chain key failed: {e}")))?;

        // Create a local ratchet keypair for future ratchet steps.
        let local_ratchet_secret = X25519StaticSecret::random_from_rng(&mut OsRng);
        let local_ratchet_public = X25519PublicKey::from(&local_ratchet_secret);

        // Build session record.
        let session_record = build_session_record(
            &root_key,
            &chain_key_send,
            &chain_key_recv,
            signed_prekey_pub.as_bytes(),
            &local_ratchet_secret.to_bytes(),
            local_ratchet_public.as_bytes(),
            0, // send_counter
            0, // recv_counter
        );

        self.session_store
            .store_session(address, device_id, &session_record)?;

        // Store the ephemeral public key in the session so the remote side
        // can complete the key agreement. We embed it in the first message.
        Ok(())
    }

    /// Encrypts plaintext for a specific device address.
    ///
    /// Wire format: `version (1) || ephemeral_pub (32) || nonce (12) ||
    ///               ciphertext || tag (16)`
    pub fn encrypt(
        &self,
        address: &str,
        device_id: u32,
        plaintext: &[u8],
    ) -> Result<Vec<u8>> {
        let session_record = self
            .session_store
            .load_session(address, device_id)?
            .ok_or_else(|| {
                AppError::Crypto(format!(
                    "No session with {address}:{device_id} — call process_prekey_bundle first"
                ))
            })?;

        let (
            root_key,
            chain_key_send,
            chain_key_recv,
            remote_ratchet_pub,
            local_ratchet_priv,
            local_ratchet_pub,
            send_counter,
            recv_counter,
        ) = parse_session_record(&session_record.record)?;

        // Derive message key from chain_key_send using HKDF.
        let message_key = derive_message_key(&chain_key_send, send_counter)?;

        // Encrypt with AES-256-GCM.
        let cipher = Aes256Gcm::new_from_slice(&message_key)
            .map_err(|e| AppError::Crypto(format!("Failed to create cipher: {e}")))?;
        let nonce = Aes256Gcm::generate_nonce(&mut OsRng);
        let ciphertext = cipher
            .encrypt(&nonce, plaintext)
            .map_err(|e| AppError::Crypto(format!("Encryption failed: {e}")))?;

        // Ratchet the send chain key forward.
        let new_chain_key_send = ratchet_chain_key(&chain_key_send)?;

        // Update session record with incremented counter and new chain key.
        let updated_record = build_session_record(
            &root_key,
            &new_chain_key_send,
            &chain_key_recv,
            &remote_ratchet_pub,
            &local_ratchet_priv,
            &local_ratchet_pub,
            send_counter + 1,
            recv_counter,
        );
        self.session_store
            .store_session(address, device_id, &updated_record)?;

        // Build wire message.
        let mut msg = Vec::with_capacity(1 + 32 + 12 + ciphertext.len());
        msg.push(PROTOCOL_VERSION);
        msg.extend_from_slice(&local_ratchet_pub);
        msg.extend_from_slice(&nonce);
        msg.extend_from_slice(&ciphertext);

        Ok(msg)
    }

    /// Decrypts ciphertext from a specific device address.
    pub fn decrypt(
        &self,
        address: &str,
        device_id: u32,
        message: &[u8],
    ) -> Result<Vec<u8>> {
        // Parse wire format.
        if message.len() < 1 + 32 + 12 + 16 {
            return Err(AppError::Crypto("Encrypted message too short".into()));
        }

        let version = message[0];
        if version != PROTOCOL_VERSION {
            return Err(AppError::Crypto(format!(
                "Unsupported protocol version: {version}"
            )));
        }

        let _sender_ratchet_pub = &message[1..33];
        let nonce_bytes = &message[33..45];
        let ciphertext = &message[45..];

        let session_record = self
            .session_store
            .load_session(address, device_id)?
            .ok_or_else(|| {
                AppError::Crypto(format!(
                    "No session with {address}:{device_id}"
                ))
            })?;

        let (
            root_key,
            chain_key_send,
            chain_key_recv,
            remote_ratchet_pub,
            local_ratchet_priv,
            local_ratchet_pub,
            send_counter,
            recv_counter,
        ) = parse_session_record(&session_record.record)?;

        // Derive message key from chain_key_recv.
        let message_key = derive_message_key(&chain_key_recv, recv_counter)?;

        // Decrypt with AES-256-GCM.
        let cipher = Aes256Gcm::new_from_slice(&message_key)
            .map_err(|e| AppError::Crypto(format!("Failed to create cipher: {e}")))?;
        let nonce = Nonce::from_slice(nonce_bytes);
        let plaintext = cipher
            .decrypt(nonce, ciphertext)
            .map_err(|e| AppError::Crypto(format!("Decryption failed: {e}")))?;

        // Ratchet the recv chain key forward.
        let new_chain_key_recv = ratchet_chain_key(&chain_key_recv)?;

        // Update session record.
        let updated_record = build_session_record(
            &root_key,
            &chain_key_send,
            &new_chain_key_recv,
            &remote_ratchet_pub,
            &local_ratchet_priv,
            &local_ratchet_pub,
            send_counter,
            recv_counter + 1,
        );
        self.session_store
            .store_session(address, device_id, &updated_record)?;

        Ok(plaintext)
    }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn parse_x25519_public(bytes: &[u8]) -> Result<X25519PublicKey> {
    let arr: [u8; 32] = bytes.try_into().map_err(|_| {
        AppError::Crypto(format!(
            "Invalid X25519 public key length: expected 32, got {}",
            bytes.len()
        ))
    })?;
    Ok(X25519PublicKey::from(arr))
}

/// Builds a fixed-size session record blob.
fn build_session_record(
    root_key: &[u8; 32],
    chain_key_send: &[u8; 32],
    chain_key_recv: &[u8; 32],
    remote_ratchet_pub: &[u8; 32],
    local_ratchet_priv: &[u8; 32],
    local_ratchet_pub: &[u8; 32],
    send_counter: u32,
    recv_counter: u32,
) -> Vec<u8> {
    let mut record = Vec::with_capacity(SESSION_RECORD_SIZE);
    record.extend_from_slice(root_key);
    record.extend_from_slice(chain_key_send);
    record.extend_from_slice(chain_key_recv);
    record.extend_from_slice(remote_ratchet_pub);
    record.extend_from_slice(local_ratchet_priv);
    record.extend_from_slice(local_ratchet_pub);
    record.extend_from_slice(&send_counter.to_le_bytes());
    record.extend_from_slice(&recv_counter.to_le_bytes());
    record
}

/// Parses a session record blob into its components.
#[allow(clippy::type_complexity)]
fn parse_session_record(
    record: &[u8],
) -> Result<(
    [u8; 32],  // root_key
    [u8; 32],  // chain_key_send
    [u8; 32],  // chain_key_recv
    [u8; 32],  // remote_ratchet_pub
    [u8; 32],  // local_ratchet_priv
    [u8; 32],  // local_ratchet_pub
    u32,       // send_counter
    u32,       // recv_counter
)> {
    if record.len() != SESSION_RECORD_SIZE {
        return Err(AppError::Crypto(format!(
            "Invalid session record size: expected {SESSION_RECORD_SIZE}, got {}",
            record.len()
        )));
    }

    let root_key: [u8; 32] = record[0..32].try_into().unwrap();
    let chain_key_send: [u8; 32] = record[32..64].try_into().unwrap();
    let chain_key_recv: [u8; 32] = record[64..96].try_into().unwrap();
    let remote_ratchet_pub: [u8; 32] = record[96..128].try_into().unwrap();
    let local_ratchet_priv: [u8; 32] = record[128..160].try_into().unwrap();
    let local_ratchet_pub: [u8; 32] = record[160..192].try_into().unwrap();
    let send_counter = u32::from_le_bytes(record[192..196].try_into().unwrap());
    let recv_counter = u32::from_le_bytes(record[196..200].try_into().unwrap());

    Ok((
        root_key,
        chain_key_send,
        chain_key_recv,
        remote_ratchet_pub,
        local_ratchet_priv,
        local_ratchet_pub,
        send_counter,
        recv_counter,
    ))
}

/// Derives a per-message AES-256-GCM key from a chain key and counter.
fn derive_message_key(chain_key: &[u8; 32], counter: u32) -> Result<[u8; 32]> {
    let hk = Hkdf::<Sha256>::new(Some(&counter.to_le_bytes()), chain_key);
    let mut message_key = [0u8; 32];
    hk.expand(HKDF_INFO_MESSAGE, &mut message_key)
        .map_err(|e| AppError::Crypto(format!("HKDF message key derivation failed: {e}")))?;
    Ok(message_key)
}

/// Ratchets a chain key forward: `new_chain_key = HKDF(chain_key, "ratchet")`.
fn ratchet_chain_key(chain_key: &[u8; 32]) -> Result<[u8; 32]> {
    let hk = Hkdf::<Sha256>::new(None, chain_key);
    let mut new_key = [0u8; 32];
    hk.expand(b"dspatch-signal-ratchet", &mut new_key)
        .map_err(|e| AppError::Crypto(format!("Chain key ratchet failed: {e}")))?;
    Ok(new_key)
}
