// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io' show Platform;

/// Non-instantiable utility for querying the host operating system.
///
/// Wraps [Platform] checks behind a single API and provides derived
/// helpers like [isDesktop] and [dockerSocketPath].
class PlatformInfo {
  PlatformInfo._();

  static bool get isDesktop => isMacOS || isWindows || isLinux;
  static bool get isMobile => isIOS || isAndroid;

  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Platform identifier sent to backend during device registration.
  static String get platformId {
    if (isWindows) return 'windows';
    if (isMacOS) return 'macos';
    if (isLinux) return 'linux';
    if (isIOS) return 'ios';
    if (isAndroid) return 'android';
    return 'unknown';
  }

  /// Human-readable platform name for UI display.
  static String get platformName {
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    return 'Unknown';
  }

  /// Device type category: 'mobile' or 'desktop'.
  static String get deviceType => isMobile ? 'mobile' : 'desktop';

  /// Returns the platform-specific Docker daemon socket path, or null on
  /// mobile platforms where Docker is unavailable.
  ///
  /// Callers should treat a null return as "Docker not supported on this
  /// platform" and suppress any Docker-related UI or logic accordingly.
  static String? get dockerSocketPath {
    if (isMobile) return null;
    if (isWindows) return r'\\.\pipe\docker_engine';
    if (isMacOS || isLinux) return '/var/run/docker.sock';
    return null;
  }
}
