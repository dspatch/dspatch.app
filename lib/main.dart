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
import 'engine_client/models/auth_phase.dart';
import 'engine_client/models/auth_token.dart';
import 'engine_client/models/db_state.dart';
import 'engine_client/native_engine.dart';
import 'engine_client/secure_token_store.dart';
import 'shared/widgets/error_boundary.dart';

/// Human-readable application name shown in the title bar and about dialog.
const kAppName = 'd:spatch';

/// Minimum window dimensions enforced at startup.
const kMinWindowWidth = 900.0;
const kMinWindowHeight = 600.0;

/// Default engine port. Can be overridden at compile time.
const kEnginePort = int.fromEnvironment('ENGINE_PORT', defaultValue: 9847);

const _kHost = '127.0.0.1';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers — catch-all for uncaught Flutter and async errors.
  FlutterError.onError = (details) {
    debugPrint('[FLUTTER_ERROR] ${details.exception}');
    debugPrint('[FLUTTER_ERROR] ${details.stack}');
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('[UNCAUGHT] $error');
    debugPrint('[UNCAUGHT] $stack');
    return true;
  };

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

  // Step 1: Ensure the engine process is running (spawn if needed).
  // NO authentication, NO WebSocket — just verify the process is alive.
  final processManager = EngineProcessManager(
    engineBinaryPath: EngineProcessManager.resolveEngineBinaryPath(),
    host: _kHost,
    port: kEnginePort,
    engineExternal: const bool.fromEnvironment('ENGINE_EXTERNAL'),
  );
  final healthStatus = await processManager.ensureRunning();
  debugPrint('[BOOT] Engine process running');

  // Derive backend URL from the engine health response.
  final backendUrl =
      healthStatus.backendUrl ??
      (const bool.fromEnvironment('dart.vm.product')
          ? 'https://backend.dspatch.dev'
          : 'http://localhost:3000');
  debugPrint('[BOOT] backendUrl=$backendUrl');

  // Step 2: Create engine objects WITHOUT connecting.
  // SetupScreen is the single gateway that establishes the WS connection
  // (anonymous or authenticated). Until then, these are inert placeholders.
  final engineAuth = EngineAuth(host: _kHost, port: kEnginePort);
  final connection = EngineConnection(
    host: _kHost,
    port: kEnginePort,
    // Empty token — SetupScreen will call reconnect() with a real one.
    token: '',
  );
  final client = EngineClient(connection);

  // Step 3: Load stored session so we can seed authPhaseProvider + authTokenProvider.
  final tokenStore = SecureTokenStore();
  final storedSession = await tokenStore.loadSession();

  // Step 4: Create a placeholder Drift database.
  // The real database path is unknown until the engine signals readiness
  // (it varies by auth state: anonymous vs per-user). SetupScreen will
  // fetch the actual path from /engine-info and swap the provider.
  final db = EngineDatabase.placeholder();

  // Step 5: Create the provider container BEFORE wiring the invalidation
  // bridge, so the bridge can read the current DB dynamically.
  final container = ProviderContainer(
    overrides: [
      engineClientProvider.overrideWithValue(client),
      engineDatabaseProvider.overrideWith((_) => db),
      engineAuthProvider.overrideWithValue(engineAuth),
      engineConnectionProvider.overrideWithValue(connection),
      backendAuthProvider.overrideWithValue(BackendAuth(baseUrl: backendUrl)),
      secureTokenStoreProvider.overrideWithValue(tokenStore),
      themeModeProvider.overrideWith((_) => ThemeMode.system),
    ],
    observers: [AppProviderObserver()],
  );

  // Step 6: Wire invalidation bridge (engine WS -> Drift watchers).
  // Uses container.read so invalidations always target the current DB,
  // even after SetupScreen swaps it to the real database path.
  final invalidationBridge = InvalidationBridge(
    invalidationStream: client.invalidations,
    onInvalidation: (tables) {
      container.read(engineDatabaseProvider).handleInvalidation(tables);
    },
  );
  invalidationBridge.start();

  // Bridge engine events to StateProviders for race-condition-free access.
  client.events.listen((event) {
    if (event.name == 'database_state_changed') {
      final state = event.data['state'] as String?;
      container.read(dbStateProvider.notifier).state = DbState.fromString(state);
    }
  });

  // Bridge connection state changes to engineSessionProvider.
  connection.connectionState.listen((connected) {
    container.read(engineSessionProvider.notifier).state = connected;
  });

  // Seed auth state from stored session.
  // Only full-scope tokens are restored. Partial registration tokens
  // are discarded on cold start — user restarts the registration flow.
  if (storedSession != null && storedSession.isFullyAuthenticated) {
    container.read(authTokenProvider.notifier).state = BackendToken(
      token: storedSession.backendToken,
      expiresAt: storedSession.expiresAt,
      scope: storedSession.scope,
      username: storedSession.username,
      email: storedSession.email,
    );
    container.read(authPhaseProvider.notifier).state = AuthPhase.authenticated;
  }
  // If no valid session: both providers stay at defaults
  // (unauthenticated + null token), router shows login.

  debugPrint('[BOOT] Providers initialized, running app...');
  runApp(
    UncontrolledProviderScope(container: container, child: const DspatchApp()),
  );
}

Future<void> _configureWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(
    const Size(kMinWindowWidth, kMinWindowHeight),
  );
  await windowManager.setTitle(kAppName);
}

