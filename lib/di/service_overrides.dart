// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns Riverpod overrides for SaaS mode.
///
/// When d:spatch connects to a remote server, replace local service
/// implementations with their SaaS counterparts here:
///
/// ```dart
/// List<Override> saasOverrides(ServerConfig config) => [
///   authServiceProvider.overrideWithValue(SaasAuthService(config)),
///   syncServiceProvider.overrideWithValue(SaasSyncService(config)),
///   connectivityServiceProvider.overrideWithValue(SaasConnectivityService(config)),
///   deviceServiceProvider.overrideWithValue(SaasDeviceService(config)),
/// ];
/// ```
///
/// Then pass them to `ProviderScope(overrides: [...saasOverrides(config)])`.
List<Override> saasOverrides() => [];
