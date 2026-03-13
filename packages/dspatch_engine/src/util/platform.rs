// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Non-instantiable utility for querying the host operating system.
///
/// Uses compile-time `cfg` checks to determine the current platform.

pub fn is_macos() -> bool {
    cfg!(target_os = "macos")
}

pub fn is_windows() -> bool {
    cfg!(target_os = "windows")
}

pub fn is_linux() -> bool {
    cfg!(target_os = "linux")
}

pub fn is_ios() -> bool {
    cfg!(target_os = "ios")
}

pub fn is_android() -> bool {
    cfg!(target_os = "android")
}

pub fn is_desktop() -> bool {
    is_macos() || is_windows() || is_linux()
}

pub fn is_mobile() -> bool {
    is_ios() || is_android()
}

/// Returns the platform-specific Docker daemon socket path.
///
/// Used by container management to connect to the Docker engine.
pub fn docker_socket_path() -> &'static str {
    if cfg!(target_os = "macos") || cfg!(target_os = "linux") {
        "/var/run/docker.sock"
    } else if cfg!(target_os = "windows") {
        r"\\.\pipe\docker_engine"
    } else {
        ""
    }
}
