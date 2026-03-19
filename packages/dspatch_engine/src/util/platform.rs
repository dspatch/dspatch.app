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

/// Returns the platform-specific Docker daemon socket path, or `None` on
/// mobile platforms where Docker is unavailable.
///
/// Callers should treat `None` as "Docker not supported on this platform"
/// and refuse to create or launch local workspaces accordingly.
pub fn docker_socket_path() -> Option<&'static str> {
    #[cfg(any(target_os = "ios", target_os = "android"))]
    return None;

    #[cfg(target_os = "windows")]
    return Some(r"\\.\pipe\docker_engine");

    #[cfg(any(target_os = "macos", target_os = "linux"))]
    return Some("/var/run/docker.sock");

    #[cfg(not(any(
        target_os = "ios",
        target_os = "android",
        target_os = "windows",
        target_os = "macos",
        target_os = "linux",
    )))]
    return None;
}
