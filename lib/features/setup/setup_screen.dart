// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';

/// Gateway screen shown after authentication.
///
/// Handles the full post-auth initialization sequence:
/// 1. Initializes the SDK (starts auth watcher).
/// 2. Waits for database state (Ready or MigrationPending).
/// 3. If migration pending, prompts the user.
/// 4. Loads saved theme preference.
/// 5. Initializes notifications.
/// 6. Redirects to /workspaces when ready.
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
      final sdk = ref.read(sdkProvider);

      // Initialize the SDK (starts auth watcher, opens DB asynchronously).
      await sdk.initialize();
      debugPrint('[SETUP] SDK initialized');

      // Wait for the database to become ready or signal migration.
      await _waitForDatabase(sdk);

      // Load saved theme.
      if (!mounted) return;
      setState(() => _status = 'Loading preferences...');

      final pref = await sdk.getPreference(key: 'theme_mode');
      if (!mounted) return;
      if (pref != null) {
        final mode = ThemeMode.values.firstWhere(
          (m) => m.name == pref,
          orElse: () => ThemeMode.system,
        );
        final container = ProviderScope.containerOf(context);
        container.updateOverrides([
          themeModeProvider.overrideWith((_) => mode),
        ]);
      }

      debugPrint('[SETUP] Setup complete, navigating to /workspaces');
      if (mounted) context.go('/workspaces');
    } catch (e) {
      debugPrint('[SETUP] Error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Waits for the database to become ready, handling migration if needed.
  ///
  /// Checks both the stream (for future events) and `isMigrationPending()`
  /// (for events that fired before we subscribed).
  Future<void> _waitForDatabase(RustSdk sdk) async {
    // If already ready, skip.
    if (await sdk.isDatabaseReady()) return;

    // Check if migration was already signalled before we subscribed.
    if (await sdk.isMigrationPending()) {
      debugPrint('[SETUP] Migration pending (caught on check) — prompting user');
      if (!mounted) return;
      await _showMigrationDialog(sdk);
      return;
    }

    // Otherwise wait for the next state event.
    final completer = Completer<void>();
    late final StreamSubscription<DatabaseReadyState> sub;

    sub = sdk.watchDatabaseState().listen((state) async {
      switch (state) {
        case DatabaseReadyState.ready:
          debugPrint('[SETUP] Database ready');
          sub.cancel();
          if (!completer.isCompleted) completer.complete();

        case DatabaseReadyState.migrationPending:
          debugPrint('[SETUP] Migration pending — prompting user');
          sub.cancel();
          if (!mounted) return;
          await _showMigrationDialog(sdk);
          if (!completer.isCompleted) completer.complete();

        case DatabaseReadyState.closed:
          break; // Transient state, ignore.
      }
    }, onError: (e) {
      sub.cancel();
      if (!completer.isCompleted) completer.completeError(e);
    });

    return completer.future;
  }

  /// Shows a dialog asking the user whether to migrate their anonymous data.
  Future<void> _showMigrationDialog(RustSdk sdk) async {
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
      await sdk.performMigration();
    } else {
      debugPrint('[SETUP] User chose to skip migration');
      await sdk.skipMigration();
    }
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
