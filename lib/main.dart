// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'database/engine_database.dart';
import 'database/invalidation_bridge.dart';
import 'di/providers.dart';
import 'engine_client/engine_client_lib.dart';
import 'engine_client/native_engine.dart';
import 'shared/widgets/error_boundary.dart';

/// Human-readable application name shown in the title bar and about dialog.
const kAppName = 'd:spatch';

/// Minimum window dimensions enforced at startup.
const kMinWindowWidth = 900.0;
const kMinWindowHeight = 600.0;

/// Default engine port. Can be overridden at compile time.
const kEnginePort = int.fromEnvironment('ENGINE_PORT', defaultValue: 9847);

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureWindow();

  // On mobile, start the engine in-process via FFI before connecting.
  if (Platform.isAndroid || Platform.isIOS) {
    final dbDir = p.join(
      Platform.environment['HOME'] ?? '.',
      '.dspatch',
      'data',
    );
    NativeEngine.start(clientApiPort: kEnginePort, dbDir: dbDir);
  }

  // Step 1: Bootstrap the engine (spawn if needed, authenticate, connect WS).
  final config = EngineBootstrapConfig(port: kEnginePort);
  final bootstrap = EngineBootstrap(config);
  final result = await bootstrap.initialize();

  debugPrint('[BOOT] Engine connected (auth: ${result.authResult.authMode})');

  // Step 2: Open the read-only Drift database.
  final dbPath = _resolveDbPath();
  final db = EngineDatabase(dbPath);

  // Step 3: Wire invalidation bridge (engine WS -> Drift watchers).
  final invalidationBridge = InvalidationBridge(
    invalidationStream: result.client.invalidations,
    onInvalidation: db.handleInvalidation,
  );
  invalidationBridge.start();

  // Step 4: Create the provider container with new providers.
  final container = ProviderContainer(
    overrides: [
      engineClientProvider.overrideWithValue(result.client),
      engineDatabaseProvider.overrideWithValue(db),
      themeModeProvider.overrideWith((_) => ThemeMode.system),
    ],
    observers: [AppProviderObserver()],
  );

  debugPrint('[BOOT] Providers initialized, running app...');
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

/// Resolves the path to the engine's SQLite database file.
///
/// Convention: `~/.dspatch/data/dspatch.db` on all platforms.
/// The engine creates this file on first run.
String _resolveDbPath() {
  final home = Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      '.';
  return p.join(home, '.dspatch', 'data', 'dspatch.db');
}
