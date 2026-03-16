// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/platform_info.dart';
import '../../../di/providers.dart';
import '../../../engine_client/engine_health.dart';
import '../../../engine_client/models/db_state.dart';

/// Compact 4-column status grid at the top of the Engine dashboard.
///
/// Shows Engine Status, Docker Status, Database, and Auth mode.
/// Conditionally shows sysbox warning banner below.
class StatusGrid extends ConsumerWidget {
  const StatusGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(engineHealthProvider);
    final dockerStatus = ref.watch(dockerStatusProvider);
    final dbState = ref.watch(dbStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Engine Status
            Expanded(child: _EngineCard(health: health)),
            const SizedBox(width: Spacing.sm),
            // Card 2: Docker Status
            Expanded(child: _DockerCard(status: dockerStatus)),
            const SizedBox(width: Spacing.sm),
            // Card 3: Database
            Expanded(child: _DatabaseCard(dbState: dbState)),
            const SizedBox(width: Spacing.sm),
            // Card 4: Auth
            Expanded(child: _AuthCard(health: health)),
          ],
        ),

        // Sysbox warning (Linux only)
        if (dockerStatus.hasValue &&
            dockerStatus.value!.isRunning &&
            PlatformInfo.isLinux &&
            !dockerStatus.value!.hasSysbox) ...[
          const SizedBox(height: Spacing.sm),
          const StatusCard(
            icon: LucideIcons.triangle_alert,
            color: AppColors.warning,
            text:
                'Sysbox not available — containers will run in privileged mode',
          ),
        ],
      ],
    );
  }
}

// ─── Card widgets ──────────────────────────────────────────────────────────

class _EngineCard extends StatelessWidget {
  const _EngineCard({required this.health});
  final AsyncValue<HealthStatus> health;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      icon: health.when(
        loading: () => const _SpinnerIcon(),
        error: (_, _) => const Icon(LucideIcons.circle_x,
            size: 16, color: AppColors.destructive),
        data: (h) => Icon(
          h.isRunning ? LucideIcons.circle_check : LucideIcons.circle_x,
          size: 16,
          color: h.isRunning ? AppColors.success : AppColors.destructive,
        ),
      ),
      value: health.when(
        loading: () => const Text('Checking...',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground)),
        error: (_, _) => const Text('Unreachable',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.destructive)),
        data: (h) => Text(
          _formatUptime(h.uptimeSeconds),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.mono,
          ),
        ),
      ),
      label: 'Engine',
    );
  }

  static String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }
}

class _DockerCard extends StatelessWidget {
  const _DockerCard({required this.status});
  final AsyncValue<dynamic> status;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      icon: status.when(
        loading: () => const _SpinnerIcon(),
        error: (_, _) => const Icon(LucideIcons.circle_alert,
            size: 16, color: AppColors.destructive),
        data: (s) => Icon(
          s.isRunning ? LucideIcons.circle_check : LucideIcons.circle_x,
          size: 16,
          color: s.isRunning ? AppColors.success : AppColors.destructive,
        ),
      ),
      value: status.when(
        loading: () => const Text('Checking...',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground)),
        error: (_, _) => const Text('Error',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.destructive)),
        data: (s) => Text(
          s.isRunning
              ? (s.dockerVersion != null ? 'v${s.dockerVersion}' : 'Ready')
              : s.isInstalled
                  ? 'Not Running'
                  : 'Not Installed',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: s.isRunning ? AppColors.foreground : AppColors.destructive,
          ),
        ),
      ),
      label: 'Docker',
    );
  }
}

class _DatabaseCard extends StatelessWidget {
  const _DatabaseCard({required this.dbState});
  final DbState dbState;

  @override
  Widget build(BuildContext context) {
    final isReady = dbState == DbState.ready;
    final isPending = dbState == DbState.migrationPending;

    return _MetricCard(
      icon: Icon(
        isPending ? LucideIcons.triangle_alert : LucideIcons.database,
        size: 16,
        color: isPending ? AppColors.warning : AppColors.mutedForeground,
      ),
      value: Text(
        isReady
            ? 'v12 Ready'
            : isPending
                ? 'Migration Pending'
                : 'Unknown',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isPending ? AppColors.warning : null,
        ),
      ),
      label: 'Database',
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.health});
  final AsyncValue<HealthStatus> health;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      icon: Icon(
        health.valueOrNull?.authenticated == true
            ? LucideIcons.shield_check
            : LucideIcons.shield,
        size: 16,
        color: AppColors.mutedForeground,
      ),
      value: health.when(
        loading: () => const Text('...',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground)),
        error: (_, _) => const Text('Unknown',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground)),
        data: (h) => Text(
          h.authenticated ? 'Connected' : 'Anonymous',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      label: 'Auth',
    );
  }
}

// ─── Shared private widgets ────────────────────────────────────────────────

/// A compact metric card: icon + value text + muted sublabel.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DspatchCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          icon,
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                value,
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small spinner matching the 16px icon size.
class _SpinnerIcon extends StatelessWidget {
  const _SpinnerIcon();

  @override
  Widget build(BuildContext context) {
    return const Spinner(
      size: SpinnerSize.sm,
      color: AppColors.mutedForeground,
    );
  }
}
