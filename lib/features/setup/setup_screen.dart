// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/engine_database.dart';
import '../../di/providers.dart';
import '../../engine_client/engine_auth.dart';
import '../../engine_client/protocol/protocol.dart';
import '../../models/commands/database.dart';

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

      debugPrint('[SETUP] Setup complete, navigating to /workspaces');
      if (mounted) context.go('/workspaces');
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
  /// - Authenticated user (backendAuth.scope == 'full'):
  ///   call engineAuth.connect(backendToken) → get session token → connect WS.
  /// - Anonymous / no stored session:
  ///   call engineAuth.authenticateAnonymous() → get session token → connect WS.
  Future<void> _connectEngine() async {
    final connection = ref.read(engineConnectionProvider);

    // If already connected (e.g. navigated back to /setup), skip.
    if (connection.isConnected) {
      debugPrint('[SETUP] Engine already connected, skipping');
      return;
    }

    setState(() => _status = 'Connecting to engine...');

    final engineAuth = ref.read(engineAuthProvider);
    final backendAuth = ref.read(backendAuthStateProvider);
    final tokenStore = ref.read(secureTokenStoreProvider);

    final AuthResult authResult;

    if (backendAuth != null && backendAuth.isFullyAuthenticated) {
      // Authenticated — connect with backend token.
      debugPrint('[SETUP] Connecting engine (authenticated, user=${backendAuth.username})...');
      authResult = await engineAuth.connect(backendToken: backendAuth.token);

      // Persist the session token so restarts don't require re-login.
      await tokenStore.saveSession(
        backendToken: backendAuth.token,
        expiresAt: backendAuth.expiresAt,
        scope: backendAuth.scope,
        username: backendAuth.username,
        email: backendAuth.email,
        sessionToken: authResult.sessionToken,
      );
    } else {
      // Anonymous — get an anonymous session.
      debugPrint('[SETUP] Connecting engine (anonymous)...');
      authResult = await engineAuth.authenticateAnonymous();
    }

    debugPrint('[SETUP] Got session token, connecting WS...');
    await connection.reconnect(authResult.sessionToken);
    debugPrint('[SETUP] Engine WS connected (mode=${authResult.authMode})');
  }

  /// Waits for the engine to signal `database_state_changed` with
  /// `state == 'ready'`. Handles `migration_pending` by prompting the user,
  /// then continues waiting for `ready`. Never proceeds without confirmation.
  Future<void> _waitForDatabase() async {
    final client = ref.read(engineClientProvider);
    debugPrint('[SETUP] _waitForDatabase: subscribing to events...');

    final completer = Completer<void>();
    late final StreamSubscription<EventFrame> sub;

    Future<void> handleState(String? state) async {
      debugPrint('[SETUP] database state: $state');
      if (completer.isCompleted) return;

      if (state == 'ready') {
        sub.cancel();
        completer.complete();
      } else if (state == 'migration_pending') {
        if (!mounted) return;
        // Show dialog and send the user's choice. Do NOT complete —
        // wait for the engine to emit 'ready' after the migration finishes.
        await _showMigrationDialog();
      }
    }

    // Listen for all database_state_changed events.
    sub = client.events.listen((event) {
      if (event.name != 'database_state_changed') return;
      handleState(event.data['state'] as String?);
    }, onError: (e) {
      debugPrint('[SETUP] Event stream error: $e');
      sub.cancel();
      if (!completer.isCompleted) completer.completeError(e);
    });

    // Query current state to handle the case where the event was already
    // emitted before we subscribed. The event listener above remains active
    // so we never miss a transition.
    try {
      final dbState = await client.send(GetDatabaseState());
      final state = dbState.raw['state'] as String?;
      debugPrint('[SETUP] GetDatabaseState returned: state=$state');
      await handleState(state);
    } catch (e) {
      debugPrint('[SETUP] GetDatabaseState failed (waiting for events): $e');
    }

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
    // _waitForDatabase's event listener will complete the completer.
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
