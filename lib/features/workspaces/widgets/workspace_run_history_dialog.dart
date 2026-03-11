// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import '../../../core/utils/datetime_ext.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import 'workspace_run_viewer_dialog.dart';

/// Dialog showing the list of past runs for a workspace.
class WorkspaceRunHistoryDialog extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceRunHistoryDialog({super.key, required this.workspaceId});

  static Future<void> show(BuildContext context, String workspaceId) {
    return DspatchDialog.show(
      context: context,
      maxWidth: 700,
      builder: (_) => WorkspaceRunHistoryDialog(workspaceId: workspaceId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(workspaceRunsProvider(workspaceId));
    final activeRun = ref.watch(activeRunProvider(workspaceId));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.xxl, Spacing.xxl, Spacing.lg, 0),
            child: Row(
              children: [
                const Text(
                  'Run History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const Spacer(),
                Button(
                  label: 'Clear History',
                  variant: ButtonVariant.ghost,
                  size: ButtonSize.sm,
                  icon: LucideIcons.trash_2,
                  onPressed: () async {
                    try {
                      await ref.read(sdkProvider).deleteNonActiveRuns(
                            workspaceId: workspaceId,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        toast('Failed to clear history: $e',
                            type: ToastType.error);
                      }
                    }
                  },
                ),
                const SizedBox(width: Spacing.xs),
                DspatchIconButton(
                  icon: LucideIcons.x,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.xxl),
            child: Text(
              'View or manage past workspace runs.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Run list
          Flexible(
            child: runsAsync.when(
              data: (runs) {
                if (runs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(Spacing.xxl),
                    child: Center(
                      child: Text(
                        'No runs yet',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                final activeRunId = activeRun?.id;
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.xxl, 0, Spacing.xxl, Spacing.xxl),
                  itemCount: runs.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final run = runs[index];
                    final isActive = run.id == activeRunId;
                    return _RunRow(
                      run: run,
                      isActive: isActive,
                      workspaceId: workspaceId,
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(Spacing.xxl),
                child: Center(child: Spinner()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(Spacing.xxl),
                child: Center(
                  child: Text(
                    'Error: $e',
                    style:
                        const TextStyle(color: AppColors.destructive, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunRow extends ConsumerWidget {
  final WorkspaceRun run;
  final bool isActive;
  final String workspaceId;

  const _RunRow({
    required this.run,
    required this.isActive,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = run.stoppedAt != null
        ? run.stoppedAt!.difference(run.startedAt)
        : DateTime.now().difference(run.startedAt);
    final durationStr = '${duration.inMinutes}m ${duration.inSeconds % 60}s';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Text(
            'Run #${run.runNumber}',
            style: const TextStyle(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          DspatchBadge(
            label: isActive ? 'active' : run.status,
            variant: _badgeVariant(run.status, isActive),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            run.startedAt.formatted(),
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            durationStr,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontFamily: AppFonts.mono,
            ),
          ),
          const Spacer(),
          if (!isActive) ...[
            Button(
              label: 'View',
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              onPressed: () {
                Navigator.of(context).pop();
                WorkspaceRunViewerDialog.show(context, run);
              },
            ),
            const SizedBox(width: Spacing.xs),
            Button(
              label: 'Delete',
              variant: ButtonVariant.destructive,
              size: ButtonSize.sm,
              onPressed: () async {
                try {
                  await ref.read(sdkProvider).deleteWorkspaceRun(
                        runId: run.id,
                      );
                } catch (e) {
                  if (context.mounted) {
                    toast('Failed to delete run: $e',
                        type: ToastType.error);
                  }
                }
              },
            ),
          ] else
            const Text(
              'Current',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  BadgeVariant _badgeVariant(String status, bool isActive) {
    if (isActive) return BadgeVariant.success;
    return switch (status) {
      'running' => BadgeVariant.success,
      'stopped' => BadgeVariant.secondary,
      'failed' => BadgeVariant.destructive,
      _ => BadgeVariant.secondary,
    };
  }
}
