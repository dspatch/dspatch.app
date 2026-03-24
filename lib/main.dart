// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/utils/platform_info.dart';
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

/// Top-level subscriptions for engine event bridges.
/// Stored at file scope so hot restarts cancel the previous listeners
/// before creating new ones, preventing listener accumulation.
StreamSubscription? _eventSub;
StreamSubscription? _connectionSub;

/// App lifecycle listener for engine shutdown on exit.
/// Stored at file scope so hot restarts dispose the previous instance.
AppLifecycleListener? _lifecycleListener;

/// Minimum window dimensions enforced at startup.
const kMinWindowWidth = 900.0;
const kMinWindowHeight = 600.0;

/// Dev device profile for multi-device testing.
/// Each profile runs its own in-process engine on a unique port and uses
/// an isolated keyring namespace — appearing as a completely new device.
///
/// Profile 0 (default): integrated engine on port 9847.
/// Profile N (N>0): integrated engine on port 9847+N, fully usable.
///
/// To use an external engine daemon during development (enables hot reload
/// without restarting the engine), pass `--dart-define=USE_EXTERNAL_DAEMON=true`.
///
/// Usage:
///   Primary instance:  `flutter run`
///   Device 1:          `flutter run --dart-define=DEV_DEVICE_PROFILE=1`
///   Device 2:          `flutter run --dart-define=DEV_DEVICE_PROFILE=2`
///   External daemon:   `flutter run --dart-define=USE_EXTERNAL_DAEMON=true`
const kDevDeviceProfile = int.fromEnvironment('DEV_DEVICE_PROFILE', defaultValue: 0);

/// Engine port. Profile 0 uses 9847. Profile N uses 9847+N to avoid port
/// collision. Override with `--dart-define=ENGINE_PORT=...`.
const kEnginePort = int.fromEnvironment('ENGINE_PORT',
    defaultValue: 9847 + kDevDeviceProfile);

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

  if (PlatformInfo.isDesktop) {
    await _configureWindow();
  }

  // Backend URL: used by both the Flutter app and the integrated engine.
  const backendUrl = bool.fromEnvironment('dart.vm.product')
      ? 'https://backend.dspatch.dev'
      : 'http://localhost:3000';
  debugPrint('[BOOT] backendUrl=$backendUrl');

  // Start the engine in-process via FFI for all shipped builds.
  // The external daemon is only used during development with
  // USE_EXTERNAL_DAEMON=true to enable hot reload without restarting
  // the engine.
  const useExternalDaemon = bool.fromEnvironment('USE_EXTERNAL_DAEMON');
  final useIntegratedEngine = !useExternalDaemon;
  if (useIntegratedEngine) {
    // path_provider gives the OS-correct app data location:
    //   Windows: %APPDATA%/com.dspatch/dspatch_app/
    //   macOS:   ~/Library/Application Support/com.dspatch.dspatch-app/
    //   Linux:   ~/.local/share/com.dspatch/dspatch_app/
    //   iOS:     <sandbox>/Library/Application Support/
    //   Android: <sandbox>/files/
    final appSupport = await getApplicationSupportDirectory();
    final String dbDir;
    if (kDevDeviceProfile > 0) {
      dbDir = p.join(appSupport.path, 'dev$kDevDeviceProfile', 'data');
    } else {
      dbDir = p.join(appSupport.path, 'data');
    }
    debugPrint('[BOOT] Starting integrated engine on port $kEnginePort, dbDir=$dbDir');
    try {
      await NativeEngine.startAndWaitReady(
        clientApiPort: kEnginePort,
        dbDir: dbDir,
        backendUrl: backendUrl,
        timeout: const Duration(seconds: 30),
      );
      debugPrint('[BOOT] Integrated engine is ready');
    } on TimeoutException {
      debugPrint('[BOOT] WARNING: Integrated engine did not become ready within 30s');
    }
  }

  // Engine process manager — used by EngineStatusButton to start/stop
  // the external engine daemon. Not needed when running integrated.
  final EngineProcessManager? processManager;
  if (PlatformInfo.isDesktop && !useIntegratedEngine) {
    processManager = EngineProcessManager(
      engineBinaryPath: EngineProcessManager.resolveEngineBinaryPath(),
      host: _kHost,
      port: kEnginePort,
    );
  } else {
    processManager = null;
  }

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
  // When DEV_DEVICE_PROFILE is set, use an isolated keyring namespace so this
  // instance appears as a completely different device.
  final keyPrefix = kDevDeviceProfile > 0
      ? 'dspatch_dev${kDevDeviceProfile}_'
      : 'dspatch_auth_';
  if (kDevDeviceProfile > 0) {
    debugPrint('[BOOT] DEV_DEVICE_PROFILE=$kDevDeviceProfile — isolated keyring prefix: $keyPrefix');
  }
  final tokenStore = SecureTokenStore(keyPrefix: keyPrefix);
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
      engineProcessManagerProvider.overrideWithValue(processManager),
      devDeviceProfileProvider.overrideWithValue(kDevDeviceProfile),
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
  // Cancel previous subscriptions on hot restart to prevent listener accumulation.
  _eventSub?.cancel();
  _connectionSub?.cancel();
  _eventSub = client.events.listen((event) {
    if (event.name == 'database_state_changed') {
      final state = event.data['state'] as String?;
      container.read(dbStateProvider.notifier).state = DbState.fromString(state);
    }
  });

  // Bridge connection state changes to engineSessionProvider.
  _connectionSub = connection.connectionState.listen((connected) {
    container.read(engineSessionProvider.notifier).state = connected;
  });

  // Seed auth state from stored session.
  // Only full-scope tokens are restored. Partial registration tokens
  // are discarded on cold start — user restarts the registration flow.
  if (storedSession != null && storedSession.isFullyAuthenticated) {
    // Validate the stored token against the backend before trusting it.
    // This catches tokens that were revoked server-side (e.g. after a
    // password reset or session invalidation). We do this inline so the
    // app starts in the correct auth state rather than discovering the
    // revocation later during normal operation.
    //
    // A 5-second timeout allows the app to proceed offline if the backend
    // is unreachable — the token will be re-validated on the next server
    // interaction. Any non-401 failure (network error, 5xx) is treated as
    // a transient issue and the stored session is preserved.
    StoredSession? validatedSession = storedSession;
    try {
      final backendAuthForValidation = BackendAuth(baseUrl: backendUrl);
      await backendAuthForValidation
          .checkStatus(token: storedSession.backendToken)
          .timeout(const Duration(seconds: 5));
      backendAuthForValidation.dispose();
      debugPrint('[BOOT] Stored token validated against backend');
    } on BackendAuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        // Backend uses stealth 404 for rejected tokens (hides protected
        // endpoints from unauthenticated scanners), so 404 = token rejected.
        debugPrint('[BOOT] Stored token rejected (${e.statusCode}) — clearing session');
        await tokenStore.clearSession();
        validatedSession = null;
      } else {
        debugPrint('[BOOT] Token validation failed (${e.statusCode}) — proceeding offline');
      }
    } on TimeoutException {
      debugPrint('[BOOT] Token validation timed out — proceeding offline');
    } catch (e) {
      debugPrint('[BOOT] Token validation error — proceeding offline: $e');
    }

    if (validatedSession != null) {
      container.read(authTokenProvider.notifier).state = BackendToken(
        token: validatedSession.backendToken,
        expiresAt: validatedSession.expiresAt,
        scope: validatedSession.scope,
        username: validatedSession.username,
        email: validatedSession.email,
      );
      container.read(authPhaseProvider.notifier).state = AuthPhase.authenticated;
    }
  }
  // If no valid session: both providers stay at defaults
  // (unauthenticated + null token), router shows login.

  // Register shutdown handler for the integrated engine.
  // Disposes the previous listener on hot restart before creating a new one.
  _lifecycleListener?.dispose();
  _lifecycleListener = AppLifecycleListener(
    onPause: () {
      debugPrint('[LIFECYCLE] App paused — disconnecting engine connection');
      connection.disconnect();
    },
    onResume: () {
      debugPrint('[LIFECYCLE] App resumed — reconnecting engine connection');
      if (!connection.isConnected) {
        connection.connect().catchError((Object e) {
          debugPrint('[LIFECYCLE] Reconnect on resume failed: $e');
        });
      }
    },
    onDetach: useIntegratedEngine
        ? () {
            debugPrint('[SHUTDOWN] Stopping integrated engine...');
            try {
              NativeEngine.stop();
              debugPrint('[SHUTDOWN] Integrated engine stopped');
            } catch (e) {
              debugPrint('[SHUTDOWN] Error stopping integrated engine: $e');
            }
          }
        : null,
  );

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
  await windowManager.setTitle(
    kDevDeviceProfile > 0 ? '$kAppName [Device $kDevDeviceProfile]' : kAppName,
  );
}

