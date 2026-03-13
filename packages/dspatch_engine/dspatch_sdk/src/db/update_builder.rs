// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Shared macros for building dynamic UPDATE SET clauses in DAOs.

/// Appends `"col = ?N"` to `$sets` and pushes `$val` to `$params` if `$opt` is `Some`.
///
/// Expects `$sets: Vec<String>`, `$params: Vec<Box<dyn rusqlite::types::ToSql>>`,
/// `$idx: integer counter` to be in scope.
///
/// Usage:
/// ```ignore
/// maybe_set!(sets, params, idx, opt_name, "name");
/// ```
#[macro_export]
macro_rules! maybe_set {
    ($sets:ident, $params:ident, $idx:ident, $opt:expr, $col:expr) => {
        if let Some(ref val) = $opt {
            $sets.push(format!("{} = ?{}", $col, $idx));
            $params.push(Box::new(val.clone()) as Box<dyn rusqlite::types::ToSql>);
            $idx += 1;
        }
    };
}

/// Like `maybe_set!`, but JSON-serializes the value first.
///
/// Returns early with `AppError::Storage` on serialization failure.
#[macro_export]
macro_rules! maybe_set_json {
    ($sets:ident, $params:ident, $idx:ident, $opt:expr, $col:expr) => {
        if let Some(ref val) = $opt {
            let json = serde_json::to_string(val)
                .map_err(|e| $crate::util::error::AppError::Storage(
                    format!("JSON encode failed: {e}")
                ))?;
            $sets.push(format!("{} = ?{}", $col, $idx));
            $params.push(Box::new(json) as Box<dyn rusqlite::types::ToSql>);
            $idx += 1;
        }
    };
}
