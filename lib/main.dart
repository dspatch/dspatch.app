// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'di/providers.dart';
import 'shared/widgets/error_boundary.dart';

/// Human-readable application name shown in the title bar and about dialog.
const kAppName = 'd:spatch';

/// Minimum window dimensions enforced at startup.
const kMinWindowWidth = 900.0;
const kMinWindowHeight = 600.0;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureWindow();

  // Initialize flutter_rust_bridge runtime.
  await RustLib.init();

  final sdk = RustSdk.withConfig(serverPort: 0, assetsDir: 'assets');
  await sdk.initialize();

  final container = ProviderContainer(
    overrides: [
      sdkProvider.overrideWithValue(sdk),
      themeModeProvider.overrideWith((_) => ThemeMode.system),
      dbHealthStatusProvider.overrideWith((_) => null),
    ],
    observers: [AppProviderObserver()],
  );

  debugPrint('[BOOT] SDK initialized, running app...');
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DspatchApp(),
    ),
  );
}

Future<void> _configureWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(
    const Size(kMinWindowWidth, kMinWindowHeight),
  );
  await windowManager.setTitle(kAppName);
}
