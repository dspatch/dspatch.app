// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../../../core/extensions/agent_state_ext.dart';
import '../../../../core/utils/datetime_ext.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/engine_database.dart';
import '../../../../di/providers.dart';
import '../../../../models/commands/commands.dart';
import '../../../../models/docker_types.dart';
import '../workspace_run_history_dialog.dart';

/// Workspace metadata, runtime info, agent summary, and Docker container stats.
class WorkspaceInfoTab extends ConsumerWidget {
  const WorkspaceInfoTab({
    super.key,
    required this.runId,
    required this.workspace,
    required this.agents,
  });

  final String runId;
  final Workspace workspace;
  final List<WorkspaceAgent> agents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running =
        agents.where((a) => a.status == AgentState.generating).length;
    final disconnected = agents
        .where((a) =>
            a.status == AgentState.disconnected ||
            a.status == AgentState.idle)
        .length;
    final waiting = agents.where((a) => a.status.isWaiting).length;
    final terminal = agents.where((a) => a.status.isTerminal).length;

    // Docker container stats — get containerId from active run
    final activeRun = ref.watch(activeRunProvider(workspace.id));
    final containerId = activeRun?.containerId;

    // Workspace config from dspatch.workspace.yml
    final configAsync =
        ref.watch(workspaceConfigProvider(workspace.projectPath));
    final config = configAsync.valueOrNull;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.all(Spacing.md),
      child: ContentArea(
        alignment: Alignment.topLeft,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // ── Workspace ──
          const _SectionLabel('Workspace'),
          _KV('ID', workspace.id),
          _KV('Name', workspace.name),
          _KV('Status', activeRun?.status ?? 'idle'),
          _KV('Project path', workspace.projectPath),
          _KV('Created', parseDate(workspace.createdAt).formatted()),
          _KV('Updated', parseDate(workspace.updatedAt).formatted()),

          const SizedBox(height: Spacing.md),

          // ── Run History ──
          const _SectionLabel('Run History'),
          Builder(builder: (context) {
            final activeRun =
                ref.watch(activeRunProvider(workspace.id));
            if (activeRun != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KV('Current run', 'Run #${activeRun.runNumber}'),
                  _KV('Started', parseDate(activeRun.startedAt).formatted()),
                  _KV('Status', activeRun.status),
                  const SizedBox(height: Spacing.sm),
                  Button(
                    label: 'View Run History',
                    icon: LucideIcons.history,
                    size: ButtonSize.sm,
                    variant: ButtonVariant.outline,
                    onPressed: () => WorkspaceRunHistoryDialog.show(
                        context, workspace.id),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _EmptyHint('No active run'),
                const SizedBox(height: Spacing.sm),
                Button(
                  label: 'View Run History',
                  icon: LucideIcons.history,
                  size: ButtonSize.sm,
                  variant: ButtonVariant.outline,
                  onPressed: () => WorkspaceRunHistoryDialog.show(
                      context, workspace.id),
                ),
              ],
            );
          }),

          const SizedBox(height: Spacing.md),

          // ── Runtime ──
          const _SectionLabel('Runtime'),
          _KV('Container', containerId ?? '\u2014'),
          _KV('Port', activeRun?.serverPort?.toString() ?? '\u2014'),

          const SizedBox(height: Spacing.md),

          // ── Docker Container Stats ──
          const _SectionLabel('Container Resources'),
          if (containerId == null)
            const Padding(
              padding: EdgeInsets.only(bottom: Spacing.sm),
              child: Text(
                'No container running',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            )
          else
            FutureBuilder<ContainerStats>(
              future: ref.read(engineClientProvider).send(GetContainerStats(
                    runId: containerId,
                  )),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: Spacing.sm),
                    child: Spinner(size: SpinnerSize.sm),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Text(
                      'Stats unavailable',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                final stats = snapshot.data!;
                final memUsageMB = (stats.memoryUsage / 1024 / 1024).toStringAsFixed(1);
                final memLimitMB = (stats.memoryLimit / 1024 / 1024).toStringAsFixed(1);
                final netRxKB = (stats.networkRx / 1024).toStringAsFixed(1);
                final netTxKB = (stats.networkTx / 1024).toStringAsFixed(1);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KV('CPU', '${stats.cpuPercent.toStringAsFixed(1)}%'),
                    _KV('Memory', '${memUsageMB}MB / ${memLimitMB}MB'),
                    _KV('Network I/O', '${netRxKB}KB / ${netTxKB}KB'),
                  ],
                );
              },
            ),

          const SizedBox(height: Spacing.md),

          // ── Config: Environment Variables ──
          if (config != null) ...[
            const _SectionLabel('Environment Variables'),
            ..._buildConfigEnvSection(config),

            const SizedBox(height: Spacing.md),

            // ── Config: Workspace Directory ──
            const _SectionLabel('Workspace Directory'),
            _KV('workspace_dir', config['workspace_dir'] as String? ?? '(project directory)'),

            const SizedBox(height: Spacing.md),

            // ── Config: Mounts ──
            const _SectionLabel('Mounts'),
            ..._buildConfigMountsSection(config),

            const SizedBox(height: Spacing.md),

            // ── Config: Docker ──
            const _SectionLabel('Docker'),
            ..._buildConfigDockerSection(config),

            const SizedBox(height: Spacing.md),

            // ── Config: Agents ──
            const _SectionLabel('Agent Configuration'),
            ..._buildConfigAgentsSection(config),
          ] else if (configAsync.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: Spacing.sm),
              child: Row(
                children: [
                  Spinner(size: SpinnerSize.sm),
                  SizedBox(width: Spacing.xs),
                  Text(
                    'Loading config...',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else if (configAsync.hasError)
            const _EmptyHint('Failed to load dspatch.workspace.yml'),

          const SizedBox(height: Spacing.md),

          // ── Agents (runtime) ──
          const _SectionLabel('Agents (Runtime)'),
          _KV('Total', '${agents.length}'),
          if (agents.isNotEmpty) ...[
            _KV('Running', '$running'),
            _KV('Disconnected', '$disconnected'),
            if (waiting > 0) _KV('Waiting', '$waiting'),
            if (terminal > 0) _KV('Terminal', '$terminal'),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.xs,
              runSpacing: Spacing.xs,
              children: [
                for (final a in agents)
                  DspatchBadge(
                    label: '${a.agentKey} (${a.status})',
                    variant: _statusVariant(a.status),
                  ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  List<Widget> _buildConfigEnvSection(Map<String, dynamic> config) {
    final env = config['env'] as Map<String, dynamic>? ?? {};
    if (env.isEmpty) return [const _EmptyHint('No global env vars configured')];
    return env.entries
        .map((entry) => _KV(entry.key, entry.value.toString()))
        .toList();
  }

  List<Widget> _buildConfigMountsSection(Map<String, dynamic> config) {
    final mounts = config['mounts'] as List<dynamic>? ?? [];
    if (mounts.isEmpty) return [const _EmptyHint('No additional mounts')];
    final widgets = <Widget>[];
    for (final m in mounts) {
      final mount = m as Map<String, dynamic>;
      widgets.add(_KV('Host', mount['host_path'] as String? ?? ''));
      widgets.add(_KV('Container', mount['container_path'] as String? ?? ''));
      widgets.add(_KV('Read-only', (mount['read_only'] as bool? ?? false) ? 'yes' : 'no'));
      widgets.add(const SizedBox(height: Spacing.xs));
    }
    return widgets;
  }

  List<Widget> _buildConfigDockerSection(Map<String, dynamic> config) {
    final docker = config['docker'] as Map<String, dynamic>? ?? {};
    final ports = (docker['ports'] as List<dynamic>?)?.cast<String>() ?? [];
    return [
      _KV('Memory limit', docker['memory_limit'] as String? ?? 'default'),
      _KV('CPU limit', docker['cpu_limit']?.toString() ?? 'default'),
      _KV('Network mode', docker['network_mode'] as String? ?? 'host'),
      if (ports.isNotEmpty) _KV('Ports', ports.join(', ')),
      _KV('GPU', (docker['gpu'] as bool? ?? false) ? 'enabled' : 'disabled'),
    ];
  }

  List<Widget> _buildConfigAgentsSection(Map<String, dynamic> config) {
    final configAgents = config['agents'] as Map<String, dynamic>? ?? {};
    if (configAgents.isEmpty) {
      return [const _EmptyHint('No agents configured')];
    }
    return configAgents.entries
        .map((entry) => _AgentConfigBlock(
            name: entry.key, config: entry.value as Map<String, dynamic>))
        .toList();
  }

  BadgeVariant _statusVariant(String s) {
    return switch (s) {
      AgentState.disconnected => BadgeVariant.secondary,
      AgentState.idle => BadgeVariant.secondary,
      AgentState.generating => BadgeVariant.success,
      AgentState.waitingForInquiry => BadgeVariant.warning,
      AgentState.waitingForAgent => BadgeVariant.warning,
      AgentState.completed => BadgeVariant.primary,
      AgentState.failed => BadgeVariant.destructive,
      AgentState.crashed => BadgeVariant.destructive,
      _ => BadgeVariant.secondary,
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 12,
                fontFamily: AppFonts.mono,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AgentConfigBlock extends StatelessWidget {
  const _AgentConfigBlock({required this.name, required this.config});
  final String name;
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final template = config['template'] as String? ?? '';
    final env = config['env'] as Map<String, dynamic>? ?? {};
    final peers = (config['peers'] as List<dynamic>?)?.cast<String>() ?? [];
    final subAgents = config['sub_agents'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.mono,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KV('Template', template),
                if (env.isNotEmpty)
                  _KV('Env', env.entries
                      .map((e) => '${e.key}=${e.value}')
                      .join(', ')),
                if (peers.isNotEmpty)
                  _KV('Peers', peers.join(', ')),
                for (final sub in subAgents.entries)
                  _AgentConfigBlock(
                      name: sub.key, config: sub.value as Map<String, dynamic>),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
