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
async fn identity_store_roundtrip() {
    use dspatch_sdk::signal::identity_store::SqliteIdentityStore;
    let conn = test_db();
    let mut rng = rand::rng();
    let identity_key_pair = IdentityKeyPair::generate(&mut rng);
    let mut store = SqliteIdentityStore::new(conn, 42, identity_key_pair);

    assert_eq!(store.get_identity_key_pair().await.unwrap().serialize(), identity_key_pair.serialize());
    assert_eq!(store.get_local_registration_id().await.unwrap(), 42);

    let remote_pair = IdentityKeyPair::generate(&mut rng);
    let addr = ProtocolAddress::new("alice".to_string(), DeviceId::new(1).unwrap());
    let change = store.save_identity(&addr, remote_pair.identity_key()).await.unwrap();
    assert_eq!(change, IdentityChange::NewOrUnchanged);

    let loaded = store.get_identity(&addr).await.unwrap();
    assert_eq!(loaded, Some(*remote_pair.identity_key()));

    assert!(store.is_trusted_identity(&addr, remote_pair.identity_key(), Direction::Receiving).await.unwrap());
}

#[tokio::test]
async fn prekey_store_roundtrip() {
    use dspatch_sdk::signal::prekey_store::SqlitePreKeyStore;
    let conn = test_db();
    let mut store = SqlitePreKeyStore::new(conn);
    let mut rng = rand::rng();

    let key_pair = KeyPair::generate(&mut rng);
    let record = PreKeyRecord::new(PreKeyId::from(7), &key_pair);

    store.save_pre_key(PreKeyId::from(7), &record).await.unwrap();
    let loaded = store.get_pre_key(PreKeyId::from(7)).await.unwrap();
    assert_eq!(loaded.serialize().unwrap(), record.serialize().unwrap());

    store.remove_pre_key(PreKeyId::from(7)).await.unwrap();
    assert!(store.get_pre_key(PreKeyId::from(7)).await.is_err());
}

#[tokio::test]
async fn signed_prekey_store_roundtrip() {
    use dspatch_sdk::signal::signed_prekey_store::SqliteSignedPreKeyStore;
    let conn = test_db();
    let mut store = SqliteSignedPreKeyStore::new(conn);
    let mut rng = rand::rng();

    let key_pair = KeyPair::generate(&mut rng);
    let identity_pair = IdentityKeyPair::generate(&mut rng);
    let signature = identity_pair.private_key().calculate_signature(&key_pair.public_key.serialize(), &mut rng).unwrap();
    let timestamp = Timestamp::from_epoch_millis(1234567890);
    let record = SignedPreKeyRecord::new(SignedPreKeyId::from(1), timestamp, &key_pair, &signature);

    store.save_signed_pre_key(SignedPreKeyId::from(1), &record).await.unwrap();
    let loaded = store.get_signed_pre_key(SignedPreKeyId::from(1)).await.unwrap();
    assert_eq!(loaded.serialize().unwrap(), record.serialize().unwrap());
}

#[tokio::test]
async fn session_store_roundtrip() {
    use dspatch_sdk::signal::session_store::SqliteSessionStore;
    let conn = test_db();
    let mut store = SqliteSessionStore::new(conn);
    let addr = ProtocolAddress::new("bob".to_string(), DeviceId::new(1).unwrap());

    assert!(store.load_session(&addr).await.unwrap().is_none());

    let record = SessionRecord::new_fresh();
    store.store_session(&addr, &record).await.unwrap();
    let loaded = store.load_session(&addr).await.unwrap();
    assert!(loaded.is_some());
}

#[tokio::test]
async fn sender_key_store_roundtrip() {
    use dspatch_sdk::signal::sender_key_store::SqliteSenderKeyStore;
    let conn = test_db();
    let mut store = SqliteSenderKeyStore::new(conn);
    let addr = ProtocolAddress::new("charlie".to_string(), DeviceId::new(1).unwrap());
    let dist_id = uuid::Uuid::new_v4();

    let loaded = store.load_sender_key(&addr, dist_id).await.unwrap();
    assert!(loaded.is_none());
}
