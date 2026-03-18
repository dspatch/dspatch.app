// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use dspatch_engine::services::LocalDeviceService;

#[test]
fn device_service_accepts_server_assigned_id() {
    let service = LocalDeviceService::with_device_id("019471a2-3b4c-7d8e-9f01-234567890abc");
    assert_eq!(service.current_device().id, "019471a2-3b4c-7d8e-9f01-234567890abc");
    assert!(service.is_multi_device_enabled());
}

#[test]
fn device_service_defaults_to_local_when_no_id() {
    let service = LocalDeviceService::new();
    assert_eq!(service.current_device().id, "local");
    assert!(!service.is_multi_device_enabled());
}

#[test]
fn set_device_id_transitions_from_local_to_multi_device() {
    let mut service = LocalDeviceService::new();
    assert!(!service.is_multi_device_enabled());
    service.set_device_id("019471a2-3b4c-7d8e-9f01-234567890abc");
    assert_eq!(service.current_device().id, "019471a2-3b4c-7d8e-9f01-234567890abc");
    assert!(service.is_multi_device_enabled());
}
