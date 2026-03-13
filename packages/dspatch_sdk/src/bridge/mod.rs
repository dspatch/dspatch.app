// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Flutter Rust Bridge integration layer.
//!
//! Exposes [`DspatchSdk`] to Flutter via `flutter_rust_bridge` annotations.
//! All methods return `Result<T, String>` for FRB serialization compatibility.

pub mod api;
