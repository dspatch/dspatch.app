// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local device service — single local device based on hostname/platform.

use std::sync::RwLock;

use crate::domain::enums::PlatformType;
use crate::domain::models::Device;

/// Local device service. Returns a single device derived from
/// the current hostname and platform. Supports server-assigned device IDs
/// for multi-device sync.
///
/// Uses interior mutability (`RwLock`) so `set_device_id` works through `Arc`.
pub struct LocalDeviceService {
    device: RwLock<Device>,
}

impl LocalDeviceService {
    /// Creates a device service using the current machine's hostname and platform.
    /// Device ID defaults to "local" until set via `with_device_id`.
    pub fn new() -> Self {
        Self::build_with_id("local".to_string())
    }

    /// Creates a device service with a server-assigned device ID.
    /// Used after device registration when the backend assigns a UUID.
    pub fn with_device_id(device_id: &str) -> Self {
        Self::build_with_id(device_id.to_string())
    }

    fn build_with_id(id: String) -> Self {
        let hostname = hostname::get()
            .ok()
            .and_then(|h| h.into_string().ok())
            .unwrap_or_else(|| "local-device".to_string());

        let platform_type = if cfg!(target_os = "windows") {
            PlatformType::Windows
        } else if cfg!(target_os = "macos") {
            PlatformType::Macos
        } else if cfg!(target_os = "linux") {
            PlatformType::Linux
        } else if cfg!(target_os = "ios") {
            PlatformType::Ios
        } else if cfg!(target_os = "android") {
            PlatformType::Android
        } else {
            PlatformType::Linux
        };

        let device = Device {
            id,
            name: hostname,
            platform_type,
            is_online: true,
            last_seen_at: None,
        };

        Self { device: RwLock::new(device) }
    }

    /// Sets the device ID. Called when the device registers with the backend.
    /// Thread-safe via interior mutability.
    pub fn set_device_id(&self, device_id: &str) {
        self.device.write().unwrap_or_else(|e| e.into_inner()).id = device_id.to_string();
    }

    /// Returns `true` if multi-device sync is active (device has a server-assigned ID).
    pub fn is_multi_device_enabled(&self) -> bool {
        self.device.read().unwrap_or_else(|e| e.into_inner()).id != "local"
    }

    /// Returns a clone of the current device.
    pub fn current_device(&self) -> Device {
        self.device.read().unwrap_or_else(|e| e.into_inner()).clone()
    }

    /// Returns the local device as the only "online desktop".
    pub fn online_desktops(&self) -> Vec<Device> {
        vec![self.device.read().unwrap_or_else(|e| e.into_inner()).clone()]
    }
}
