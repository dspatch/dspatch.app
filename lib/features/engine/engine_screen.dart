// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/platform_info.dart';
import 'engine_controller.dart';
import 'widgets/container_table.dart';
import 'widgets/docker_error_banner.dart';
import 'widgets/operation_console.dart';
import 'widgets/status_grid.dart';

/// Engine screen — Docker infrastructure management (desktop only).
///
/// Shows Docker status, runtime image management, container table,
/// and an operation console for build/bulk operation output.
class EngineScreen extends ConsumerWidget {
  const EngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformInfo.isDesktop) {
      return const EmptyState(
        icon: LucideIcons.monitor,
        title: 'Desktop Only',
        description:
            'Docker engine management is only available on desktop platforms.',
      );
    }

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Docker Engine',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              Button(
                label: 'Refresh',
                variant: ButtonVariant.outline,
                icon: LucideIcons.refresh_cw,
                onPressed: () => ref
                    .read(engineControllerProvider.notifier)
                    .refreshStatus(),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Docker error/install banner (pinned above scroll)
          const DockerErrorBanner(),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  StatusGrid(),
                  SizedBox(height: Spacing.md),
                  OperationConsole(),
                  SizedBox(height: Spacing.md),
                  ContainerTable(),
                  SizedBox(height: Spacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
