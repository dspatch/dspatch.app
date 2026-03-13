// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Helper for extracting typed column values from rusqlite rows with consistent
//! error mapping. Replaces ~250 `.map_err(|e| AppError::Storage(...))` sites.

use crate::util::error::AppError;
use crate::util::result::Result;

/// Reads column `idx` from `row`, mapping any rusqlite error to
/// `AppError::Storage` with the column name for diagnostics.
///
/// Usage: `let name: String = col(row, 0, "name")?;`
pub fn col<T: rusqlite::types::FromSql>(
    row: &rusqlite::Row<'_>,
    idx: usize,
    name: &str,
) -> Result<T> {
    row.get(idx)
        .map_err(|e| AppError::Storage(format!("Failed to read {name}: {e}")))
}
