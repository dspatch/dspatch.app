// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/agent_state_ext.dart';
import '../../../database/engine_database.dart';
import '../../../di/providers.dart';
import 'status_colors.dart';


/// Sidebar showing the agent hierarchy tree with live status dots.
///
/// Uses a config map for the tree structure and [WorkspaceAgent] rows
/// for live status. Clicking an instance selects it in the content area;
/// clicking the workspace header deselects back to workspace-level view.
class AgentHierarchySidebar extends ConsumerWidget {
  const AgentHierarchySidebar({
    super.key,
    required this.workspaceId,
    required this.workspace,
    required this.config,
    required this.agents,
    required this.runId,
    required this.isRunning,
    required this.runStatus,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final String workspaceId;
  final Workspace workspace;
  final Map<String, dynamic>? config;
  final List<WorkspaceAgent> agents;
  final String? runId;
  final bool isRunning;
  final String? runStatus;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInstance = ref.watch(selectedInstanceProvider(workspaceId));

    final agentsMap = config?['agents'] as Map<String, dynamic>? ?? {};
    final agentOrder = (config?['agent_order'] as List<dynamic>?)
            ?.cast<String>() ??
        [];

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Workspace header (clickable → workspace-level) ──
          _WorkspaceHeaderRow(
            workspace: workspace,
            isSelected: selectedInstance == null,
            runStatus: runStatus,
            isLoading: isLoading,
            onTap: () => ref
                .read(selectedInstanceProvider(workspaceId).notifier)
                .state = null,
            onStart: onStart,
            onStop: onStop,
            onRestart: onRestart,
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── Agent tree ──
          Expanded(
            child: agentsMap.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.md),
                      child: Text(
                        'No agents configured',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _orderedAgentEntries(
                        agentsMap,
                        agentOrder,
                      ).map((entry) {
                        final agentConfig =
                            entry.value as Map<String, dynamic>;
                        return _AgentTreeNode(
                          workspaceId: workspaceId,
                          runId: runId,
                          isRunning: isRunning,
                          agentKey: entry.key,
                          agentConfig: agentConfig,
                          agents: agents,
                          selectedInstance: selectedInstance,
                          depth: 0,
                        );
                      }).toList(),
                    ),
                  ),
          ),

        ],
      ),
    );
  }
}

/// Returns agent entries in declaration order using [order], falling back
/// to the map's native iteration order when [order] is empty.
Iterable<MapEntry<String, dynamic>> _orderedAgentEntries(
  Map<String, dynamic> agents,
  List<String> order,
) {
  if (order.isEmpty) return agents.entries;
  return order
      .where((k) => agents.containsKey(k))
      .map((k) => MapEntry(k, agents[k]!))
      .followedBy(
        agents.entries.where((e) => !order.contains(e.key)),
      );
}

// ── Workspace header row ──

class _WorkspaceHeaderRow extends StatelessWidget {
  const _WorkspaceHeaderRow({
    required this.workspace,
    required this.isSelected,
    required this.runStatus,
    required this.isLoading,
    required this.onTap,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final Workspace workspace;
  final bool isSelected;
  final String? runStatus;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final canStart =
        runStatus == null || runStatus == 'stopped' || runStatus == 'failed';
    final canStop = runStatus == 'running';
    final canRestart = runStatus == 'running';
    final isBusy = isLoading ||
        runStatus == 'stopping' ||
        runStatus == 'starting';

    final dotColor = switch (runStatus) {
      'running' => AppColors.success,
      'starting' || 'stopping' => AppColors.terminalAmber,
      'failed' => AppColors.destructive,
      _ => AppColors.mutedForeground,
    };

    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              _StatusDot(color: dotColor),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  workspace.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                    fontFamily: AppFonts.mono,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Play / Stop
              if (canStop)
                _ActionIconButton(
                  icon: LucideIcons.square,
                  color: isBusy
                      ? AppColors.mutedForeground
                      : AppColors.destructive,
                  tooltip: 'Stop workspace',
                  onPressed: isBusy ? () {} : onStop,
                )
              else
                _ActionIconButton(
                  icon: LucideIcons.play,
                  color: (canStart && !isBusy)
                      ? AppColors.terminalGreen
                      : AppColors.mutedForeground,
                  tooltip: 'Start workspace',
                  onPressed: (canStart && !isBusy) ? onStart : () {},
                ),
              // Restart
              _ActionIconButton(
                icon: LucideIcons.refresh_cw,
                color: (canRestart && !isBusy)
                    ? AppColors.foreground
                    : AppColors.mutedForeground,
                tooltip: 'Restart workspace',
                onPressed: (canRestart && !isBusy) ? onRestart : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recursive agent tree node ──

class _AgentTreeNode extends ConsumerWidget {
  const _AgentTreeNode({
    required this.workspaceId,
    required this.runId,
    required this.isRunning,
    required this.agentKey,
    required this.agentConfig,
    required this.agents,
    required this.selectedInstance,
    required this.depth,
  });

  final String workspaceId;
  final String? runId;
  final bool isRunning;
  final String agentKey;
  final Map<String, dynamic> agentConfig;
  final List<WorkspaceAgent> agents;
  final String? selectedInstance; // instanceId or null
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAgents =
        agentConfig['sub_agents'] as Map<String, dynamic>? ?? {};
    final subAgentOrder =
        (agentConfig['sub_agent_order'] as List<dynamic>?)?.cast<String>() ??
            [];
    final hasSubAgents = subAgents.isNotEmpty;
    final isSubAgent = depth > 0;

    // Show ALL instances for this agent (including disconnected).
    final allInstances = agents
        .where((a) => a.agentKey == agentKey)
        .toList();
    // 0 instances: simple label row
    // 1 instance: inline row with live status + actions (no expand)
    // 2+ instances: expandable group with instance sub-rows
    final isSingleInstance = allInstances.length == 1;
    final showAsExpandable = allInstances.length >= 2;

    // Shared callback for adding an instance.
    Future<void> addInstance() async {
      if (runId == null) return;
      try {
        if (isSubAgent) {
          await ref.read(engineClientProvider).sendCommand('start_sub_instance', {
                'run_id': runId!,
                'parent_instance_id': '', // TODO: resolve parent instance ID
                'agent_key': agentKey,
              });
        } else {
          await ref.read(engineClientProvider).sendCommand('start_root_instance', {
                'run_id': runId!,
                'agent_key': agentKey,
              });
        }
      } catch (e) {
        debugPrint('[start_instance] Failed: $e');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── No instances: simple label row ──
        if (allInstances.isEmpty)
          _AgentRow(
            agentKey: agentKey,
            instanceId: null,
            displayLabel: agentKey,
            status: isSubAgent ? null : null,
            isSelected: false,
            depth: depth,
            isStale: false,
            waitingFor: null,
            onTap: isSubAgent ? null : null,
            trailing: isRunning
                ? _ActionIconButton(
                    icon: LucideIcons.plus,
                    color: AppColors.terminalGreen,
                    tooltip: 'Add instance',
                    onPressed: addInstance,
                  )
                : null,
          ),

        // ── Single instance: inline row with live status + actions ──
        if (isSingleInstance) ...[
          Builder(builder: (context) {
            final a = allInstances.first;
            final isAlive = a.status != AgentState.disconnected;
            return _AgentRow(
              agentKey: agentKey,
              instanceId: a.instanceId,
              displayLabel: agentKey,
              status: a.status,
              isSelected: selectedInstance == a.instanceId,
              depth: depth,
              isStale: !isAlive,
              waitingFor: null,
              onTap: () => ref
                  .read(selectedInstanceProvider(workspaceId).notifier)
                  .state = a.instanceId,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRunning && isAlive && runId != null)
                    _ActionIconButton(
                      icon: LucideIcons.square,
                      color: AppColors.destructive,
                      tooltip: 'Stop instance',
                      onPressed: () async {
                        try {
                          await ref.read(engineClientProvider).sendCommand('stop_instance', {
                                'run_id': runId!,
                                'instance_id': a.instanceId,
                              });
                        } catch (e) {
                          debugPrint('[stop_instance] Failed: $e');
                        }
                      },
                    ),
                  if (isRunning)
                    _ActionIconButton(
                      icon: LucideIcons.plus,
                      color: AppColors.terminalGreen,
                      tooltip: 'Add instance',
                      onPressed: addInstance,
                    ),
                ],
              ),
            );
          }),
        ],

        // ── Multi-instance: expandable group ──
        if (showAsExpandable)
          Collapsible(
            defaultOpen: !isSubAgent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CollapsibleTrigger(
                  child: _AgentGroupRow(
                    agentKey: agentKey,
                    agents: agents,
                    depth: depth,
                    isSubAgent: isSubAgent,
                    onAddInstance: isRunning ? addInstance : null,
                    onCleanupAll: allInstances.any((a) =>
                            a.status == AgentState.disconnected)
                        ? () async {
                            if (runId == null) return;
                            try {
                              await ref.read(engineClientProvider).sendCommand('cleanup_stale_instances', {
                                    'run_id': runId!,
                                  });
                            } catch (e) {
                              debugPrint('[cleanup] Failed: $e');
                            }
                          }
                        : null,
                  ),
                ),
                CollapsibleContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: allInstances.map((a) {
                      final isAlive =
                          a.status != AgentState.disconnected;
                      final isStale = !isAlive;
                      return _AgentRow(
                        agentKey: agentKey,
                        instanceId: a.instanceId,
                        displayLabel: '#${a.displayName}',
                        status: a.status,
                        isSelected: selectedInstance == a.instanceId,
                        depth: depth + 1,
                        isStale: isStale,
                        waitingFor: null,
                        onTap: () => ref
                                .read(selectedInstanceProvider(workspaceId).notifier)
                                .state = a.instanceId,
                        trailing: isRunning && isAlive && runId != null
                            ? _ActionIconButton(
                                icon: LucideIcons.square,
                                color: AppColors.destructive,
                                tooltip: 'Stop instance',
                                onPressed: () async {
                                  try {
                                    await ref.read(engineClientProvider).sendCommand('stop_instance', {
                                          'run_id': runId!,
                                          'instance_id': a.instanceId,
                                        });
                                  } catch (e) {
                                    debugPrint('[stop_instance] Failed: $e');
                                  }
                                },
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        // Sub-agents (recursive, in declaration order)
        if (hasSubAgents)
          ..._orderedAgentEntries(
            subAgents,
            subAgentOrder,
          ).map((entry) {
            final subConfig = entry.value as Map<String, dynamic>;
            return _AgentTreeNode(
              workspaceId: workspaceId,
              runId: runId,
              isRunning: isRunning,
              agentKey: entry.key,
              agentConfig: subConfig,
              agents: agents,
              selectedInstance: selectedInstance,
              depth: depth + 1,
            );
          }),
      ],
    );
  }

}

// ── Single agent row (clickable) ──

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.agentKey,
    required this.instanceId,
    required this.displayLabel,
    required this.status,
    required this.isSelected,
    required this.depth,
    this.onTap,
    this.waitingFor,
    this.isStale = false,
    this.trailing,
  });

  final String agentKey;
  final String? instanceId;
  final String displayLabel;
  final String? status;
  final bool isSelected;
  final int depth;
  final VoidCallback? onTap;
  final String? waitingFor;
  final bool isStale;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasInstance = instanceId != null;

    return Opacity(
      opacity: isStale ? 0.5 : 1.0,
      child: Material(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.08)
            : hasInstance && depth > 0
                ? AppColors.bgDeep
                : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(
              left: Spacing.md + depth * 16.0,
              right: Spacing.sm,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                _StatusDot(color: agentStatusColor(status), status: status),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isStale
                                ? AppColors.mutedForeground
                                : AppColors.foreground,
                            fontFamily: AppFonts.mono,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (waitingFor != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '\u2192 $waitingFor',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                              fontFamily: AppFonts.mono,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (status == AgentState.idle)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(LucideIcons.messages_square,
                        size: 12, color: AppColors.terminalAmber),
                  ),
                if (status == AgentState.waitingForInquiry)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(LucideIcons.bell,
                        size: 12, color: AppColors.terminalAmber),
                  ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Multi-instance group header row ──

class _AgentGroupRow extends StatelessWidget {
  const _AgentGroupRow({
    required this.agentKey,
    required this.agents,
    required this.depth,
    this.isSubAgent = false,
    this.onAddInstance,
    this.onCleanupAll,
  });

  final String agentKey;
  final List<WorkspaceAgent> agents;
  final int depth;
  final bool isSubAgent;
  final VoidCallback? onAddInstance;
  final VoidCallback? onCleanupAll;

  @override
  Widget build(BuildContext context) {
    final allForAgent = agents
        .where((a) => a.agentKey == agentKey)
        .toList();
    final alive = allForAgent
        .where((a) => a.status != AgentState.disconnected)
        .toList();
    final aggregateStatus = _aggregateStatus(alive);
    final hasWaitingInput =
        alive.any((a) => a.status == AgentState.idle);
    final hasWaitingInquiry =
        alive.any((a) => a.status == AgentState.waitingForInquiry);

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.md + depth * 16.0,
        right: Spacing.sm,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        children: [
          _StatusDot(
            color: agentStatusColor(aggregateStatus),
            status: aggregateStatus,
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(
              agentKey,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
                fontFamily: AppFonts.mono,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasWaitingInput && !Collapsible.of(context).isOpen)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(LucideIcons.messages_square,
                  size: 12, color: AppColors.terminalAmber),
            ),
          if (hasWaitingInquiry && !Collapsible.of(context).isOpen)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(LucideIcons.bell,
                  size: 12, color: AppColors.terminalAmber),
            ),
          if (allForAgent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: DspatchBadge(
                label: '${alive.length}/${allForAgent.length}',
                variant: BadgeVariant.secondary,
              ),
            ),
          if (onCleanupAll != null)
            _ActionIconButton(
              icon: LucideIcons.sparkles,
              color: AppColors.mutedForeground,
              tooltip: 'Cleanup all stale instances',
              onPressed: onCleanupAll!,
            ),
          if (onAddInstance != null)
            _ActionIconButton(
              icon: LucideIcons.plus,
              color: AppColors.terminalGreen,
              tooltip: 'Add instance',
              onPressed: onAddInstance!,
            ),
        ],
      ),
    );
  }

  /// Pick the most urgent status among instances.
  static String? _aggregateStatus(List<WorkspaceAgent> instances) {
    if (instances.isEmpty) return null;
    const priority = [
      AgentState.generating,
      AgentState.idle,
      AgentState.waitingForInquiry,
      AgentState.waitingForAgent,
      AgentState.crashed,
      AgentState.failed,
      AgentState.completed,
      AgentState.idle,
      AgentState.disconnected,
    ];
    for (final s in priority) {
      if (instances.any((a) => a.status == s)) return s;
    }
    return instances.first.status;
  }
}

// ── Small action icon button ──

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 14,
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

// ── Pulsating status dot ──

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, this.status});

  final Color color;
  final String? status;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;

  bool get _shouldPulse =>
      widget.status == AgentState.generating ||
      widget.status == AgentState.idle ||
      widget.status == AgentState.waitingForInquiry ||
      widget.status == AgentState.waitingForAgent;

  Duration get _pulseDuration =>
      widget.status == AgentState.generating
          ? const Duration(milliseconds: 1500)
          : const Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (_shouldPulse) {
      _controller.duration = _pulseDuration;
      _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.reset();
      _opacity = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      ),
    );
  }
}
