// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! SignalService — wrapper around `libsignal-protocol` for E2E encrypted messaging.

use std::sync::Arc;

use parking_lot::Mutex;
use std::time::SystemTime;

use libsignal_protocol::*;
use rand::{CryptoRng, Rng};
use rusqlite::Connection;

use super::identity_store::SqliteIdentityStore;
use super::kyber_prekey_store::SqliteKyberPreKeyStore;
use super::prekey_store::SqlitePreKeyStore;
use super::sender_key_store::SqliteSenderKeyStore;
use super::session_store::SqliteSessionStore;
use super::signed_prekey_store::SqliteSignedPreKeyStore;

pub struct SignalService {
    pub identity_store: SqliteIdentityStore,
    pub prekey_store: SqlitePreKeyStore,
    pub signed_prekey_store: SqliteSignedPreKeyStore,
    pub session_store: SqliteSessionStore,
    pub sender_key_store: SqliteSenderKeyStore,
    pub kyber_prekey_store: SqliteKyberPreKeyStore,
}

impl SignalService {
    pub fn new(
        conn: Arc<Mutex<Connection>>,
        local_registration_id: u32,
        identity_key_pair: IdentityKeyPair,
    ) -> Self {
        Self {
            identity_store: SqliteIdentityStore::new(Arc::clone(&conn), local_registration_id, identity_key_pair),
            prekey_store: SqlitePreKeyStore::new(Arc::clone(&conn)),
            signed_prekey_store: SqliteSignedPreKeyStore::new(Arc::clone(&conn)),
            session_store: SqliteSessionStore::new(Arc::clone(&conn)),
            sender_key_store: SqliteSenderKeyStore::new(Arc::clone(&conn)),
            kyber_prekey_store: SqliteKyberPreKeyStore::new(conn),
        }
    }

    pub async fn generate_prekey<R: Rng + CryptoRng>(
        &mut self, id: u32, csprng: &mut R,
    ) -> Result<PreKeyRecord, SignalProtocolError> {
        let key_pair = KeyPair::generate(csprng);
        let record = PreKeyRecord::new(PreKeyId::from(id), &key_pair);
        self.prekey_store.save_pre_key(PreKeyId::from(id), &record).await?;
        Ok(record)
    }

    pub async fn generate_prekeys<R: Rng + CryptoRng>(
        &mut self, start_id: u32, count: u32, csprng: &mut R,
    ) -> Result<Vec<PreKeyRecord>, SignalProtocolError> {
        let mut records = Vec::with_capacity(count as usize);
        for i in 0..count {
            let record = self.generate_prekey(start_id + i, csprng).await?;
            records.push(record);
        }
        Ok(records)
    }

    pub async fn generate_signed_prekey<R: Rng + CryptoRng>(
        &mut self, id: u32, csprng: &mut R,
    ) -> Result<SignedPreKeyRecord, SignalProtocolError> {
        let identity_key_pair = self.identity_store.get_identity_key_pair().await?;
        let key_pair = KeyPair::generate(csprng);
        let signature = identity_key_pair.private_key().calculate_signature(&key_pair.public_key.serialize(), csprng)?;
        let timestamp_millis = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap_or_default().as_millis() as u64;
        let timestamp = Timestamp::from_epoch_millis(timestamp_millis);
        let record = SignedPreKeyRecord::new(SignedPreKeyId::from(id), timestamp, &key_pair, &signature);
        self.signed_prekey_store.save_signed_pre_key(SignedPreKeyId::from(id), &record).await?;
        Ok(record)
    }

    pub async fn generate_kyber_prekey(
        &mut self, id: u32,
    ) -> Result<KyberPreKeyRecord, SignalProtocolError> {
        let identity_key_pair = self.identity_store.get_identity_key_pair().await?;
        let record = KyberPreKeyRecord::generate(
            kem::KeyType::Kyber1024,
            KyberPreKeyId::from(id),
            identity_key_pair.private_key(),
        )?;
        self.kyber_prekey_store.save_kyber_pre_key(KyberPreKeyId::from(id), &record).await?;
        Ok(record)
    }

    /// Returns the number of prekeys currently available in the local store.
    pub async fn available_prekey_count(&self) -> usize {
        self.prekey_store.count_available().await
    }

    /// Generates additional prekeys until the stored count reaches `target_count`.
    ///
    /// Returns the newly generated records (empty if already at or above target).
    pub async fn replenish_prekeys<R: Rng + CryptoRng>(
        &mut self, target_count: u32, csprng: &mut R,
    ) -> Result<Vec<PreKeyRecord>, SignalProtocolError> {
        let current = self.available_prekey_count().await;
        if current >= target_count as usize {
            return Ok(vec![]);
        }
        let needed = target_count as usize - current;
        // Start new IDs immediately after the current highest ID.
        let next_id = self.prekey_store.max_id().await + 1;
        self.generate_prekeys(next_id, needed as u32, csprng).await
    }

    pub async fn process_prekey_bundle<R: Rng + CryptoRng>(
        &mut self, remote_address: &ProtocolAddress, bundle: &PreKeyBundle, csprng: &mut R,
    ) -> Result<(), SignalProtocolError> {
        libsignal_protocol::process_prekey_bundle(
            remote_address,
            &mut self.session_store,
            &mut self.identity_store,
            bundle,
            SystemTime::now(),
            csprng,
        ).await
    }

    pub async fn encrypt<R: Rng + CryptoRng>(
        &mut self, remote_address: &ProtocolAddress, plaintext: &[u8], csprng: &mut R,
    ) -> Result<Vec<u8>, SignalProtocolError> {
        let ciphertext = message_encrypt(
            plaintext,
            remote_address,
            &mut self.session_store,
            &mut self.identity_store,
            SystemTime::now(),
            csprng,
        ).await?;
        Ok(ciphertext.serialize().to_vec())
    }

    pub async fn decrypt<R: Rng + CryptoRng>(
        &mut self, remote_address: &ProtocolAddress, ciphertext: &[u8], csprng: &mut R,
    ) -> Result<Vec<u8>, SignalProtocolError> {
        // Try PreKeySignalMessage first, fall back to SignalMessage.
        if let Ok(pre_key_msg) = PreKeySignalMessage::try_from(ciphertext) {
            return message_decrypt_prekey(
                &pre_key_msg,
                remote_address,
                &mut self.session_store,
                &mut self.identity_store,
                &mut self.prekey_store,
                &self.signed_prekey_store,
                &mut self.kyber_prekey_store,
                csprng,
            ).await;
        }

        let signal_msg = SignalMessage::try_from(ciphertext)?;
        message_decrypt_signal(
            &signal_msg,
            remote_address,
            &mut self.session_store,
            &mut self.identity_store,
            csprng,
        ).await
    }
}
