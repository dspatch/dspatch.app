// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the Signal Protocol stores and SignalManager.

use std::sync::Arc;

use dspatch_sdk::db::Database;
use dspatch_sdk::signal::identity_store::TrustLevel;
use dspatch_sdk::signal::protocol::{PreKeyBundle, SignalManager};
use ed25519_dalek::SigningKey;
use rand::rngs::OsRng;

/// Helper: create an in-memory database and a SignalManager.
fn make_manager(reg_id: u32) -> SignalManager {
    let db = Arc::new(Database::open_in_memory().unwrap());
    let signing_key = SigningKey::generate(&mut OsRng);
    SignalManager::new(db, reg_id, signing_key)
}

// -----------------------------------------------------------------------
// Key generation tests
// -----------------------------------------------------------------------

#[test]
fn test_generate_identity_keypair() {
    let manager = make_manager(1);
    let pub_key = manager.identity_store.get_identity_public_key_bytes();
    assert_eq!(pub_key.len(), 32, "Ed25519 public key should be 32 bytes");
}

#[test]
fn test_generate_prekeys() {
    let mut manager = make_manager(1);
    let prekeys = manager.generate_prekeys(1, 10).unwrap();
    assert_eq!(prekeys.len(), 10);
    for (i, pk) in prekeys.iter().enumerate() {
        assert_eq!(pk.id, (i as u32) + 1);
        assert_eq!(pk.record.len(), 64, "prekey record = private(32) + public(32)");
    }
}

#[test]
fn test_generate_signed_prekey() {
    let mut manager = make_manager(1);
    let spk = manager.generate_signed_prekey(1).unwrap();
    assert_eq!(spk.id, 1);
    assert_eq!(
        spk.record.len(),
        128,
        "signed prekey record = private(32) + public(32) + signature(64)"
    );
}

// -----------------------------------------------------------------------
// Store CRUD tests
// -----------------------------------------------------------------------

#[test]
fn test_identity_store_save_and_load() {
    let manager = make_manager(1);
    let identity_key = vec![42u8; 32];

    manager
        .identity_store
        .save_identity("alice", 1, &identity_key, TrustLevel::TrustedUnverified)
        .unwrap();

    let record = manager
        .identity_store
        .get_identity("alice", 1)
        .unwrap()
        .expect("identity should exist");

    assert_eq!(record.address, "alice");
    assert_eq!(record.device_id, 1);
    assert_eq!(record.identity_key, identity_key);
    assert_eq!(record.trust_level, TrustLevel::TrustedUnverified);
}

#[test]
fn test_identity_store_trust_on_first_use() {
    let manager = make_manager(1);
    // No identity stored yet — should be trusted (TOFU).
    assert!(manager
        .identity_store
        .is_trusted_identity("bob", 1, &[0u8; 32])
        .unwrap());
}

#[test]
fn test_identity_store_untrusted_on_key_change() {
    let manager = make_manager(1);
    let original_key = vec![1u8; 32];
    let different_key = vec![2u8; 32];

    manager
        .identity_store
        .save_identity("bob", 1, &original_key, TrustLevel::TrustedVerified)
        .unwrap();

    assert!(!manager
        .identity_store
        .is_trusted_identity("bob", 1, &different_key)
        .unwrap());
}

#[test]
fn test_prekey_store_crud() {
    let mut manager = make_manager(1);
    let prekeys = manager.generate_prekeys(1, 3).unwrap();

    assert!(manager.prekey_store.contains_prekey(1).unwrap());
    assert!(manager.prekey_store.contains_prekey(2).unwrap());
    assert!(manager.prekey_store.contains_prekey(3).unwrap());
    assert!(!manager.prekey_store.contains_prekey(4).unwrap());

    let loaded = manager.prekey_store.get_prekey(2).unwrap().unwrap();
    assert_eq!(loaded.record, prekeys[1].record);

    manager.prekey_store.remove_prekey(2).unwrap();
    assert!(!manager.prekey_store.contains_prekey(2).unwrap());
    assert!(manager.prekey_store.get_prekey(2).unwrap().is_none());
}

#[test]
fn test_signed_prekey_store_crud() {
    let mut manager = make_manager(1);
    let spk = manager.generate_signed_prekey(42).unwrap();

    let loaded = manager
        .signed_prekey_store
        .get_signed_prekey(42)
        .unwrap()
        .unwrap();
    assert_eq!(loaded.record, spk.record);
    assert_eq!(loaded.created_at, spk.created_at);

    manager.signed_prekey_store.remove_signed_prekey(42).unwrap();
    assert!(manager
        .signed_prekey_store
        .get_signed_prekey(42)
        .unwrap()
        .is_none());
}

#[test]
fn test_session_store_crud() {
    let manager = make_manager(1);
    let record = vec![99u8; 200];

    // Store.
    manager
        .session_store
        .store_session("alice", 1, &record)
        .unwrap();

    // Load.
    let loaded = manager
        .session_store
        .load_session("alice", 1)
        .unwrap()
        .unwrap();
    assert_eq!(loaded.record, record);

    // Contains.
    assert!(manager.session_store.contains_session("alice", 1).unwrap());
    assert!(!manager.session_store.contains_session("alice", 2).unwrap());

    // Sub-device sessions.
    manager
        .session_store
        .store_session("alice", 2, &record)
        .unwrap();
    manager
        .session_store
        .store_session("alice", 3, &record)
        .unwrap();
    let subs = manager
        .session_store
        .get_sub_device_sessions("alice")
        .unwrap();
    assert_eq!(subs, vec![2, 3]);

    // Delete.
    manager.session_store.delete_session("alice", 1).unwrap();
    assert!(!manager.session_store.contains_session("alice", 1).unwrap());
}

#[test]
fn test_sender_key_store_crud() {
    let manager = make_manager(1);
    let record = vec![77u8; 64];

    manager
        .sender_key_store
        .store_sender_key("alice", 1, "group-1", &record)
        .unwrap();

    let loaded = manager
        .sender_key_store
        .load_sender_key("alice", 1, "group-1")
        .unwrap()
        .unwrap();
    assert_eq!(loaded.record, record);

    // Non-existent key.
    assert!(manager
        .sender_key_store
        .load_sender_key("alice", 1, "group-2")
        .unwrap()
        .is_none());
}

// -----------------------------------------------------------------------
// Encrypt / decrypt round-trip
// -----------------------------------------------------------------------

#[test]
fn test_encrypt_decrypt_round_trip() {
    // Set up Alice and Bob with pre-shared symmetric sessions.
    // Alice's send chain = Bob's recv chain and vice versa.
    // (Full X3DH handshake is tested in test_session_establishment_via_prekey_bundle.)
    let db_alice = Arc::new(Database::open_in_memory().unwrap());
    let db_bob = Arc::new(Database::open_in_memory().unwrap());

    let alice = SignalManager::new(
        Arc::clone(&db_alice),
        1,
        SigningKey::generate(&mut OsRng),
    );
    let bob = SignalManager::new(
        Arc::clone(&db_bob),
        2,
        SigningKey::generate(&mut OsRng),
    );

    let shared_root = [0xAA_u8; 32];
    let shared_chain_send = [0xBB_u8; 32];
    let shared_chain_recv = [0xCC_u8; 32];
    let ratchet_priv = [0xDD_u8; 32];
    let ratchet_pub = {
        let secret = x25519_dalek::StaticSecret::from(ratchet_priv);
        let public = x25519_dalek::PublicKey::from(&secret);
        *public.as_bytes()
    };

    // Alice's send chain = Bob's recv chain, and vice versa.
    let alice_session_record = build_test_session(
        &shared_root,
        &shared_chain_send,
        &shared_chain_recv,
        &ratchet_pub,
        &ratchet_priv,
        &ratchet_pub,
        0,
        0,
    );
    let bob_session_record = build_test_session(
        &shared_root,
        &shared_chain_recv, // Bob's send = Alice's recv
        &shared_chain_send, // Bob's recv = Alice's send
        &ratchet_pub,
        &ratchet_priv,
        &ratchet_pub,
        0,
        0,
    );

    alice
        .session_store
        .store_session("bob", 1, &alice_session_record)
        .unwrap();
    bob.session_store
        .store_session("alice", 1, &bob_session_record)
        .unwrap();

    // Alice encrypts.
    let plaintext = b"Symmetric session test message";
    let ciphertext = alice.encrypt("bob", 1, plaintext).unwrap();

    // Bob decrypts.
    let decrypted = bob.decrypt("alice", 1, &ciphertext).unwrap();
    assert_eq!(decrypted, plaintext);
}

#[test]
fn test_multiple_messages_in_sequence() {
    let db_alice = Arc::new(Database::open_in_memory().unwrap());
    let db_bob = Arc::new(Database::open_in_memory().unwrap());

    let mut alice = SignalManager::new(
        Arc::clone(&db_alice),
        1,
        SigningKey::generate(&mut OsRng),
    );
    let mut bob = SignalManager::new(
        Arc::clone(&db_bob),
        2,
        SigningKey::generate(&mut OsRng),
    );

    alice.initialize().unwrap();
    bob.initialize().unwrap();

    // Set up symmetric session.
    let shared_root = [0x11_u8; 32];
    let chain_a_to_b = [0x22_u8; 32];
    let chain_b_to_a = [0x33_u8; 32];
    let ratchet_priv = [0x44_u8; 32];
    let ratchet_pub = {
        let secret = x25519_dalek::StaticSecret::from(ratchet_priv);
        *x25519_dalek::PublicKey::from(&secret).as_bytes()
    };

    alice
        .session_store
        .store_session(
            "bob",
            1,
            &build_test_session(
                &shared_root,
                &chain_a_to_b,
                &chain_b_to_a,
                &ratchet_pub,
                &ratchet_priv,
                &ratchet_pub,
                0,
                0,
            ),
        )
        .unwrap();
    bob.session_store
        .store_session(
            "alice",
            1,
            &build_test_session(
                &shared_root,
                &chain_b_to_a,
                &chain_a_to_b,
                &ratchet_pub,
                &ratchet_priv,
                &ratchet_pub,
                0,
                0,
            ),
        )
        .unwrap();

    // Send 5 messages from Alice to Bob.
    for i in 0..5 {
        let msg = format!("Message number {i}");
        let ct = alice.encrypt("bob", 1, msg.as_bytes()).unwrap();
        let pt = bob.decrypt("alice", 1, &ct).unwrap();
        assert_eq!(pt, msg.as_bytes());
    }
}

#[test]
fn test_session_establishment_via_prekey_bundle() {
    let db_alice = Arc::new(Database::open_in_memory().unwrap());
    let db_bob = Arc::new(Database::open_in_memory().unwrap());

    let mut alice = SignalManager::new(
        Arc::clone(&db_alice),
        1,
        SigningKey::generate(&mut OsRng),
    );
    let mut bob = SignalManager::new(
        Arc::clone(&db_bob),
        2,
        SigningKey::generate(&mut OsRng),
    );

    alice.initialize().unwrap();
    bob.initialize().unwrap();

    // Build Bob's prekey bundle.
    let bob_spk = bob
        .signed_prekey_store
        .get_signed_prekey(1)
        .unwrap()
        .unwrap();
    let bob_pk = bob.prekey_store.get_prekey(1).unwrap().unwrap();

    let bundle = PreKeyBundle {
        registration_id: 2,
        device_id: 1,
        identity_key: bob.identity_store.get_identity_public_key_bytes(),
        signed_prekey_id: 1,
        signed_prekey_public: bob_spk.record[32..64].to_vec(),
        signed_prekey_signature: bob_spk.record[64..128].to_vec(),
        prekey_id: Some(1),
        prekey_public: Some(bob_pk.record[32..64].to_vec()),
    };

    // Alice processes the bundle — this should create a session.
    alice.process_prekey_bundle("bob", 1, &bundle).unwrap();

    // Verify the session was stored.
    assert!(alice.session_store.contains_session("bob", 1).unwrap());

    // Verify Bob's identity was saved.
    let identity = alice
        .identity_store
        .get_identity("bob", 1)
        .unwrap()
        .unwrap();
    assert_eq!(
        identity.identity_key,
        bob.identity_store.get_identity_public_key_bytes()
    );
    assert_eq!(identity.trust_level, TrustLevel::TrustedUnverified);

    // Alice should be able to encrypt (session exists).
    let ct = alice.encrypt("bob", 1, b"test").unwrap();
    assert!(ct.len() > 1 + 32 + 12 + 16); // version + pub + nonce + tag + at least 4 bytes ct
}

#[test]
fn test_decrypt_without_session_fails() {
    let manager = make_manager(1);
    let fake_message = vec![1u8; 100]; // version byte + garbage
    let result = manager.decrypt("nobody", 1, &fake_message);
    assert!(result.is_err());
}

#[test]
fn test_decrypt_short_message_fails() {
    let manager = make_manager(1);
    let short = vec![1u8; 10];
    let result = manager.decrypt("nobody", 1, &short);
    assert!(result.is_err());
}

// -----------------------------------------------------------------------
// Helper
// -----------------------------------------------------------------------

fn build_test_session(
    root_key: &[u8; 32],
    chain_key_send: &[u8; 32],
    chain_key_recv: &[u8; 32],
    remote_ratchet_pub: &[u8; 32],
    local_ratchet_priv: &[u8; 32],
    local_ratchet_pub: &[u8; 32],
    send_counter: u32,
    recv_counter: u32,
) -> Vec<u8> {
    let mut record = Vec::with_capacity(200);
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
