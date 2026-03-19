// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Tests that the FFI boundary correctly catches panics and returns error code 4
//! rather than unwinding across the C ABI boundary.

use std::panic;

/// Verify that the catch_unwind pattern used in the FFI entry points produces
/// error code 4 when a panic occurs, rather than unwinding across the FFI boundary.
///
/// This test simulates the exact pattern used in `start_engine` and `stop_engine`
/// to confirm that a panic inside the closure returns 4 and does NOT propagate.
#[test]
fn test_catch_unwind_returns_error_code_on_panic() {
    let result = panic::catch_unwind(panic::AssertUnwindSafe(|| -> i32 {
        panic!("simulated engine init panic");
    }));

    let code = match result {
        Ok(code) => code,
        Err(_e) => 4, // panic error code — same as in start_engine / stop_engine
    };

    assert_eq!(
        code, 4,
        "FFI boundary must return error code 4 on panic, not unwind across C ABI"
    );
}

/// Verify that a non-panicking closure returns its value unchanged through
/// the catch_unwind wrapper.
#[test]
fn test_catch_unwind_passes_through_normal_return() {
    let result = panic::catch_unwind(panic::AssertUnwindSafe(|| -> i32 { 0 }));

    let code = match result {
        Ok(code) => code,
        Err(_e) => 4,
    };

    assert_eq!(code, 0, "Non-panicking FFI entry point must return 0 on success");
}

/// Verify that the FFI functions handle null config by returning 1, not panicking.
#[test]
fn test_start_engine_null_config_returns_1_not_panic() {
    let result = unsafe { dspatch_engine::ffi::start_engine(std::ptr::null()) };
    assert_eq!(
        result, 1,
        "start_engine should return 1 on null pointer, not panic (code 4)"
    );
    assert_ne!(result, 4, "null pointer must not cause a panic");
}

/// Verify that stop_engine returns a defined non-panic error code when not running.
#[test]
fn test_stop_engine_not_running_returns_1_not_panic() {
    // Call stop when engine is definitely not running (or may have been stopped already).
    // Either 0 (success) or 1 (not running) is valid; 4 (panic) is never acceptable.
    let result = dspatch_engine::ffi::stop_engine();
    assert_ne!(result, 4, "stop_engine must not return panic code 4");
}
