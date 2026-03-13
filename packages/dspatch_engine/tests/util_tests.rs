// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use dspatch_engine::util::error::AppError;
use dspatch_engine::util::format::format_bytes;
use dspatch_engine::util::result::Result;

#[test]
fn app_error_display_validation() {
    let err = AppError::Validation("name cannot be empty".into());
    assert_eq!(err.to_string(), "ValidationError: name cannot be empty");
}

#[test]
fn app_error_display_not_found() {
    let err = AppError::NotFound("provider 123 not found".into());
    assert_eq!(err.to_string(), "NotFoundError: provider 123 not found");
}

#[test]
fn app_error_display_storage() {
    let err = AppError::Storage("disk full".into());
    assert_eq!(err.to_string(), "StorageError: disk full");
}

#[test]
fn app_error_display_docker() {
    let err = AppError::Docker("daemon not running".into());
    assert_eq!(err.to_string(), "DockerError: daemon not running");
}

#[test]
fn app_error_display_server() {
    let err = AppError::Server("port in use".into());
    assert_eq!(err.to_string(), "ServerError: port in use");
}

#[test]
fn app_error_display_crypto() {
    let err = AppError::Crypto("bad key".into());
    assert_eq!(err.to_string(), "CryptoError: bad key");
}

#[test]
fn app_error_display_platform() {
    let err = AppError::Platform("unsupported OS".into());
    assert_eq!(err.to_string(), "PlatformError: unsupported OS");
}

#[test]
fn app_error_display_auth() {
    let err = AppError::Auth("token expired".into());
    assert_eq!(err.to_string(), "AuthError: token expired");
}

#[test]
fn app_error_display_api() {
    let err = AppError::Api {
        message: "rate limited".into(),
        status_code: Some(429),
        body: Some("{\"error\":\"too many requests\"}".into()),
    };
    assert_eq!(err.to_string(), "ApiError: rate limited");
}

#[test]
fn app_error_api_without_optional_fields() {
    let err = AppError::Api {
        message: "unknown".into(),
        status_code: None,
        body: None,
    };
    assert_eq!(err.to_string(), "ApiError: unknown");
}

#[test]
fn result_type_alias_ok() {
    let result: Result<i32> = Ok(42);
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), 42);
}

#[test]
fn result_type_alias_err() {
    let result: Result<i32> = Err(AppError::NotFound("missing".into()));
    assert!(result.is_err());
}

#[test]
fn format_bytes_values() {
    assert_eq!(format_bytes(0), "0 B");
    assert_eq!(format_bytes(512), "512 B");
    assert_eq!(format_bytes(1024), "1.0 KB");
    assert_eq!(format_bytes(1536), "1.5 KB");
    assert_eq!(format_bytes(1048576), "1.0 MB");
    assert_eq!(format_bytes(1073741824), "1.0 GB");
    assert_eq!(format_bytes(2415919104), "2.2 GB");
    assert_eq!(format_bytes(2524971008), "2.4 GB");
}

#[test]
fn optional_ext_converts_no_rows_to_none() {
    use dspatch_engine::db::optional_ext::OptionalExt;
    let result: std::result::Result<String, rusqlite::Error> =
        Err(rusqlite::Error::QueryReturnedNoRows);
    assert_eq!(result.optional().unwrap(), None);
}

#[test]
fn optional_ext_passes_through_ok() {
    use dspatch_engine::db::optional_ext::OptionalExt;
    let result: std::result::Result<String, rusqlite::Error> = Ok("hello".into());
    assert_eq!(result.optional().unwrap(), Some("hello".into()));
}

#[test]
fn optional_ext_preserves_other_errors() {
    use dspatch_engine::db::optional_ext::OptionalExt;
    let result: std::result::Result<String, rusqlite::Error> =
        Err(rusqlite::Error::InvalidParameterCount(0, 1));
    assert!(result.optional().is_err());
}

#[test]
fn new_id_returns_valid_uuid_v4_string() {
    use dspatch_engine::util::id::new_id;
    let id = new_id();
    assert_eq!(id.len(), 36);
    assert!(uuid::Uuid::parse_str(&id).is_ok());
}

#[test]
fn new_id_returns_unique_values() {
    use dspatch_engine::util::id::new_id;
    let ids: Vec<String> = (0..100).map(|_| new_id()).collect();
    let unique: std::collections::HashSet<&String> = ids.iter().collect();
    assert_eq!(unique.len(), 100);
}

#[test]
fn engine_config_default_values() {
    use dspatch_engine::engine::config::EngineConfig;
    let config = EngineConfig::default();
    assert_eq!(config.client_api_port, 9847);
    assert_eq!(config.db_dir, dirs::home_dir().unwrap().join(".dspatch").join("data"));
    assert_eq!(config.log_level, "info");
    assert_eq!(config.agent_server_port, 0);
    assert_eq!(config.invalidation_debounce_ms, 50);
}
