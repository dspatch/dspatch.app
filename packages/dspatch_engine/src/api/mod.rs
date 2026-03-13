// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Backend API client, token storage, and connected auth service.
//!
//! Ported from `data/api/` in the Dart SDK.

mod client;
mod connected_auth;
mod token_storage;

pub use client::HttpApiClient;
pub use connected_auth::ConnectedAuthService;
pub use token_storage::TokenStorage;
