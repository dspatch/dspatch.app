// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Maps `AppError` variants to machine-readable JSON error codes for the
//! client API wire protocol.
//!
//! The Dart client matches on the `code` string to decide how to present
//! errors (e.g. show retry button for `STORAGE_ERROR`, show login prompt
//! for `AUTH_ERROR`).

use crate::client_api::protocol::ServerFrame;
use crate::util::error::AppError;

/// Returns the machine-readable error code for an `AppError`.
///
/// These codes are stable — changing them is a breaking protocol change.
pub fn error_to_code(error: &AppError) -> &'static str {
    match error {
        AppError::Validation(_) => "VALIDATION_ERROR",
        AppError::NotFound(_) => "NOT_FOUND",
        AppError::Storage(_) => "STORAGE_ERROR",
        AppError::Docker(_) => "DOCKER_ERROR",
        AppError::Server(_) => "SERVER_ERROR",
        AppError::Crypto(_) => "CRYPTO_ERROR",
        AppError::SecureStorageFailure(_) => "SECURE_STORAGE_FAILURE",
        AppError::Platform(_) => "PLATFORM_ERROR",
        AppError::Auth(_) => "AUTH_ERROR",
        AppError::Api { .. } => "API_ERROR",
        AppError::Internal(_) => "INTERNAL_ERROR",
    }
}

/// Converts an `AppError` into a `ServerFrame::Error` with the given
/// correlation ID.
pub fn error_to_frame(command_id: &str, error: &AppError) -> ServerFrame {
    ServerFrame::Error {
        id: Some(command_id.to_string()),
        code: error_to_code(error).to_string(),
        message: error.to_string(),
    }
}
