// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use crate::domain::models::Device;

use super::WatchStream;

/// Manages device registration and multi-device awareness.
///
/// In local mode, there is a single device and multi-device is disabled.
/// In SaaS mode, this would track paired devices and their online status.
pub trait DeviceService: Send + Sync {
    /// Watches all registered devices.
    fn watch_devices(&self) -> WatchStream<Vec<Device>>;

    /// The current device running this app instance.
    fn current_device(&self) -> &Device;

    /// Desktop devices currently online (for session targeting).
    fn online_desktops(&self) -> Vec<Device>;

    /// Whether multi-device features are available (SaaS only).
    fn is_multi_device_enabled(&self) -> bool;
}
