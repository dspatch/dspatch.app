// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Base error type for all domain-level errors in the SDK.
///
/// Each variant represents a specific error category. Use with [`Result<T>`](super::result::Result)
/// for operations that can fail without panicking.
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    /// Input validation failed (e.g. empty name, invalid URL format).
    #[error("ValidationError: {0}")]
    Validation(String),

    /// A requested entity was not found (e.g. provider by ID).
    #[error("NotFoundError: {0}")]
    NotFound(String),

    /// Database or file system storage operation failed.
    #[error("StorageError: {0}")]
    Storage(String),

    /// Docker daemon or container operation failed.
    #[error("DockerError: {0}")]
    Docker(String),

    /// Embedded server or network operation failed.
    #[error("ServerError: {0}")]
    Server(String),

    /// Encryption, decryption, or key derivation failed.
    #[error("CryptoError: {0}")]
    Crypto(String),

    /// Secure storage operation failed and requires user intervention.
    ///
    /// Typically means the master encryption key was lost (keychain entry
    /// deleted externally) so previously-encrypted API keys are undecryptable.
    /// The UI should prompt the user to re-enter API keys.
    #[error("SecureStorageFailure: {0}")]
    SecureStorageFailure(String),

    /// Platform-specific operation unsupported or failed.
    #[error("PlatformError: {0}")]
    Platform(String),

    /// Authentication or authorization failed.
    #[error("AuthError: {0}")]
    Auth(String),

    /// Backend API returned an error response.
    #[error("ApiError: {message}")]
    Api {
        message: String,
        status_code: Option<u16>,
        body: Option<String>,
    },

    /// Internal SDK state error (misconfiguration, uninitialised access).
    #[error("InternalError: {0}")]
    Internal(String),
}
