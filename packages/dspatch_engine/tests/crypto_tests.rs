// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Integration tests for the crypto layer.

use std::sync::Arc;

use dspatch_engine::crypto::AesGcmCrypto;
use dspatch_engine::db::key_manager::testing::InMemorySecretStore;
use dspatch_engine::db::key_manager::SecretStore;

fn make_crypto() -> AesGcmCrypto {
    AesGcmCrypto::new(Arc::new(InMemorySecretStore::new()))
}

fn make_crypto_with_store(store: Arc<InMemorySecretStore>) -> AesGcmCrypto {
    AesGcmCrypto::new(store)
}

// ── Round-trip tests ──────────────────────────────────────────────────

#[tokio::test]
async fn encrypt_decrypt_round_trip_bytes() {
    let crypto = make_crypto();
    let plaintext = b"hello, world!";
    let blob = crypto.encrypt(plaintext, "test_key").await.unwrap();
    let decrypted = crypto.decrypt(&blob, "test_key").await.unwrap();
    assert_eq!(decrypted, plaintext);
}

#[tokio::test]
async fn encrypt_decrypt_round_trip_string() {
    let crypto = make_crypto();
    let plaintext = "secret API key 🔑";
    let blob = crypto.encrypt_string(plaintext, "api_key").await.unwrap();
    let decrypted = crypto.decrypt_string(&blob, "api_key").await.unwrap();
    assert_eq!(decrypted, plaintext);
}

#[tokio::test]
async fn encrypt_decrypt_empty_plaintext() {
    let crypto = make_crypto();
    let blob = crypto.encrypt(b"", "key").await.unwrap();
    let decrypted = crypto.decrypt(&blob, "key").await.unwrap();
    assert!(decrypted.is_empty());
}

// ── Blob format verification ──────────────────────────────────────────

const NONCE_LEN: usize = 12;
const TAG_LEN: usize = 16;

#[tokio::test]
async fn blob_format_nonce_and_tag() {
    let crypto = make_crypto();
    let plaintext = b"test data";
    let blob = crypto.encrypt(plaintext, "key1").await.unwrap();

    // blob = nonce (12) + ciphertext (len(plaintext)) + tag (16)
    assert_eq!(blob.len(), NONCE_LEN + plaintext.len() + TAG_LEN);
}

// ── Key derivation tests ──────────────────────────────────────────────

#[tokio::test]
async fn different_key_ids_produce_different_ciphertexts() {
    let crypto = make_crypto();
    let plaintext = b"same plaintext";
    let blob1 = crypto.encrypt(plaintext, "key_a").await.unwrap();
    let blob2 = crypto.encrypt(plaintext, "key_b").await.unwrap();
    assert_ne!(blob1, blob2);
}

#[tokio::test]
async fn same_master_key_same_key_id_produces_same_derived_key() {
    // Two AesGcmCrypto instances sharing the same store (hence same master key)
    // should derive the same key for the same key_id.
    let store = Arc::new(InMemorySecretStore::new());
    let crypto1 = make_crypto_with_store(Arc::clone(&store));
    let crypto2 = make_crypto_with_store(Arc::clone(&store));

    // Force master key creation via first encrypt.
    let blob = crypto1.encrypt(b"data", "shared_key").await.unwrap();
    // Second instance should derive the same key and decrypt successfully.
    let decrypted = crypto2.decrypt(&blob, "shared_key").await.unwrap();
    assert_eq!(decrypted, b"data");
}

// ── Error cases ───────────────────────────────────────────────────────

#[tokio::test]
async fn decrypt_with_wrong_key_id_fails() {
    let crypto = make_crypto();
    let blob = crypto.encrypt(b"secret", "correct_key").await.unwrap();
    let result = crypto.decrypt(&blob, "wrong_key").await;
    assert!(result.is_err());
}

#[tokio::test]
async fn decrypt_corrupted_blob_fails() {
    let crypto = make_crypto();
    let mut blob = crypto.encrypt(b"secret", "key").await.unwrap();
    // Corrupt one byte in the ciphertext region.
    let mid = NONCE_LEN + 1;
    blob[mid] ^= 0xFF;
    let result = crypto.decrypt(&blob, "key").await;
    assert!(result.is_err());
}

#[tokio::test]
async fn decrypt_too_short_blob_fails() {
    let crypto = make_crypto();
    let result = crypto.decrypt(&[0u8; 10], "key").await;
    assert!(result.is_err());
}

// ── Master key persistence ────────────────────────────────────────────

#[tokio::test]
async fn master_key_is_persisted_to_store() {
    let store = Arc::new(InMemorySecretStore::new());
    let crypto = make_crypto_with_store(Arc::clone(&store));

    // Trigger master key generation.
    let _ = crypto.encrypt(b"x", "k").await.unwrap();

    // The store should now contain the master key.
    let stored = store.read("dspatch_master_key").unwrap();
    assert!(stored.is_some());

    // The stored value should be valid base64 decoding to 32 bytes.
    let decoded = base64::Engine::decode(
        &base64::engine::general_purpose::STANDARD,
        stored.unwrap(),
    )
    .unwrap();
    assert_eq!(decoded.len(), 32);
}

// ── InMemorySecretStore tests ─────────────────────────────────────────

#[test]
fn in_memory_store_read_write_delete() {
    let store = InMemorySecretStore::new();

    // Initially empty.
    assert_eq!(store.read("key1").unwrap(), None);

    // Write and read back.
    store.write("key1", "value1").unwrap();
    assert_eq!(store.read("key1").unwrap(), Some("value1".to_string()));

    // Overwrite.
    store.write("key1", "value2").unwrap();
    assert_eq!(store.read("key1").unwrap(), Some("value2".to_string()));

    // Delete.
    store.delete("key1").unwrap();
    assert_eq!(store.read("key1").unwrap(), None);

    // Delete non-existent is a no-op.
    store.delete("nonexistent").unwrap();
}
