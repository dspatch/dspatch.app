// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

/// An AES-256-GCM encrypted API key stored in the local database.
///
/// The [`encrypted_key`] blob is decrypted at runtime via AES-GCM crypto.
/// The [`provider_label`] is a human-readable tag indicating which LLM provider
/// (e.g. 'OpenAI', 'Anthropic') this key belongs to.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ApiKey {
    pub id: String,
    pub name: String,
    pub provider_label: String,
    pub encrypted_key: Vec<u8>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub display_hint: Option<String>,
    pub created_at: NaiveDateTime,
}
