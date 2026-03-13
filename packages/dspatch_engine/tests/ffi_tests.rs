// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::ffi::CString;

use dspatch_engine::ffi;

#[test]
fn stop_engine_returns_nonzero_when_not_running() {
    let result = ffi::stop_engine();
    assert_ne!(
        result, 0,
        "stop_engine should return nonzero when engine is not running"
    );
}

#[test]
fn start_engine_returns_nonzero_on_null_pointer() {
    let result = unsafe { ffi::start_engine(std::ptr::null()) };
    assert_eq!(result, 1, "start_engine should return 1 on null pointer");
}

#[test]
fn start_engine_returns_nonzero_on_invalid_json() {
    let bad_json = CString::new("not valid json {{{").unwrap();
    let result = unsafe { ffi::start_engine(bad_json.as_ptr()) };
    assert_eq!(result, 1, "start_engine should return 1 on invalid JSON");
}

#[test]
fn start_and_stop_engine_round_trip() {
    let tmp = tempfile::tempdir().unwrap();
    let config = serde_json::json!({
        "client_api_port": 0,
        "db_dir": tmp.path().to_str().unwrap(),
        "log_level": "error",
        "agent_server_port": 0,
        "invalidation_debounce_ms": 50
    });
    let config_str = CString::new(config.to_string()).unwrap();
    let result = unsafe { ffi::start_engine(config_str.as_ptr()) };
    assert_eq!(result, 0, "start_engine should return 0 on success");

    // Give server time to bind.
    std::thread::sleep(std::time::Duration::from_millis(200));

    let stop_result = ffi::stop_engine();
    assert_eq!(stop_result, 0, "stop_engine should return 0 on success");
}
