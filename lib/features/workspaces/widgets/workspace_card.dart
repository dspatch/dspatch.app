// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../../core/extensions/drift_extensions.dart';
import '../../../database/engine_database.dart';
import '../../../core/utils/datetime_ext.dart';
import '../../../core/utils/workspace_status.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';

class WorkspaceCard extends ConsumerWidget {
  const WorkspaceCard({
    super.key,
    required this.workspace,
    required this.onTap,
    required this.onDelete,
    this.status = WorkspaceStatus.idle,
    this.onStart,
    this.onStop,
    this.onSubmitToHub,
    this.isLoading = false,
  });

  final Workspace workspace;
  final WorkspaceStatus status;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onSubmitToHub;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: DspatchCard(
          child: Row(
            children: [
              // Name + project path
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workspace.name,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      workspace.projectPath,
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontFamily: AppFonts.mono,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Agent count from config on disk
              SizedBox(
                width: 48,
                child: Consumer(
                  builder: (context, ref, _) {
                    final configAsync =
                        ref.watch(workspaceConfigProvider(workspace.projectPath));
                    return configAsync.when(
                      data: (config) => _MetaChip(
                        icon: LucideIcons.user,
                        value: config != null ? '${(config['agents'] as Map?)?.length ?? 0}' : '?',
                      ),
                      loading: () =>
                          const Skeleton(width: 28, height: 14),
                      error: (_, _) => const _MetaChip(
                        icon: LucideIcons.user,
                        value: '?',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Status badge
              DspatchBadge(
                label: status.name,
                variant: _badgeVariant(status),
              ),
              const SizedBox(width: Spacing.md),

              // Updated time
              SizedBox(
                width: 52,
                child: Text(
                  workspace.updatedAtDate.timeAgo(),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: Spacing.sm),

              // Start/Stop button
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: Spinner(
                    size: SpinnerSize.sm,
                    color: AppColors.mutedForeground,
                  ),
                )
              else if (status == WorkspaceStatus.idle ||
                  status == WorkspaceStatus.failed)
                DspatchIconButton(
                  icon: LucideIcons.play,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  tooltip: 'Start',
                  onPressed: onStart,
                )
              else if (status == WorkspaceStatus.running)
                DspatchIconButton(
                  icon: LucideIcons.square,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  tooltip: 'Stop',
                  onPressed: onStop,
                )
              else
                const SizedBox(width: 24),
              const SizedBox(width: 2),

              // Submit to Hub button
              if (onSubmitToHub != null)
                DspatchIconButton(
                  icon: LucideIcons.upload,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  tooltip: 'Submit to Hub',
                  onPressed: onSubmitToHub,
                ),

              // Delete button
              DspatchIconButton(
                icon: LucideIcons.trash_2,
                variant: IconButtonVariant.ghost,
                size: IconButtonSize.sm,
                tooltip: 'Delete',
                onPressed: status == WorkspaceStatus.running
                    ? null
                    : onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static BadgeVariant _badgeVariant(WorkspaceStatus status) {
    return switch (status) {
      WorkspaceStatus.idle => BadgeVariant.secondary,
      WorkspaceStatus.starting => BadgeVariant.primary,
      WorkspaceStatus.running => BadgeVariant.success,
      WorkspaceStatus.stopping => BadgeVariant.warning,
      WorkspaceStatus.failed => BadgeVariant.destructive,
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.mutedForeground),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 11,
            fontFamily: AppFonts.mono,
          ),
        ),
      ],
    );
  }
}
