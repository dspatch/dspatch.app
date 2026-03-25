use dspatch_router::wal::{Wal, WalDirection};
use serde_json::json;
use tempfile::NamedTempFile;

#[test]
fn append_and_read_entries() {
    let f = NamedTempFile::new().unwrap();
    let mut wal = Wal::open(f.path()).unwrap();

    wal.append(WalDirection::Outbound, json!({"type": "agent.output.message"})).unwrap();
    wal.append(WalDirection::Outbound, json!({"type": "agent.output.log"})).unwrap();

    let entries = wal.unacked_entries(WalDirection::Outbound);
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[0].seq, 1);
    assert_eq!(entries[1].seq, 2);
}

#[test]
fn ack_truncates() {
    let f = NamedTempFile::new().unwrap();
    let mut wal = Wal::open(f.path()).unwrap();

    wal.append(WalDirection::Outbound, json!({"seq": 1})).unwrap();
    wal.append(WalDirection::Outbound, json!({"seq": 2})).unwrap();
    wal.append(WalDirection::Outbound, json!({"seq": 3})).unwrap();

    wal.ack(WalDirection::Outbound, 2);
    let remaining = wal.unacked_entries(WalDirection::Outbound);
    assert_eq!(remaining.len(), 1);
    assert_eq!(remaining[0].seq, 3);
}

#[test]
fn survives_reopen() {
    let f = NamedTempFile::new().unwrap();
    let path = f.path().to_owned();

    {
        let mut wal = Wal::open(&path).unwrap();
        wal.append(WalDirection::Outbound, json!({"msg": "hello"})).unwrap();
        wal.append(WalDirection::Outbound, json!({"msg": "world"})).unwrap();
        wal.ack(WalDirection::Outbound, 1);
    }

    let wal = Wal::open(&path).unwrap();
    let entries = wal.unacked_entries(WalDirection::Outbound);
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].data["msg"], "world");
}

#[test]
fn bidirectional_independence() {
    let f = NamedTempFile::new().unwrap();
    let mut wal = Wal::open(f.path()).unwrap();

    wal.append(WalDirection::Outbound, json!({"dir": "out"})).unwrap();
    wal.append(WalDirection::Inbound, json!({"dir": "in"})).unwrap();

    assert_eq!(wal.unacked_entries(WalDirection::Outbound).len(), 1);
    assert_eq!(wal.unacked_entries(WalDirection::Inbound).len(), 1);

    wal.ack(WalDirection::Outbound, 1);
    assert_eq!(wal.unacked_entries(WalDirection::Outbound).len(), 0);
    assert_eq!(wal.unacked_entries(WalDirection::Inbound).len(), 1);
}
