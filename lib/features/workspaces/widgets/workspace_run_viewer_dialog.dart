// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import '../../../core/utils/datetime_ext.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import 'workspace_tabs/workspace_logs_tab.dart';

/// Full-screen modal for viewing a past run's data (read-only).
///
/// Shows a banner with run info, a sidebar listing agents from that run,
/// and tabbed content (Logs, Usage) scoped to the historical [runId].
class WorkspaceRunViewerDialog extends ConsumerStatefulWidget {
  final WorkspaceRun run;

  const WorkspaceRunViewerDialog({super.key, required this.run});

  static Future<void> show(BuildContext context, WorkspaceRun run) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => WorkspaceRunViewerDialog(run: run),
    );
  }

  @override
  ConsumerState<WorkspaceRunViewerDialog> createState() =>
      _WorkspaceRunViewerDialogState();
}

class _WorkspaceRunViewerDialogState
    extends ConsumerState<WorkspaceRunViewerDialog> {
  String? _selectedInstanceId;

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final agentsAsync = ref.watch(workspaceAgentsProvider(run.id));
    final agents = agentsAsync.valueOrNull ?? [];

    final duration = run.stoppedAt != null
        ? run.stoppedAt!.difference(run.startedAt)
        : DateTime.now().difference(run.startedAt);
    final durationStr = '${duration.inMinutes}m ${duration.inSeconds % 60}s';

    return Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // ── Run info banner ──
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  DspatchIconButton(
                    icon: LucideIcons.x,
                    variant: IconButtonVariant.ghost,
                    size: IconButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close viewer',
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Icon(
                    LucideIcons.history,
                    size: 16,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    'Run #${run.runNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  DspatchBadge(
                    label: run.status,
                    variant: _runStatusBadgeVariant(run.status),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    run.startedAt.formatted(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    durationStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                  const Spacer(),
                  DspatchBadge(
                    icon: LucideIcons.eye,
                    label: 'Read-only',
                    variant: BadgeVariant.secondary,
                  ),
                ],
              ),
            ),
          ),

          // ── Sidebar + content area ──
          Expanded(
            child: Row(
              children: [
                // Agent sidebar
                _RunAgentSidebar(
                  agents: agents,
                  selectedInstanceId: _selectedInstanceId,
                  onSelectInstance: (id) {
                    setState(() {
                      _selectedInstanceId =
                          _selectedInstanceId == id ? null : id;
                    });
                  },
                ),
                const VerticalDivider(width: 1, thickness: 1),

                // Content area with tabs
                Expanded(
                  child: _RunContentArea(
                    runId: run.id,
                    agents: agents,
                    selectedInstanceId: _selectedInstanceId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

// ── Agent sidebar (read-only) ──

class _RunAgentSidebar extends StatelessWidget {
  const _RunAgentSidebar({
    required this.agents,
    required this.selectedInstanceId,
    required this.onSelectInstance,
  });

  final List<WorkspaceAgent> agents;
  final String? selectedInstanceId;
  final ValueChanged<String?> onSelectInstance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () => onSelectInstance(null),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: selectedInstanceId == null
                    ? AppColors.surfaceHover
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.layout_grid,
                    size: 14,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: Spacing.xs),
                  const Text(
                    'All Agents',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${agents.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Agent list
          Expanded(
            child: agents.isEmpty
                ? const Center(
                    child: Text(
                      'No agents',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: Spacing.xs),
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      final isSelected =
                          agent.instanceId == selectedInstanceId;
                      return InkWell(
                        onTap: () =>
                            onSelectInstance(agent.instanceId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.surfaceHover
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _statusColor(agent.status),
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Expanded(
                                child: Text(
                                  agent.agentKey,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppColors.foreground
                                        : AppColors.mutedForeground,
                                    fontFamily: AppFonts.mono,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: Spacing.xs),
                              DspatchBadge(
                                label: agent.status.name,
                                variant: _agentBadgeVariant(agent.status),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AgentState status) {
    return switch (status) {
      AgentState.generating => AppColors.success,
      AgentState.completed => AppColors.primary,
      AgentState.failed || AgentState.crashed => AppColors.destructive,
      AgentState.waitingForInquiry ||
      AgentState.waitingForAgent =>
        AppColors.warning,
      _ => AppColors.mutedForeground,
    };
  }

  BadgeVariant _agentBadgeVariant(AgentState status) {
    return switch (status) {
      AgentState.generating => BadgeVariant.success,
      AgentState.completed => BadgeVariant.primary,
      AgentState.failed || AgentState.crashed => BadgeVariant.destructive,
      AgentState.waitingForInquiry ||
      AgentState.waitingForAgent =>
        BadgeVariant.warning,
      _ => BadgeVariant.secondary,
    };
  }
}

// ── Content area with tabs (read-only) ──

class _RunContentArea extends ConsumerWidget {
  const _RunContentArea({
    required this.runId,
    required this.agents,
    required this.selectedInstanceId,
  });

  final String runId;
  final List<WorkspaceAgent> agents;
  final String? selectedInstanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DspatchTabs(
      defaultValue: 'logs',
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  TabsList(
                    children: const [
                      TabsTrigger(
                        value: 'logs',
                        child: Text('Logs'),
                      ),
                      TabsTrigger(
                        value: 'agents',
                        child: Text('Agents'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: Stack(
              children: [
                TabsContent(
                  value: 'logs',
                  child: WorkspaceLogsTab(
                    runId: runId,
                    agents: agents,
                  ),
                ),
                TabsContent(
                  value: 'agents',
                  child: _AgentSummaryTab(agents: agents),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agent summary tab (read-only list of agents and their final status) ──

class _AgentSummaryTab extends StatelessWidget {
  const _AgentSummaryTab({required this.agents});

  final List<WorkspaceAgent> agents;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.bot,
        title: 'No Agents',
        description: 'No agents were registered during this run.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: agents.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final agent = agents[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.agentKey,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Instance: ${agent.instanceId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                    Text(
                      'Display: ${agent.displayName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ],
                ),
              ),
              DspatchBadge(
                label: agent.status.name,
                variant: _badgeVariant(agent.status),
              ),
            ],
          ),
        );
      },
    );
  }

  BadgeVariant _badgeVariant(AgentState status) {
    return switch (status) {
      AgentState.generating => BadgeVariant.success,
      AgentState.completed => BadgeVariant.primary,
      AgentState.failed || AgentState.crashed => BadgeVariant.destructive,
      AgentState.waitingForInquiry ||
      AgentState.waitingForAgent =>
        BadgeVariant.warning,
      _ => BadgeVariant.secondary,
    };
  }
}
