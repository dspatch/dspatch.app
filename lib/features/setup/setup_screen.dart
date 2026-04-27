// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/display_error.dart';
import '../../core/utils/platform_info.dart';
import '../../database/engine_database.dart';
import '../../di/providers.dart';
import '../../engine_client/backend_auth.dart';
import '../../engine_client/engine_auth.dart';
import '../../engine_client/models/auth_token.dart';
import '../../engine_client/models/db_state.dart';
import '../../models/commands/commands.dart';
import '../auth/auth_controller.dart';
import '../auth/widgets/engine_status_button.dart';

/// Gateway screen shown after authentication.
///
/// With the engine architecture, the engine process manages DB initialization
/// and migration. This screen now:
/// 1. Waits for the engine to signal database readiness.
/// 2. If migration pending, prompts the user.
/// 3. Loads saved theme preference.
/// 4. Redirects to /workspaces when ready.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _setupStarted = false;
  String? _error;
  Object? _errorObject;
  String _status = 'Initializing...';
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSetup());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSetup() async {
    if (_setupStarted) return;
    _setupStarted = true;

    debugPrint('[SETUP] Starting setup...');

    try {
      // ── Step 0: Auth verification (runs ONCE, never retried) ──────
      final token = ref.read(authTokenProvider);
      if (token is BackendToken) {
        if (!mounted) return;
        setState(() => _status = 'Verifying authentication...');
        debugPrint('[SETUP] Checking auth status with backend...');

        try {
          final backend = ref.read(backendAuthProvider);
          final status = await backend.checkStatus(token: token.token);
          final backendScope = status['scope'] as String?;
          debugPrint('[SETUP] Backend says scope=$backendScope');

          if (backendScope != 'full') {
            debugPrint('[SETUP] Not fully authenticated (scope=$backendScope), logging out');
            if (!mounted) return;
            await ref.read(authControllerProvider.notifier).logout();
            return;
          }
        } on BackendAuthException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 404) {
            // Backend uses stealth 404 for rejected tokens. Clear session
            // so the app falls back to anonymous auth instead of failing
            // during engine connect.
            debugPrint('[SETUP] Backend rejected token (${e.statusCode}), logging out');
            if (!mounted) return;
            await ref.read(authControllerProvider.notifier).logout();
            return;
          }
          // Other errors (5xx, network) — proceed offline.
          debugPrint('[SETUP] Backend status check failed (proceeding): $e');
        } catch (e) {
          // Backend unreachable — proceed with local state for offline resilience.
          debugPrint('[SETUP] Backend status check failed (proceeding): $e');
        }
      }

      // ── Step 1: Connect to engine (retries silently until success) ─
      debugPrint('[SETUP] Step 1: _connectEngine...');
      if (!mounted) return;
      setState(() => _status = 'Waiting for engine...');
      await _connectEngineWithRetry();
      debugPrint('[SETUP] Step 1 done');

      final client = ref.read(engineClientProvider);

      // ── Step 2: Wait for database readiness ───────────────────────
      if (!mounted) return;
      setState(() => _status = 'Waiting for database...');
      debugPrint('[SETUP] Step 2: _waitForDatabase...');
      await _waitForDatabase();
      debugPrint('[SETUP] Step 2 done — database ready');

      // ── Step 3: Open read-only Drift database ─────────────────────
      if (!mounted) return;
      setState(() => _status = 'Opening database...');
      debugPrint('[SETUP] Step 3: Fetching engine info for DB path...');
      await _openDatabase();
      debugPrint('[SETUP] Step 3 done — Drift database opened');

      // ── Step 4: Load preferences ──────────────────────────────────
      if (!mounted) return;
      setState(() => _status = 'Loading preferences...');

      try {
        final pref = await client.send(GetPreference(key: 'theme_mode'));
        final value = pref.value;
        debugPrint('[SETUP] Theme preference: $value');
        if (!mounted) return;
        if (value != null) {
          final mode = ThemeMode.values.firstWhere(
            (m) => m.name == value,
            orElse: () => ThemeMode.system,
          );
          ref.read(themeModeProvider.notifier).state = mode;
        }
      } catch (e) {
        debugPrint('[SETUP] Theme preference not set or failed: $e');
      }

      // Start proactive token refresh if authenticated (not anonymous).
      final currentToken = ref.read(authTokenProvider);
      if (currentToken is BackendToken) {
        ref.read(authControllerProvider.notifier).startRefreshTimer();

        // TODO(push): Register FCM/APNs push token with backend.
        // On Android, get the FCM token via firebase_messaging.
        // On iOS, get the APNs token via firebase_messaging or native APNs.
        // Then POST to /api/push/subscribe with { platform: "fcm"|"apns", token: "<token>" }.
        // This enables server-side push notifications for sync_ready events
        // (wakes the app for background sync) and other domain events.
        // Requires adding firebase_messaging dependency and FCM/APNs configuration.
        debugPrint('[SETUP] Push token registration stub — '
            'would send token to backend /api/push/subscribe');
      }

      // Phase → ready. Router handles navigation.
      ref.read(authControllerProvider.notifier).setReady();
      debugPrint('[SETUP] Setup complete, phase=ready');
    } catch (e, st) {
      debugPrint('[SETUP] FATAL ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _errorObject = e;
      });
    }
  }

  /// Retries engine connection in a background loop until it succeeds.
  ///
  /// Auth verification has already completed — this only retries the
  /// engine WS handshake. Shows "Waiting for engine..." on the UI and
  /// polls every 3 seconds without re-running auth checks.
  Future<void> _connectEngineWithRetry() async {
    while (true) {
      if (!mounted) return;
      try {
        await _connectEngine();
        // Success — clear any previous engine-unreachable state.
        if (mounted) {
          setState(() {
            _error = null;
            _errorObject = null;
          });
        }
        return;
      } catch (e) {
        if (!isEngineUnreachableError(e)) rethrow; // Non-connection error → fatal

        debugPrint('[SETUP] Engine not reachable, retrying in 3s...');
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _errorObject = e;
        });

        // Wait 3 seconds before retrying (cancellable via dispose).
        final completer = Completer<void>();
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(seconds: 3), () {
          if (!completer.isCompleted) completer.complete();
        });
        await completer.future;
      }
    }
  }

  /// Establishes the engine WebSocket connection.
  ///
  /// This is the SINGLE place the engine WS is connected. main.dart creates
  /// the EngineConnection/EngineClient objects but does NOT connect them.
  ///
  /// - Authenticated user (BackendToken with scope == 'full'):
  ///   call engineAuth.connect(backendToken) → get session token → connect WS.
  /// - Anonymous / no stored session:
  ///   call engineAuth.authenticateAnonymous() → get session token → connect WS.
  Future<void> _connectEngine() async {
    // Capture the root ProviderContainer synchronously (before any await)
    // so the token-refresh callback can use it after SetupScreen is disposed.
    final container = ProviderScope.containerOf(context);
    final connection = ref.read(engineConnectionProvider);

    if (connection.isConnected) {
      debugPrint('[SETUP] Engine already connected, skipping');
      return;
    }

    setState(() => _status = 'Connecting to engine...');

    final engineAuth = ref.read(engineAuthProvider);
    final token = ref.read(authTokenProvider);
    final tokenStore = ref.read(secureTokenStoreProvider);

    final AuthResult authResult;

    if (token is BackendToken) {
      // Authenticated — connect with backend token + device credentials.
      debugPrint('[SETUP] Connecting engine (authenticated, user=${token.username})...');

      final deviceCreds = await tokenStore.loadDeviceCredentials(token.username);
      authResult = await engineAuth.connect(
        backendToken: token.token,
        deviceId: deviceCreds?.deviceId,
        identityKeySeed: deviceCreds?.identityKeyHex,
      );

      // Persist session token for restart persistence.
      await tokenStore.saveSession(
        backendToken: token.token,
        expiresAt: token.expiresAt,
        scope: token.scope,
        username: token.username,
        email: token.email,
        sessionToken: authResult.sessionToken,
      );
    } else {
      // Anonymous — get anonymous token, then connect.
      debugPrint('[SETUP] Connecting engine (anonymous)...');
      final anonResult = await engineAuth.authenticateAnonymous();

      // Store the anonymous token via AuthController (single-writer invariant).
      ref.read(authControllerProvider.notifier).setAnonymousToken(
        token: anonResult.sessionToken,
        expiresAt: anonResult.expiresAt ?? 0,
      );

      authResult = anonResult;
    }

    debugPrint('[SETUP] Got session token, connecting WS...');
    await connection.reconnect(authResult.sessionToken);

    // Install token refresh callback for auto-reconnect.
    // Uses ProviderContainer (captured above, before any await) so the
    // callback remains valid after SetupScreen is disposed —
    // EngineConnection is a long-lived singleton that outlives this widget.
    connection.onTokenRefresh = () async {
      final currentToken = container.read(authTokenProvider);

      if (currentToken == null) {
        // No credentials at all — force logout.
        debugPrint('[TOKEN_REFRESH] No auth token, logging out');
        await container.read(authControllerProvider.notifier).logout();
        return null;
      }

      if (currentToken is BackendToken) {
        // Check if the backend JWT has expired.
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (nowSec >= currentToken.expiresAt) {
          debugPrint('[TOKEN_REFRESH] Backend token expired, logging out');
          await container.read(authControllerProvider.notifier).logout();
          return null;
        }

        // Re-authenticate with the engine using the still-valid backend token.
        // This handles engine restarts (in-memory session store wiped).
        try {
          final deviceCreds = await tokenStore.loadDeviceCredentials(
            currentToken.username,
          );
          final result = await engineAuth.connect(
            backendToken: currentToken.token,
            deviceId: deviceCreds?.deviceId,
            identityKeySeed: deviceCreds?.identityKeyHex,
          );

          // Persist the new session token.
          await tokenStore.saveSession(
            backendToken: currentToken.token,
            expiresAt: currentToken.expiresAt,
            scope: currentToken.scope,
            username: currentToken.username,
            email: currentToken.email,
            sessionToken: result.sessionToken,
          );

          debugPrint('[TOKEN_REFRESH] Re-authenticated (backend), new session token');
          return result.sessionToken;
        } on AuthException catch (e) {
          if (e.statusCode != null) {
            // Engine responded with an error (e.g., 401/403) — definitive
            // rejection. Reset to setup so the full connection flow reruns.
            debugPrint('[TOKEN_REFRESH] Engine rejected auth (${e.statusCode}), resetting to setup');
            container.read(authControllerProvider.notifier).resetForReSetup();
            return null;
          }
          // No status code means the engine is unreachable (connection error).
          // Rethrow so the reconnect loop retries with backoff.
          debugPrint('[TOKEN_REFRESH] Engine unreachable, will retry: $e');
          rethrow;
        }
      }

      if (currentToken is AnonymousToken) {
        try {
          final result = await engineAuth.authenticateAnonymous();
          debugPrint('[TOKEN_REFRESH] Re-authenticated (anonymous), new session token');
          return result.sessionToken;
        } on AuthException catch (e) {
          if (e.statusCode != null) {
            debugPrint('[TOKEN_REFRESH] Engine rejected anonymous auth (${e.statusCode}), resetting to setup');
            container.read(authControllerProvider.notifier).resetForReSetup();
            return null;
          }
          debugPrint('[TOKEN_REFRESH] Engine unreachable (anonymous), will retry: $e');
          rethrow;
        }
      }

      return null;
    };

    // Update phase to connecting (via AuthController — single writer).
    ref.read(authControllerProvider.notifier).setConnecting();
    debugPrint('[SETUP] Engine WS connected (mode=${authResult.authMode})');
  }

  /// Waits for the engine to signal database readiness via dbStateProvider.
  /// Handles `migration_pending` by prompting the user, then continues
  /// waiting for `ready`. Never proceeds without confirmation.
  Future<void> _waitForDatabase() async {
    final client = ref.read(engineClientProvider);
    debugPrint('[SETUP] _waitForDatabase: checking current state...');

    // Query the engine for the authoritative database state. This handles
    // the common case where the WS event arrived before we subscribed (the
    // MigrationPending event is sent during /auth/connect, before the WS
    // handler's select loop is running).
    Future<DbState> queryEngineState() async {
      final dbResponse = await client.send(GetDatabaseState());
      final stateStr = dbResponse.raw['state'] as String?;
      final parsed = DbState.fromString(stateStr);
      debugPrint('[SETUP] GetDatabaseState returned: state=$stateStr');
      ref.read(authControllerProvider.notifier).setDbState(parsed);
      return parsed;
    }

    // Poll: check provider first (fast), then query the engine (authoritative).
    // Loop until ready. Each iteration handles one state transition.
    while (true) {
      if (!mounted) return;

      // Always query the engine for ground truth. The cached dbStateProvider
      // can be stale (e.g. migration just completed but the WS invalidation
      // event hasn't arrived yet).
      final state = await queryEngineState();

      if (state == DbState.ready) {
        debugPrint('[SETUP] DB ready');
        return;
      }

      if (state == DbState.migrationPending) {
        if (!mounted) return;
        ref.read(authControllerProvider.notifier).setMigrating();
        await _showMigrationDialog();
        // Migration command sent — re-query to confirm it's ready.
        continue;
      }

      // State is unknown/closed — wait for the next dbStateProvider change,
      // then loop again.
      debugPrint('[SETUP] DB state is $state, waiting for change...');
      final completer = Completer<void>();
      late final ProviderSubscription<DbState> sub;
      sub = ref.listenManual(dbStateProvider, (prev, next) {
        if (completer.isCompleted) return;
        debugPrint('[SETUP] dbStateProvider changed: $prev -> $next');
        sub.close();
        completer.complete();
      });

      // Also poll the engine periodically in case the WS event is lost.
      final timer = Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          sub.close();
          completer.complete();
        }
      });

      await completer.future;
      timer.cancel();
    }
  }

  /// Fetches the current DB path from `/engine-info` and swaps the Drift
  /// database provider to point at the correct file.
  ///
  /// Must be called AFTER `_waitForDatabase()` completes (engine DB is ready).
  Future<void> _openDatabase() async {
    final engineAuth = ref.read(engineAuthProvider);
    final info = await engineAuth.fetchEngineInfo();
    debugPrint('[SETUP] Engine DB path: ${info.dbPath}');

    // Close the placeholder and open the real database.
    final oldDb = ref.read(engineDatabaseProvider);
    await oldDb.close();

    final newDb = EngineDatabase(info.dbPath);
    if (!mounted) return;
    ref.read(engineDatabaseProvider.notifier).state = newDb;

    // Mark the database as ready so the router allows navigation.
    ref.read(databaseReadyProvider.notifier).state = true;
  }

  /// Shows a dialog asking the user whether to migrate their anonymous data.
  /// Sends the command but does NOT signal completion — the caller continues
  /// waiting for the engine's `database_state_changed` → `ready` event.
  Future<void> _showMigrationDialog() async {
    final client = ref.read(engineClientProvider);

    final migrate = await DspatchAlertDialog.show<bool>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AlertDialogHeader(children: [
            AlertDialogTitle(text: 'Migrate local data?'),
            AlertDialogDescription(
              text: 'You have data from a previous anonymous session. '
                  'Would you like to migrate it to your account?',
            ),
          ]),
          AlertDialogFooter(children: [
            Button(
              label: 'Start fresh',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            Button(
              label: 'Migrate data',
              variant: ButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ]),
        ],
      ),
    );

    if (!mounted) return;
    setState(() => _status = 'Setting up database...');

    if (migrate == true) {
      debugPrint('[SETUP] User chose to migrate');
      await client.send(PerformMigration());
    } else {
      debugPrint('[SETUP] User chose to skip migration');
      await client.send(SkipMigration());
    }
    // Do NOT return — the engine will emit 'ready' when done, and
    // _waitForDatabase's provider listener will complete the completer.
  }

  @override
  Widget build(BuildContext context) {
    final isUnreachable =
        _errorObject != null && isEngineUnreachableError(_errorObject!);

    // Engine unreachable — show waiting state with auto-retry and engine button.
    if (isUnreachable) {
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.unplug,
                    size: 32,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: Spacing.md),
                  const Text(
                    'Engine is not reachable',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  const Text(
                    'Retrying automatically...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
            if (PlatformInfo.isDesktop)
              const Positioned(
                left: Spacing.md,
                bottom: Spacing.md,
                child: EngineStatusButton(),
              ),
          ],
        ),
      );
    }

    // Non-connection error — show error with manual retry.
    if (_error != null) {
      return Scaffold(
        body: Stack(
          children: [
            ErrorStateView(
              message: 'Setup failed: ${displayError(_errorObject!)}',
              onRetry: () {
                _retryTimer?.cancel();
                setState(() {
                  _error = null;
                  _errorObject = null;
                  _setupStarted = false;
                  _status = 'Initializing...';
                });
                _startSetup();
              },
            ),
            if (PlatformInfo.isDesktop)
              const Positioned(
                left: Spacing.md,
                bottom: Spacing.md,
                child: EngineStatusButton(),
              ),
          ],
        ),
      );
    }

    // Loading state.
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Spacing.md),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
