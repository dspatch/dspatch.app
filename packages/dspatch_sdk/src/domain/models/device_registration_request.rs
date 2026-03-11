// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use serde::{Deserialize, Serialize};

/// A one-time pre-key for Signal Protocol key exchange.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PreKey {
    pub key_id: i64,
    pub key: Vec<u8>,
}

/// Request payload for first-device registration.
///
/// Binary fields are serialized as integer arrays to match the backend's
/// expected format (compatible with Dart's `Uint8List.toList()`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DeviceRegistrationRequest {
    /// Human-readable device name (e.g. hostname).
    pub name: String,

    /// Broad device category: 'desktop' or 'mobile'.
    pub device_type: String,

    /// OS platform: 'windows', 'macos', 'linux', 'ios', 'android'.
    pub platform: String,

    /// Ed25519 public identity key (32 bytes).
    pub identity_key: Vec<u8>,

    /// Curve25519 signed pre-key (32 bytes).
    pub signed_pre_key: Vec<u8>,

    /// Integer ID for the signed pre-key.
    pub signed_pre_key_id: i64,

    /// Ed25519 signature over the signed pre-key (64 bytes).
    pub signed_pre_key_signature: Vec<u8>,

    /// Optional one-time pre-keys for Signal Protocol.
    #[serde(default)]
    pub one_time_pre_keys: Vec<PreKey>,
}
