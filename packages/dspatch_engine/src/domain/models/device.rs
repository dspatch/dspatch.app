// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

use crate::domain::enums::PlatformType;

/// A registered device that can receive push notifications and sync data.
///
/// Tracked for multi-device sync. [`is_online`] and [`last_seen_at`] reflect
/// the device's last known connectivity state.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct Device {
    pub id: String,
    pub name: String,
    pub platform_type: PlatformType,
    #[serde(default)]
    pub is_online: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_seen_at: Option<NaiveDateTime>,
}
