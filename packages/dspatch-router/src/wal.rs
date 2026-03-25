//! Write-ahead log for persistent buffering across engine disconnections.
//!
//! Append-only JSON-lines file. Each entry: [seq, direction, timestamp_ms, package_json].
//! Entries are replayed on reconnect and truncated on acknowledgement.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs::{File, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum WalDirection {
    Outbound,
    Inbound,
}

#[derive(Debug, Clone)]
pub struct WalEntry {
    pub seq: u64,
    pub direction: WalDirection,
    pub timestamp_ms: u64,
    pub data: Value,
}

pub struct Wal {
    path: PathBuf,
    entries: Vec<WalEntry>,
    next_seq: u64,
}

impl Wal {
    pub fn open(path: &Path) -> Result<Self> {
        let mut entries = Vec::new();
        let mut max_seq: u64 = 0;

        if path.exists() {
            let file = File::open(path).context("Failed to open WAL")?;
            let reader = BufReader::new(file);
            for line in reader.lines() {
                let line = line.context("Failed to read WAL line")?;
                if line.trim().is_empty() {
                    continue;
                }
                if let Ok(row) = serde_json::from_str::<(u64, WalDirection, u64, Value)>(&line) {
                    max_seq = max_seq.max(row.0);
                    entries.push(WalEntry {
                        seq: row.0,
                        direction: row.1,
                        timestamp_ms: row.2,
                        data: row.3,
                    });
                }
            }
        }

        Ok(Self {
            path: path.to_owned(),
            entries,
            next_seq: max_seq + 1,
        })
    }

    pub fn append(&mut self, direction: WalDirection, data: Value) -> Result<u64> {
        let seq = self.next_seq;
        self.next_seq += 1;
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let entry = WalEntry {
            seq,
            direction,
            timestamp_ms: ts,
            data: data.clone(),
        };

        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)
            .context("Failed to open WAL for append")?;

        let row = serde_json::to_string(&(seq, direction, ts, &data))?;
        writeln!(file, "{}", row)?;
        file.flush()?;

        self.entries.push(entry);
        Ok(seq)
    }

    pub fn ack(&mut self, direction: WalDirection, up_to_seq: u64) {
        self.entries
            .retain(|e| !(e.direction == direction && e.seq <= up_to_seq));
        self.rewrite_file();
    }

    pub fn unacked_entries(&self, direction: WalDirection) -> Vec<&WalEntry> {
        self.entries
            .iter()
            .filter(|e| e.direction == direction)
            .collect()
    }

    fn rewrite_file(&self) {
        if let Ok(mut file) = File::create(&self.path) {
            for entry in &self.entries {
                if let Ok(row) = serde_json::to_string(&(
                    entry.seq,
                    &entry.direction,
                    entry.timestamp_ms,
                    &entry.data,
                )) {
                    let _ = writeln!(file, "{}", row);
                }
            }
            let _ = file.flush();
        }
    }
}
