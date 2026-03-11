// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/platform_info.dart';
import '../../../di/providers.dart';
import '../engine_controller.dart';

/// Compact 4-column status grid at the top of the Engine dashboard.
///
/// Shows Docker Status, Docker Version, Runtime Image (with actions),
/// and Container counts. Conditionally shows install/sysbox banners below.
class StatusGrid extends ConsumerWidget {
  const StatusGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dockerStatusProvider);
    final containers = ref.watch(containerListProvider);
    final inProgress = ref.watch(operationInProgressProvider);
    final controller = ref.read(engineControllerProvider.notifier);

    // Derive container counts.
    final containerList = containers.valueOrNull ?? [];
    final runningCount =
        containerList.where((c) => c.state == 'running').length;
    final stoppedCount = containerList.length - runningCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Metric cards grid ──────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Docker Status
            Expanded(
              child: _MetricCard(
                icon: status.when(
                  loading: () => const _SpinnerIcon(),
                  error: (_, _) => const Icon(LucideIcons.circle_alert,
                      size: 16, color: AppColors.destructive),
                  data: (s) => Icon(
                    s.isRunning
                        ? LucideIcons.circle_check
                        : LucideIcons.circle_x,
                    size: 16,
                    color:
                        s.isRunning ? AppColors.success : AppColors.destructive,
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
                        ? 'Ready'
                        : s.isInstalled
                            ? 'Not Running'
                            : 'Not Installed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: s.isRunning
                          ? AppColors.success
                          : AppColors.destructive,
                    ),
                  ),
                ),
                label: 'Docker Status',
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // Card 2: Docker Version
            Expanded(
              child: _MetricCard(
                icon: const Icon(LucideIcons.terminal,
                    size: 16, color: AppColors.mutedForeground),
                value: Text(
                  status.valueOrNull?.dockerVersion ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.mono,
                  ),
                ),
                label: 'Docker Version',
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // Card 3: Runtime Image
            Expanded(
              child: _RuntimeImageCard(
                status: status,
                inProgress: inProgress,
                controller: controller,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            // Card 4: Containers
            Expanded(
              child: _MetricCard(
                icon: const Icon(LucideIcons.server,
                    size: 16, color: AppColors.mutedForeground),
                value: _ContainerCountLabel(
                  running: runningCount,
                  stopped: stoppedCount,
                ),
                label: 'Containers',
              ),
            ),
          ],
        ),

        // ── Conditional banners ────────────────────────────────────────
        // Docker install/error banners are handled by DockerErrorBanner
        // in engine_screen.dart (pinned above scroll area).
        if (status.hasValue &&
            status.value!.isRunning &&
            PlatformInfo.isLinux &&
            !status.value!.hasSysbox) ...[
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

// ─── Private sub-widgets ──────────────────────────────────────────────────

/// A compact metric card: icon + value text + muted sublabel.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    this.trailing,
  });

  final Widget icon;
  final Widget value;
  final String label;
  final Widget? trailing;

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
          ?trailing,
        ],
      ),
    );
  }
}

/// Runtime Image metric card with inline Build/Delete icon buttons.
class _RuntimeImageCard extends StatelessWidget {
  const _RuntimeImageCard({
    required this.status,
    required this.inProgress,
    required this.controller,
  });

  final AsyncValue<dynamic> status;
  final bool inProgress;
  final EngineController controller;

  @override
  Widget build(BuildContext context) {
    final dockerStatus = status.valueOrNull;
    final isRunning = dockerStatus?.isRunning ?? false;
    final hasImage = dockerStatus?.hasRuntimeImage ?? false;
    final disabled = inProgress || !isRunning;

    return _MetricCard(
      icon: Icon(
        hasImage ? LucideIcons.circle_check : LucideIcons.circle_x,
        size: 16,
        color: hasImage ? AppColors.success : AppColors.mutedForeground,
      ),
      value: Text(
        hasImage ? 'Built' : 'Not Built',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: hasImage ? AppColors.success : AppColors.mutedForeground,
        ),
      ),
      label: 'Runtime Image',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DspatchTooltip(
            message: hasImage ? 'Rebuild image' : 'Build image',
            child: DspatchIconButton(
              icon: LucideIcons.refresh_cw,
              variant: IconButtonVariant.outline,
              size: IconButtonSize.sm,
              onPressed: disabled
                  ? null
                  : () => hasImage
                      ? controller.rebuildRuntimeImage(context)
                      : controller.buildRuntimeImage(),
            ),
          ),
          if (hasImage)
            DspatchTooltip(
              message: 'Delete image',
              child: DspatchIconButton(
                icon: LucideIcons.trash_2,
                variant: IconButtonVariant.outline,
                size: IconButtonSize.sm,
                onPressed: disabled
                    ? null
                    : () => controller.deleteRuntimeImageCascade(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// Container count label: "X running / Y stopped".
class _ContainerCountLabel extends StatelessWidget {
  const _ContainerCountLabel({
    required this.running,
    required this.stopped,
  });

  final int running;
  final int stopped;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$running running',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (stopped > 0)
            TextSpan(
              text: ' / $stopped stopped',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: AppColors.mutedForeground,
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
