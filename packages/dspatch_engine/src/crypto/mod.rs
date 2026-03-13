// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! AES-256-GCM crypto layer with HKDF-SHA256 key derivation and
//! platform-specific secret storage.
//!
//! Ported from `core/crypto/aes_gcm.dart` and `core/crypto/secure_storage_fallback.dart`.

pub mod aes_gcm;
pub mod secure_storage;

pub use aes_gcm::AesGcmCrypto;
pub use secure_storage::KeyringSecretStore;
