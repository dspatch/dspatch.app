// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! AES-256-GCM encryption with HKDF-SHA256 key derivation.
//!
//! A single master key is stored in a [`SecretStore`] (platform keychain).
//! Per-purpose keys are derived using HKDF with `key_id` as the info parameter,
//! so different key IDs (e.g. `"api_key"`, `"session_token"`) produce independent
//! encryption keys from the same master key.
//!
//! Blob format: `nonce (12 B) || ciphertext || GCM tag (16 B)`.
//!
//! The master key is generated on first use and cached in memory for the
//! lifetime of this instance.
//!
//! Ported from `core/crypto/aes_gcm.dart`.

use std::sync::Arc;

use aes_gcm::aead::{Aead, KeyInit, OsRng};
use aes_gcm::{Aes256Gcm, AeadCore, Nonce};
use base64::Engine;
use hkdf::Hkdf;
use sha2::Sha256;
use tokio::sync::OnceCell;

use crate::db::key_manager::SecretStore;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Storage key for the master encryption key in the [`SecretStore`].
const MASTER_KEY_STORAGE_KEY: &str = "dspatch_master_key";

/// Nonce length for AES-GCM (96 bits).
const NONCE_LENGTH: usize = 12;

/// GCM authentication tag length (128 bits).
const TAG_LENGTH: usize = 16;

/// AES-256-GCM encryption with HKDF-SHA256 key derivation.
///
/// Cross-compatible with the Dart `AesGcmCrypto` implementation: same HKDF
/// parameters, same blob layout, same master key storage key.
pub struct AesGcmCrypto {
    store: Arc<dyn SecretStore>,
    master_key: OnceCell<Vec<u8>>,
}

impl AesGcmCrypto {
    /// Creates a new instance backed by the given secret store.
    pub fn new(store: Arc<dyn SecretStore>) -> Self {
        Self {
            store,
            master_key: OnceCell::new(),
        }
    }

    /// Encrypts `plaintext` bytes using a key derived from `key_id`.
    ///
    /// Returns: `nonce (12 B) || ciphertext || tag (16 B)`.
    pub async fn encrypt(&self, plaintext: &[u8], key_id: &str) -> Result<Vec<u8>> {
        let derived = self.derive_key(key_id).await?;
        let cipher = Aes256Gcm::new_from_slice(&derived)
            .map_err(|e| AppError::Crypto(format!("Failed to create cipher: {e}")))?;

        let nonce = Aes256Gcm::generate_nonce(&mut OsRng);

        // aes-gcm crate returns ciphertext || tag concatenated.
        let ciphertext_with_tag = cipher
            .encrypt(&nonce, plaintext)
            .map_err(|e| AppError::Crypto(format!("Encryption failed: {e}")))?;

        // Build blob: nonce || ciphertext || tag
        let mut blob = Vec::with_capacity(NONCE_LENGTH + ciphertext_with_tag.len());
        blob.extend_from_slice(&nonce);
        blob.extend_from_slice(&ciphertext_with_tag);
        Ok(blob)
    }

    /// Decrypts a blob previously produced by [`encrypt`](Self::encrypt).
    pub async fn decrypt(&self, blob: &[u8], key_id: &str) -> Result<Vec<u8>> {
        if blob.len() < NONCE_LENGTH + TAG_LENGTH {
            return Err(AppError::Crypto("Encrypted blob too short".into()));
        }

        let nonce = Nonce::from_slice(&blob[..NONCE_LENGTH]);
        let ciphertext_with_tag = &blob[NONCE_LENGTH..];

        let derived = self.derive_key(key_id).await?;
        let cipher = Aes256Gcm::new_from_slice(&derived)
            .map_err(|e| AppError::Crypto(format!("Failed to create cipher: {e}")))?;

        cipher
            .decrypt(nonce, ciphertext_with_tag)
            .map_err(|e| AppError::Crypto(format!("Decryption failed: {e}")))
    }

    /// Convenience: encrypts a UTF-8 string.
    pub async fn encrypt_string(&self, plaintext: &str, key_id: &str) -> Result<Vec<u8>> {
        self.encrypt(plaintext.as_bytes(), key_id).await
    }

    /// Convenience: decrypts to a UTF-8 string.
    pub async fn decrypt_string(&self, blob: &[u8], key_id: &str) -> Result<String> {
        let bytes = self.decrypt(blob, key_id).await?;
        String::from_utf8(bytes)
            .map_err(|e| AppError::Crypto(format!("Decrypted bytes are not valid UTF-8: {e}")))
    }

    /// Derives a purpose-specific 256-bit key from the master key using
    /// HKDF-SHA256. The `key_id` is used as the HKDF info parameter.
    async fn derive_key(&self, key_id: &str) -> Result<[u8; 32]> {
        let master = self.get_master_key().await?;
        let hk = Hkdf::<Sha256>::new(None, master);
        let mut okm = [0u8; 32];
        hk.expand(key_id.as_bytes(), &mut okm)
            .map_err(|e| AppError::Crypto(format!("HKDF expand failed: {e}")))?;
        Ok(okm)
    }

    /// Retrieves or generates the master key. Generated on first use,
    /// then cached in memory and persisted to the secret store.
    async fn get_master_key(&self) -> Result<&[u8]> {
        self.master_key
            .get_or_try_init(|| async {
                // Try to read existing key from store.
                let stored = self.store.read(MASTER_KEY_STORAGE_KEY).map_err(|e| {
                    AppError::Crypto(format!(
                        "Cannot access the platform keychain: {e}. \
                         Ensure your system keychain is unlocked and try again."
                    ))
                })?;

                if let Some(encoded) = stored {
                    let bytes = base64::engine::general_purpose::STANDARD
                        .decode(&encoded)
                        .map_err(|e| {
                            AppError::Crypto(format!("Stored master key is not valid base64: {e}"))
                        })?;
                    return Ok(bytes);
                }

                // Generate a new 32-byte master key.
                let mut bytes = vec![0u8; 32];
                rand::RngCore::fill_bytes(&mut OsRng, &mut bytes);

                let encoded = base64::engine::general_purpose::STANDARD.encode(&bytes);
                self.store
                    .write(MASTER_KEY_STORAGE_KEY, &encoded)
                    .map_err(|e| {
                        AppError::Crypto(format!(
                            "Cannot write to the platform keychain: {e}. \
                             The encryption key will not persist across app restarts."
                        ))
                    })?;

                Ok(bytes)
            })
            .await
            .map(|v| v.as_slice())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::key_manager::testing::InMemorySecretStore;

    fn make_crypto() -> AesGcmCrypto {
        AesGcmCrypto::new(Arc::new(InMemorySecretStore::new()))
    }

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
    async fn blob_format_nonce_and_tag() {
        let crypto = make_crypto();
        let plaintext = b"test data";
        let blob = crypto.encrypt(plaintext, "key1").await.unwrap();

        // blob = nonce (12) + ciphertext (len(plaintext)) + tag (16)
        assert_eq!(blob.len(), NONCE_LENGTH + plaintext.len() + TAG_LENGTH);

        // First 12 bytes are the nonce (non-zero with very high probability).
        let nonce = &blob[..NONCE_LENGTH];
        assert_eq!(nonce.len(), NONCE_LENGTH);

        // Last 16 bytes are the GCM tag.
        let tag = &blob[blob.len() - TAG_LENGTH..];
        assert_eq!(tag.len(), TAG_LENGTH);
    }

    #[tokio::test]
    async fn different_key_ids_produce_different_ciphertexts() {
        let crypto = make_crypto();
        let plaintext = b"same plaintext";
        let blob1 = crypto.encrypt(plaintext, "key_a").await.unwrap();
        let blob2 = crypto.encrypt(plaintext, "key_b").await.unwrap();
        // Ciphertexts differ because derived keys differ (and nonces differ).
        assert_ne!(blob1, blob2);
    }

    #[tokio::test]
    async fn hkdf_is_deterministic() {
        let store: Arc<dyn SecretStore> = Arc::new(InMemorySecretStore::new());
        let crypto = AesGcmCrypto::new(Arc::clone(&store));

        let key1 = crypto.derive_key("deterministic_test").await.unwrap();
        let key2 = crypto.derive_key("deterministic_test").await.unwrap();
        assert_eq!(key1, key2);

        // Different key_id produces a different derived key.
        let key3 = crypto.derive_key("other_purpose").await.unwrap();
        assert_ne!(key1, key3);
    }

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
        let mid = NONCE_LENGTH + 1;
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
}
