// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../../core/utils/datetime_ext.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/display_error.dart';
import '../../../di/providers.dart';
import '../engine_controller.dart';

/// Table of d:spatch-managed Docker containers with status, ID, and actions.
class ContainerTable extends ConsumerWidget {
  const ContainerTable({super.key});

  static String _shortId(String id) =>
      id.length > 12 ? id.substring(0, 12) : id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerList = ref.watch(containerListProvider);
    final inProgress = ref.watch(operationInProgressProvider);
    final controller = ref.read(engineControllerProvider.notifier);

    // Don't show until Docker status is resolved.
    final status = ref.watch(dockerStatusProvider);
    if (status.isLoading || status.hasError) return const SizedBox.shrink();
    final dockerStatus = status.value;
    if (dockerStatus == null || !dockerStatus.isRunning) {
      return const SizedBox.shrink();
    }

    final filter = ref.watch(containerFilterProvider);

    return DspatchCard(
      title: 'Containers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter + bulk action bar
          Row(
            children: [
              ToggleGroup(
                type: ToggleGroupType.single,
                style: ToggleGroupStyle.grouped,
                iconMode: false,
                variant: ToggleVariant.outline,
                size: ToggleSize.sm,
                value: {filter.name},
                onChanged: (v) {
                  if (v.isNotEmpty) {
                    ref.read(containerFilterProvider.notifier).state =
                        ContainerFilter.values.byName(v.first);
                  }
                },
                children: const [
                  ToggleGroupItem(
                    value: 'all',
                    child: Text('All', style: TextStyle(fontSize: 12)),
                  ),
                  ToggleGroupItem(
                    value: 'running',
                    child: Text('Running', style: TextStyle(fontSize: 12)),
                  ),
                  ToggleGroupItem(
                    value: 'stopped',
                    child: Text('Stopped', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Wrap(
                  spacing: Spacing.sm,
                  children: [
                    Button(
                      label: 'Stop All',
                      variant: ButtonVariant.outline,
                      onPressed: inProgress
                          ? null
                          : () => controller.stopAllContainers(),
                    ),
                    Button(
                      label: 'Delete Stopped',
                      variant: ButtonVariant.outline,
                      onPressed: inProgress
                          ? null
                          : () => controller.deleteStoppedContainers(),
                    ),
                    Button(
                      label: 'Clean Orphaned',
                      variant: ButtonVariant.outline,
                      onPressed: inProgress
                          ? null
                          : () => controller.cleanOrphaned(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Container list — preserve previous data during refresh to avoid flicker.
          containerList.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(Spacing.xl),
                child: Spinner(),
              ),
            ),
            error: (e, _) => ErrorStateView(
              message: 'Failed to list containers: ${displayError(e)}',
              onRetry: () => ref.invalidate(containerListProvider),
            ),
            data: (containers) {
              // Filter by state.
              final filtered = switch (filter) {
                ContainerFilter.all => containers,
                ContainerFilter.running => containers
                    .where((c) => c.state == 'running')
                    .toList(),
                ContainerFilter.stopped => containers
                    .where((c) => c.state != 'running')
                    .toList(),
              };

              // Sort by creation time (newest first).
              final sorted = [...filtered]
                ..sort((a, b) => b.created.compareTo(a.created));

              if (sorted.isEmpty) {
                return EmptyState(
                  icon: LucideIcons.server,
                  compact: true,
                  title: filter == ContainerFilter.all
                      ? 'No containers'
                      : 'No ${filter.name} containers',
                  description: filter == ContainerFilter.all
                      ? 'Containers will appear here when you start a session.'
                      : 'No ${filter.name} containers at the moment.',
                );
              }

              return Column(
                children: [
                  // Header
                  TableHeader(
                    child: Row(
                      children: const [
                        SizedBox(
                            width: 28,
                            child: Text('', style: TableHeader.headerStyle)),
                        Expanded(
                            flex: 3,
                            child: Text('Container ID',
                                style: TableHeader.headerStyle)),
                        Expanded(
                            flex: 3,
                            child:
                                Text('Image', style: TableHeader.headerStyle)),
                        Expanded(
                            flex: 1,
                            child: Text('Status',
                                style: TableHeader.headerStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('Started',
                                style: TableHeader.headerStyle)),
                        SizedBox(width: 64),
                      ],
                    ),
                  ),
                  // Rows
                  ...sorted.map((c) {
                    final isRunning = c.state == 'running';
                    final createdAt =
                        DateTime.fromMillisecondsSinceEpoch(c.created * 1000);

                    return DspatchTableRow(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: isRunning
                                ? const PulsingDot(
                                    color: AppColors.success,
                                    size: 12,
                                  )
                                : Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (c.state == 'exited'
                                              ? AppColors.mutedForeground
                                              : AppColors.destructive)
                                          .withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: c.state == 'exited'
                                            ? AppColors.mutedForeground
                                            : AppColors.destructive,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _shortId(c.id),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: AppFonts.mono,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              c.image,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: DspatchBadge(
                                label: _badgeLabel(c.state),
                                variant: _badgeVariant(c.state),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              createdAt.timeAgo(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isRunning)
                                  DspatchTooltip(
                                    message: 'Stop container',
                                    child: DspatchIconButton(
                                      icon: LucideIcons.square,
                                      variant: IconButtonVariant.ghost,
                                      size: IconButtonSize.sm,
                                      onPressed: inProgress
                                          ? null
                                          : () => controller
                                              .stopContainer(c.id),
                                    ),
                                  )
                                else
                                  DspatchTooltip(
                                    message: 'Remove container',
                                    child: DspatchIconButton(
                                      icon: LucideIcons.trash_2,
                                      variant: IconButtonVariant.ghost,
                                      size: IconButtonSize.sm,
                                      onPressed: inProgress
                                          ? null
                                          : () => controller
                                              .removeContainer(c.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _badgeLabel(String state) => switch (state) {
        'running' => 'Running',
        'exited' => 'Exited',
        'created' => 'Created',
        'dead' => 'Dead',
        'removing' => 'Removing',
        'paused' => 'Paused',
        'restarting' => 'Restarting',
        _ => state.isNotEmpty
            ? '${state[0].toUpperCase()}${state.substring(1)}'
            : 'Unknown',
      };

  static BadgeVariant _badgeVariant(String state) => switch (state) {
        'running' => BadgeVariant.success,
        'exited' => BadgeVariant.secondary,
        'created' => BadgeVariant.info,
        'paused' => BadgeVariant.warning,
        'restarting' => BadgeVariant.warning,
        _ => BadgeVariant.destructive,
      };
}
