use libsignal_protocol::*;
use std::sync::{Arc, Mutex};

fn test_db() -> Arc<Mutex<rusqlite::Connection>> {
    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "CREATE TABLE signal_identities (
            address TEXT NOT NULL, device_id INTEGER NOT NULL,
            identity_key BLOB NOT NULL, trust_level INTEGER NOT NULL DEFAULT 1,
            PRIMARY KEY (address, device_id)
        );
        CREATE TABLE signal_prekeys (id INTEGER PRIMARY KEY, record BLOB NOT NULL);
        CREATE TABLE signal_signed_prekeys (
            id INTEGER PRIMARY KEY, record BLOB NOT NULL, created_at TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE signal_sessions (
            address TEXT NOT NULL, device_id INTEGER NOT NULL, record BLOB NOT NULL,
            PRIMARY KEY (address, device_id)
        );
        CREATE TABLE signal_sender_keys (
            sender_address TEXT NOT NULL, device_id INTEGER NOT NULL,
            distribution_id TEXT NOT NULL, record BLOB NOT NULL,
            PRIMARY KEY (sender_address, device_id, distribution_id)
        );
        CREATE TABLE signal_kyber_prekeys (id INTEGER PRIMARY KEY, record BLOB NOT NULL);",
    )
    .unwrap();
    Arc::new(Mutex::new(conn))
}

#[tokio::test]
async fn signal_service_encrypt_decrypt_roundtrip() {
    use dspatch_sdk::signal::SignalService;
    let mut rng = rand::rng();

    let alice_db = test_db();
    let alice_identity = IdentityKeyPair::generate(&mut rng);
    let mut alice = SignalService::new(alice_db, 1, alice_identity);

    let bob_db = test_db();
    let bob_identity = IdentityKeyPair::generate(&mut rng);
    let mut bob = SignalService::new(bob_db, 2, bob_identity);

    // Generate Bob's keys
    let bob_signed_prekey = bob.generate_signed_prekey(1, &mut rng).await.unwrap();
    let bob_prekey = bob.generate_prekey(5, &mut rng).await.unwrap();
    let bob_kyber_prekey = bob.generate_kyber_prekey(1).await.unwrap();

    let bob_bundle = PreKeyBundle::new(
        2,
        DeviceId::new(1).unwrap(),
        Some((PreKeyId::from(5), bob_prekey.public_key().unwrap())),
        SignedPreKeyId::from(1),
        bob_signed_prekey.public_key().unwrap(),
        bob_signed_prekey.signature().unwrap(),
        KyberPreKeyId::from(1),
        bob_kyber_prekey.public_key().unwrap(),
        bob_kyber_prekey.signature().unwrap(),
        *bob_identity.identity_key(),
    ).unwrap();

    let bob_addr = ProtocolAddress::new("bob".to_string(), DeviceId::new(1).unwrap());
    alice.process_prekey_bundle(&bob_addr, &bob_bundle, &mut rng).await.unwrap();

    let plaintext = b"Hello from Alice!";
    let ciphertext = alice.encrypt(&bob_addr, plaintext, &mut rng).await.unwrap();

    let alice_addr = ProtocolAddress::new("alice".to_string(), DeviceId::new(1).unwrap());
    let decrypted = bob.decrypt(&alice_addr, &ciphertext, &mut rng).await.unwrap();
    assert_eq!(decrypted, plaintext);
}

#[tokio::test]
async fn signal_service_generates_prekeys() {
    use dspatch_sdk::signal::SignalService;
    let db = test_db();
    let mut rng = rand::rng();
    let identity = IdentityKeyPair::generate(&mut rng);
    let mut service = SignalService::new(db, 1, identity);

    let prekeys = service.generate_prekeys(1, 10, &mut rng).await.unwrap();
    assert_eq!(prekeys.len(), 10);
}
