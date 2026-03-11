// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Local device service — single local device based on hostname/platform.

use futures::stream;

use crate::domain::enums::PlatformType;
use crate::domain::models::Device;
use crate::domain::services::WatchStream;

/// Local-only device service. Returns a single device derived from
/// the current hostname and platform. Multi-device is disabled.
pub struct LocalDeviceService {
    device: Device,
}

impl LocalDeviceService {
    /// Creates a device service using the current machine's hostname and platform.
    pub fn new() -> Self {
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
            id: "local".to_string(),
            name: hostname,
            platform_type,
            is_online: true,
            last_seen_at: None,
        };

        Self { device }
    }

    /// Emits the single local device as a one-element list.
    pub fn watch_devices(&self) -> WatchStream<Vec<Device>> {
        let devices = vec![self.device.clone()];
        Box::pin(stream::once(async move { devices }))
    }

    /// Returns a reference to the current device.
    pub fn current_device(&self) -> &Device {
        &self.device
    }

    /// Returns the local device as the only "online desktop".
    pub fn online_desktops(&self) -> Vec<Device> {
        vec![self.device.clone()]
    }

    /// Always `false` — multi-device is a SaaS-only feature.
    pub fn is_multi_device_enabled(&self) -> bool {
        false
    }
}
