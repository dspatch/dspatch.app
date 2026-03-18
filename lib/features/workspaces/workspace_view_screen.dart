// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../database/engine_database.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/string_ext.dart';
import '../../di/providers.dart';
import 'widgets/agent_hierarchy_sidebar.dart';
import 'widgets/agent_timeline_view.dart';
import 'widgets/workspace_level_view.dart';
import 'workspace_controller.dart';

class WorkspaceViewScreen extends ConsumerWidget {
  const WorkspaceViewScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider(id));

    return workspaceAsync.when(
      loading: () => const Center(child: Spinner()),
      error: (error, _) => Center(
        child: EmptyState(
          icon: LucideIcons.circle_alert,
          title: 'Workspace not found',
          description: 'This workspace may have been deleted.',
          actions: [
            Button(
              label: 'Back to Workspaces',
              onPressed: () => context.go('/workspaces'),
            ),
          ],
        ),
      ),
      data: (workspace) {
        if (workspace == null) {
          return Center(
            child: EmptyState(
              icon: LucideIcons.circle_alert,
              title: 'Workspace not found',
              description: 'This workspace may have been deleted.',
              actions: [
                Button(
                  label: 'Back to Workspaces',
                  onPressed: () => context.go('/workspaces'),
                ),
              ],
            ),
          );
        }
        return _WorkspaceViewBody(
          workspaceId: id,
          workspace: workspace,
        );
      },
    );
  }
}

class _WorkspaceViewBody extends ConsumerWidget {
  const _WorkspaceViewBody({
    required this.workspaceId,
    required this.workspace,
  });

  final String workspaceId;
  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(
      workspaceConfigProvider(workspace.projectPath)
          .select((async) => async.valueOrNull),
    );
    final latestRun = ref.watch(latestRunProvider(workspaceId));
    final runId = latestRun?.id;
    final agents = runId != null
        ? ref.watch(
            workspaceAgentsProvider(runId)
                .select((async) => async.valueOrNull ?? <WorkspaceAgent>[]),
          )
        : <WorkspaceAgent>[];
    final selectedInstance = ref.watch(selectedInstanceProvider(workspaceId));

    // Derive workspace status from the viewable run
    final runStatus = latestRun?.status;
    final isRunning = runStatus == 'running';
    final isStarting = runStatus == 'starting';

    return Column(
      children: [
        // ── Dashboard header (full width, above sidebar + content) ──
        _WorkspaceDashboard(
          workspace: workspace,
          agents: agents,
          activeRun: latestRun,
          onBack: () => context.go('/workspaces'),
          onViewLogs: () {
            // Select workspace-level view and switch to logs tab
            ref.read(selectedInstanceProvider(workspaceId).notifier).state =
                null;
          },
        ),
        // ── Sidebar + content area ──
        Expanded(
          child: Row(
            children: [
              AgentHierarchySidebar(
                workspaceId: workspaceId,
                workspace: workspace,
                config: config,
                agents: agents,
                runId: runId,
                isRunning: isRunning || isStarting,
                runStatus: runStatus,
                isLoading: ref.watch(
                  workspaceControllerProvider.select((s) => s.isLoading),
                ),
                onStart: () => ref
                    .read(workspaceControllerProvider.notifier)
                    .launchWorkspace(workspaceId),
                onStop: () => ref
                    .read(workspaceControllerProvider.notifier)
                    .stopWorkspace(workspaceId),
                onRestart: () => ref
                    .read(workspaceControllerProvider.notifier)
                    .restartWorkspace(workspaceId),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: runId == null
                    ? const EmptyState(
                        icon: LucideIcons.circle_play,
                        title: 'No Active Run',
                        description:
                            'Start the workspace to see agent data.',
                      )
                    : selectedInstance == null
                        ? WorkspaceLevelView(
                            runId: runId,
                            workspace: workspace,
                            agents: agents,
                          )
                        : AgentTimelineView(
                            workspaceId: workspaceId,
                            runId: runId,
                            instanceId: selectedInstance,
                            agents: agents,
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

// ── Workspace dashboard header ──────────────────────────────────────

class _WorkspaceDashboard extends ConsumerWidget {
  const _WorkspaceDashboard({
    required this.workspace,
    required this.agents,
    required this.activeRun,
    required this.onBack,
    required this.onViewLogs,
  });

  final Workspace workspace;
  final List<WorkspaceAgent> agents;
  final dynamic activeRun; // WorkspaceRun?
  final VoidCallback onBack;
  final VoidCallback onViewLogs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runId = activeRun?.id as String?;
    final usageAsync = runId != null
        ? ref.watch(workspaceUsageProvider((
            runId: runId,
            instanceId: null,
          )))
        : null;
    final pendingCount = ref
            .watch(pendingWorkspaceInquiryCountProvider(workspace.id))
            .valueOrNull ??
        0;
    final isLoading = ref.watch(
      workspaceControllerProvider.select((s) => s.isLoading),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                DspatchIconButton(
                  icon: LucideIcons.arrow_left,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  onPressed: onBack,
                  tooltip: 'Back to workspaces',
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              workspace.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Text(
                            workspace.id.shortIdForLog,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          CopyButton(
                            textToCopy: workspace.id,
                            iconSize: 14,
                          ),
                        ],
                      ),
                      Text(
                        workspace.projectPath,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.md),
                _buildMetrics(usageAsync),
                const SizedBox(width: Spacing.sm),
                _buildControls(ref, isLoading),
              ],
            ),

            // ── Status + container stats row ──
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: _buildStatusRow(pendingCount, null),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status row ──────────────────────────────────────────────────

  Widget _buildStatusRow(
      int pendingCount, AsyncValue<dynamic>? statsAsync) {
    final runStatus = activeRun?.status as String? ?? 'idle';
    final description = _statusDescription(runStatus, pendingCount);

    // Extract container stats if available
    final stats = statsAsync?.valueOrNull;

    return Row(
      children: [
        DspatchBadge(
          label: runStatus,
          variant: _runStatusBadgeVariant(runStatus),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (stats != null) ...[
          _containerStatBadge(LucideIcons.cpu, stats.memUsage),
          _containerStatBadge(LucideIcons.gauge, stats.cpuPerc),
          _containerStatBadge(LucideIcons.hard_drive, stats.blockIO),
        ],
        if (pendingCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: Spacing.sm),
            child: DspatchBadge(
              icon: LucideIcons.circle_question_mark,
              label: '$pendingCount pending',
              variant: BadgeVariant.warning,
            ),
          ),
      ],
    );
  }

  Widget _containerStatBadge(IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: Spacing.xs),
      child: DspatchBadge(
        icon: icon,
        label: value,
        variant: BadgeVariant.secondary,
      ),
    );
  }

  String _statusDescription(String runStatus, int pendingCount) {
    return switch (runStatus) {
      'idle' => 'Workspace is idle',
      'starting' => 'Workspace is starting up',
      'running' => pendingCount > 0
          ? '$pendingCount inquiry${pendingCount == 1 ? '' : 'ies'} waiting for response'
          : 'Workspace is running',
      'stopping' => 'Workspace is shutting down',
      'failed' => 'Workspace terminated with an error',
      _ => 'Workspace is idle',
    };
  }

  static BadgeVariant _runStatusBadgeVariant(String status) {
    return switch (status) {
      'running' => BadgeVariant.success,
      'starting' => BadgeVariant.warning,
      'stopping' => BadgeVariant.warning,
      'failed' => BadgeVariant.destructive,
      _ => BadgeVariant.secondary,
    };
  }

  // ── Controls ────────────────────────────────────────────────────

  Widget _buildControls(WidgetRef ref, bool isLoading) {
    // TODO: Wire up start/stop controls using workspace controller + run status.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DspatchIconButton(
          icon: LucideIcons.file_text,
          variant: IconButtonVariant.ghost,
          size: IconButtonSize.sm,
          onPressed: onViewLogs,
          tooltip: 'View logs',
        ),
      ],
    );
  }

  // ── Metrics ─────────────────────────────────────────────────────

  Widget _buildMetrics(AsyncValue<List<AgentUsageRecord>>? usageAsync) {
    Widget badge(IconData icon, String label) => Padding(
          padding: const EdgeInsets.only(left: Spacing.xs),
          child: DspatchBadge(
            icon: icon,
            label: label,
            variant: BadgeVariant.secondary,
          ),
        );

    final runningCount =
        agents.where((a) => a.status == 'running').length;
    final agentLabel =
        '${agents.isEmpty ? 0 : runningCount}/${agents.length} agents';

    if (usageAsync == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge(LucideIcons.bot, agentLabel),
        ],
      );
    }

    return usageAsync.when(
      data: (records) {
        final totalTokens = records.fold<int>(
            0, (s, r) => s + r.inputTokens + r.outputTokens);
        final totalCost =
            records.fold<double>(0, (s, r) => s + r.costUsd);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge(LucideIcons.bot, agentLabel),
            badge(LucideIcons.coins, _fmtTokens(totalTokens)),
            badge(LucideIcons.dollar_sign,
                totalCost > 0 ? '\$${totalCost.toStringAsFixed(4)}' : '\u2014'),
            badge(LucideIcons.cpu, '${records.length} calls'),
          ],
        );
      },
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge(LucideIcons.bot, agentLabel),
        ],
      ),
      error: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge(LucideIcons.bot, agentLabel),
        ],
      ),
    );
  }

  static String _fmtTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

}
