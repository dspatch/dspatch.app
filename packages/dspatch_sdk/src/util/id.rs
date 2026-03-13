// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Centralized ID generation. Replaces ~26 scattered `Uuid::new_v4().to_string()` calls.

/// Generates a new random UUID v4 string (lowercase, hyphenated).
pub fn new_id() -> String {
    uuid::Uuid::new_v4().to_string()
}
