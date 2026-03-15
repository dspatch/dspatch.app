// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/engine_database.dart';
import '../../di/providers.dart';
import '../../engine_client/engine_auth.dart';
import '../../engine_client/models/auth_token.dart';
import '../../engine_client/models/db_state.dart';
import '../../models/commands/database.dart';
import '../auth/auth_controller.dart';

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
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSetup());
  }

  Future<void> _startSetup() async {
    if (_setupStarted) return;
    _setupStarted = true;

    debugPrint('[SETUP] Starting setup...');

    try {
      // If the user just logged in (scope == 'full'), reconnect the
      // engine WS with their backend token. This is done here — not in
      // the auth controller — so login is a simple POST→save→navigate
      // with no concurrent WS work racing against the router.
      debugPrint('[SETUP] Step 1: _connectEngine...');
      await _connectEngine();
      debugPrint('[SETUP] Step 1 done');

      final client = ref.read(engineClientProvider);

      // Wait for the engine to signal database readiness (handles migration).
      if (!mounted) return;
      setState(() => _status = 'Waiting for database...');
      debugPrint('[SETUP] Step 2: _waitForDatabase...');
      await _waitForDatabase();
      debugPrint('[SETUP] Step 2 done — database ready');

      // Fetch the actual DB path from the engine and open the read-only
      // Drift connection. The path varies by auth state (anonymous vs
      // per-user) and changes after migration.
      if (!mounted) return;
      setState(() => _status = 'Opening database...');
      debugPrint('[SETUP] Step 3: Fetching engine info for DB path...');
      await _openDatabase();
      debugPrint('[SETUP] Step 3 done — Drift database opened');

      // Load saved theme.
      if (!mounted) return;
      setState(() => _status = 'Loading preferences...');
      debugPrint('[SETUP] Step 4: Loading theme preference...');

      try {
        final pref = await client.sendCommand('get_preference', {'key': 'theme_mode'});
        final value = pref['value'] as String?;
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

      // Phase → ready (via AuthController — single writer). Router handles navigation.
      ref.read(authControllerProvider.notifier).setReady();
      debugPrint('[SETUP] Setup complete, phase=ready');
    } catch (e, st) {
      debugPrint('[SETUP] FATAL ERROR: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
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

      final deviceCreds = await tokenStore.loadDeviceCredentials();
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

      // Store the anonymous token so the rest of the flow can use it.
      ref.read(authTokenProvider.notifier).state = AnonymousToken(
        token: anonResult.sessionToken,
        expiresAt: anonResult.expiresAt ?? 0,
      );

      authResult = anonResult;
    }

    debugPrint('[SETUP] Got session token, connecting WS...');
    await connection.reconnect(authResult.sessionToken);

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

    // Check if the state is already set (event arrived before we got here).
    final currentState = ref.read(dbStateProvider);
    if (currentState == DbState.ready) {
      debugPrint('[SETUP] DB already ready');
      return;
    }

    if (currentState == DbState.migrationPending) {
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).setMigrating();
      await _showMigrationDialog();
    }

    // Also query the engine directly (handles case where WS event listener
    // hasn't received the event yet but the engine already has a state).
    try {
      final dbState = await client.send(GetDatabaseState());
      final state = dbState.raw['state'] as String?;
      debugPrint('[SETUP] GetDatabaseState returned: state=$state');
      if (state == 'ready') {
        ref.read(dbStateProvider.notifier).state = DbState.ready;
        return;
      } else if (state == 'migration_pending') {
        ref.read(dbStateProvider.notifier).state = DbState.migrationPending;
        if (!mounted) return;
        ref.read(authControllerProvider.notifier).setMigrating();
        await _showMigrationDialog();
      }
    } catch (e) {
      debugPrint('[SETUP] GetDatabaseState failed (waiting for events): $e');
    }

    // Wait for dbStateProvider to become ready.
    if (ref.read(dbStateProvider) == DbState.ready) return;

    final completer = Completer<void>();
    late final ProviderSubscription<DbState> sub;
    sub = ref.listenManual(dbStateProvider, (prev, next) {
      if (completer.isCompleted) return;
      debugPrint('[SETUP] dbStateProvider changed: $prev -> $next');
      if (next == DbState.ready) {
        sub.close();
        completer.complete();
      } else if (next == DbState.migrationPending && prev != DbState.migrationPending) {
        if (mounted) {
          ref.read(authControllerProvider.notifier).setMigrating();
          _showMigrationDialog();
        }
      }
    });

    return completer.future;
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
    // Error state.
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.circle_alert, size: 48, color: AppColors.destructive),
                const SizedBox(height: Spacing.md),
                Text('Setup failed', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Spacing.sm),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: Spacing.xl),
                Button(
                  label: 'Retry',
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _setupStarted = false;
                      _status = 'Initializing...';
                    });
                    _startSetup();
                  },
                ),
              ],
            ),
          ),
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
