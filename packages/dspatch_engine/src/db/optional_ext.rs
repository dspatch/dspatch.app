// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Shared extension trait for converting `rusqlite::Error::QueryReturnedNoRows`
//! into `Ok(None)`. Replaces 11 identical private definitions across DAOs and
//! signal stores.

/// Converts a `QueryReturnedNoRows` error into `Ok(None)`, passing through
/// all other results unchanged.
pub trait OptionalExt<T> {
    fn optional(self) -> std::result::Result<Option<T>, rusqlite::Error>;
}

impl<T> OptionalExt<T> for std::result::Result<T, rusqlite::Error> {
    fn optional(self) -> std::result::Result<Option<T>, rusqlite::Error> {
        match self {
            Ok(v) => Ok(Some(v)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e),
        }
    }
}
