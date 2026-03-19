// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! X3DH session establishment for Signal Protocol.
//!
//! Before two devices can exchange encrypted sync messages, they need to
//! establish a Signal session via X3DH key agreement. This module handles
//! fetching a peer's prekey bundle from the backend and processing it to
//! create the session.

use std::collections::HashMap;
use std::sync::Arc;

use libsignal_protocol::{DeviceId, IdentityKey, IdentityKeyStore, KyberPreKeyId, PreKeyBundle, PreKeyId, ProtocolAddress, PublicKey, SessionStore, SignedPreKeyId};
use tokio::sync::Mutex;

use crate::domain::services::ApiClient;
use crate::signal::SignalService;
use crate::util::error::AppError;
use crate::util::result::Result;

/// Fetches a peer's prekey bundle from the backend and establishes an X3DH session.
///
/// If a session already exists for the peer, this is a no-op.
pub async fn establish_signal_session(
    signal: &Arc<Mutex<SignalService>>,
    api_client: &dyn ApiClient,
    peer_device_id: &str,
) -> Result<()> {
    let addr = ProtocolAddress::new(
        peer_device_id.to_string(),
        DeviceId::new(1).expect("valid device id"),
    );

    // Fetch prekey bundle from backend first so we can check for identity key changes.
    let response = api_client
        .get(&format!("/api/keys/bundle/{}", peer_device_id), None)
        .await
        .map_err(|e| {
            AppError::Server(format!(
                "Failed to fetch prekey bundle for {peer_device_id}: {e}"
            ))
        })?;

    if !response.is_success() {
        return Err(AppError::Api {
            message: format!("Prekey bundle request failed for {peer_device_id}"),
            status_code: Some(response.status_code),
            body: Some(response.raw_body),
        });
    }

    // Parse the bundle response.
    let bundle = parse_prekey_bundle(&response.raw_body)?;

    // Check for an existing session and detect identity key changes.
    {
        let signal = signal.lock().await;
        if let Ok(Some(_existing_session)) = signal.session_store.load_session(&addr).await {
            let stored_identity = signal.identity_store.get_identity(&addr).await
                .map_err(|e| AppError::Internal(format!("Failed to load stored identity for {peer_device_id}: {e}")))?;
            let bundle_identity = bundle.identity_key().ok();
            if stored_identity.as_ref() != bundle_identity {
                tracing::warn!(
                    "Identity key changed for {peer_device_id}, forcing new session"
                );
                signal
                    .session_store
                    .delete_session(&addr)
                    .await
                    .map_err(|e| AppError::Internal(format!("Failed to delete stale session: {e}")))?;
                // Fall through to re-establish below.
            } else {
                tracing::debug!("Signal session already exists for {peer_device_id}");
                return Ok(());
            }
        }
    }

    // Process bundle to establish X3DH session.
    let mut signal = signal.lock().await;
    signal
        .process_prekey_bundle(&addr, &bundle, &mut rand::rng())
        .await
        .map_err(|e| AppError::Internal(format!("X3DH session establishment failed: {e}")))?;

    tracing::info!("Established Signal session with {peer_device_id}");
    Ok(())
}

/// Parses a prekey bundle JSON response from the backend.
///
/// Expected format:
/// ```json
/// {
///   "registration_id": 12345,
///   "identity_key": "<base64>",
///   "signed_prekey_id": 1,
///   "signed_prekey": "<base64>",
///   "signed_prekey_signature": "<base64>",
///   "prekey_id": 42,
///   "prekey": "<base64>",
///   "kyber_prekey_id": 1,
///   "kyber_prekey": "<base64>",
///   "kyber_prekey_signature": "<base64>"
/// }
/// ```
fn parse_prekey_bundle(json: &str) -> Result<PreKeyBundle> {
    use base64::{engine::general_purpose::STANDARD, Engine};

    let v: serde_json::Value = serde_json::from_str(json)
        .map_err(|e| AppError::Internal(format!("Invalid prekey bundle JSON: {e}")))?;

    let registration_id = v["registration_id"]
        .as_u64()
        .ok_or_else(|| AppError::Internal("Missing registration_id in prekey bundle".into()))?
        as u32;

    let identity_key_bytes = STANDARD
        .decode(v["identity_key"].as_str().unwrap_or_default())
        .map_err(|e| AppError::Internal(format!("Invalid identity_key base64: {e}")))?;
    let identity_key_pub = PublicKey::deserialize(&identity_key_bytes)
        .map_err(|e| AppError::Internal(format!("Invalid identity_key: {e}")))?;
    let identity_key = IdentityKey::new(identity_key_pub);

    let signed_prekey_id = SignedPreKeyId::from(
        v["signed_prekey_id"]
            .as_u64()
            .ok_or_else(|| AppError::Internal("Missing signed_prekey_id".into()))?
            as u32,
    );

    let signed_prekey_bytes = STANDARD
        .decode(v["signed_prekey"].as_str().unwrap_or_default())
        .map_err(|e| AppError::Internal(format!("Invalid signed_prekey base64: {e}")))?;
    let signed_prekey = PublicKey::deserialize(&signed_prekey_bytes)
        .map_err(|e| AppError::Internal(format!("Invalid signed_prekey: {e}")))?;

    let signed_prekey_signature = STANDARD
        .decode(
            v["signed_prekey_signature"]
                .as_str()
                .unwrap_or_default(),
        )
        .map_err(|e| AppError::Internal(format!("Invalid signed_prekey_signature base64: {e}")))?;

    let device_id = DeviceId::new(1).expect("valid device id");

    // Parse optional one-time prekey.
    let prekey = if let (Some(pk_id), Some(pk_b64)) =
        (v["prekey_id"].as_u64(), v["prekey"].as_str())
    {
        let pk_bytes = STANDARD
            .decode(pk_b64)
            .map_err(|e| AppError::Internal(format!("Invalid prekey base64: {e}")))?;
        let pk = PublicKey::deserialize(&pk_bytes)
            .map_err(|e| AppError::Internal(format!("Invalid prekey: {e}")))?;
        Some((PreKeyId::from(pk_id as u32), pk))
    } else {
        None
    };

    // Parse Kyber prekey (required by libsignal PreKeyBundle).
    let kyber_prekey_id = KyberPreKeyId::from(
        v["kyber_prekey_id"]
            .as_u64()
            .ok_or_else(|| AppError::Internal("Missing kyber_prekey_id".into()))?
            as u32,
    );

    let kyber_prekey_bytes = STANDARD
        .decode(v["kyber_prekey"].as_str().unwrap_or_default())
        .map_err(|e| AppError::Internal(format!("Invalid kyber_prekey base64: {e}")))?;
    let kyber_prekey = libsignal_protocol::kem::PublicKey::deserialize(&kyber_prekey_bytes)
        .map_err(|e| AppError::Internal(format!("Invalid kyber_prekey: {e}")))?;

    let kyber_prekey_signature = STANDARD
        .decode(v["kyber_prekey_signature"].as_str().unwrap_or_default())
        .map_err(|e| AppError::Internal(format!("Invalid kyber_prekey_signature base64: {e}")))?;

    PreKeyBundle::new(
        registration_id,
        device_id,
        prekey,
        signed_prekey_id,
        signed_prekey,
        signed_prekey_signature,
        kyber_prekey_id,
        kyber_prekey,
        kyber_prekey_signature,
        identity_key,
    )
    .map_err(|e| AppError::Internal(format!("Failed to create PreKeyBundle: {e}")))
}

/// Decrypts a message and automatically resets the session after 3 consecutive
/// failures for the same peer, then re-establishes a fresh X3DH session.
///
/// `failure_counts` must be the same map across calls (owned by the caller, e.g.
/// `PeerConnectionManager`) so that consecutive failures can be tracked.
pub async fn decrypt_or_reset_session(
    signal: &Arc<Mutex<SignalService>>,
    api_client: &dyn ApiClient,
    peer_device_id: &str,
    ciphertext: &[u8],
    failure_counts: &mut HashMap<String, u32>,
) -> Result<Vec<u8>> {
    let addr = ProtocolAddress::new(
        peer_device_id.to_string(),
        DeviceId::new(1).expect("valid device id"),
    );

    let result = {
        let mut signal = signal.lock().await;
        signal
            .decrypt(&addr, ciphertext, &mut rand::rng())
            .await
            .map_err(|e| AppError::Internal(format!("Signal decrypt failed: {e}")))
    };

    match result {
        Ok(plaintext) => {
            // Success — reset the failure counter for this peer.
            failure_counts.remove(peer_device_id);
            Ok(plaintext)
        }
        Err(e) => {
            let count = failure_counts
                .entry(peer_device_id.to_string())
                .or_insert(0);
            *count += 1;

            if *count >= 3 {
                tracing::warn!(
                    "3 consecutive decrypt failures for {peer_device_id}, resetting session"
                );
                failure_counts.remove(peer_device_id);

                {
                    let signal = signal.lock().await;
                    signal
                        .session_store
                        .delete_session(&addr)
                        .await
                        .map_err(|del_err| {
                            AppError::Internal(format!(
                                "Failed to delete session for {peer_device_id}: {del_err}"
                            ))
                        })?;
                }

                establish_signal_session(signal, api_client, peer_device_id).await?;
            }

            Err(e)
        }
    }
}
