// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../engine_client/protocol/protocol.dart';

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
      final client = ref.read(engineClientProvider);

      // Wait for the database to become ready or signal migration.
      setState(() => _status = 'Waiting for database...');
      await _waitForDatabase();

      debugPrint('[SETUP] Database ready');

      // Load saved theme.
      if (!mounted) return;
      setState(() => _status = 'Loading preferences...');

      try {
        final pref = await client.getPreference('theme_mode');
        final value = pref['value'] as String?;
        if (!mounted) return;
        if (value != null) {
          final mode = ThemeMode.values.firstWhere(
            (m) => m.name == value,
            orElse: () => ThemeMode.system,
          );
          final container = ProviderScope.containerOf(context);
          container.updateOverrides([
            themeModeProvider.overrideWith((_) => mode),
          ]);
        }
      } catch (_) {
        // Preference not set — use default theme.
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
  /// Listens to engine events for database state changes. The engine manages
  /// the actual DB initialization; we just react to its state signals.
  Future<void> _waitForDatabase() async {
    final client = ref.read(engineClientProvider);

    // Check if already ready by sending a command.
    try {
      final status = await client.sendCommand('get_database_state');
      final state = status['state'] as String?;
      if (state == 'ready') return;
      if (state == 'migration_pending') {
        if (!mounted) return;
        await _showMigrationDialog();
        return;
      }
    } catch (_) {
      // Command may not exist — fall through to event-based approach.
    }

    // Otherwise wait for the next state event from the engine's event stream.
    final completer = Completer<void>();
    late final StreamSubscription<EventFrame> sub;

    sub = client.events.listen((event) async {
      if (event.name != 'database_state_changed') return;
      final state = event.data['state'] as String?;
      if (state == 'ready') {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      } else if (state == 'migration_pending') {
        sub.cancel();
        if (!mounted) return;
        await _showMigrationDialog();
        if (!completer.isCompleted) completer.complete();
      }
    }, onError: (e) {
      sub.cancel();
      if (!completer.isCompleted) completer.completeError(e);
    });

    return completer.future;
  }

  /// Shows a dialog asking the user whether to migrate their anonymous data.
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
      await client.sendCommand('perform_migration');
    } else {
      debugPrint('[SETUP] User chose to skip migration');
      await client.sendCommand('skip_migration');
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
