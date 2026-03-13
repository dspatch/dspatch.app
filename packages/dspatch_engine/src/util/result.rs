// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use super::error::AppError;

/// A type alias for `std::result::Result<T, AppError>`.
///
/// In Rust, `Result` already provides pattern matching via `match`, `map`, `and_then`,
/// and the `?` operator — so a custom sealed class like Dart's `Result<T>` is unnecessary.
pub type Result<T> = std::result::Result<T, AppError>;
