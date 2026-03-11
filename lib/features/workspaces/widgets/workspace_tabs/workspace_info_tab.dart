// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import '../../../../core/extensions/agent_state_ext.dart';
import '../../../../core/utils/datetime_ext.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/providers.dart';
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
          _KV('Created', workspace.createdAt.formatted()),
          _KV('Updated', workspace.updatedAt.formatted()),

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
                  _KV('Started', activeRun.startedAt.formatted()),
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
              future: ref.read(sdkProvider).containerStats(
                    containerId: containerId,
                  ),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KV('CPU', stats.cpuPerc),
                    _KV('Memory', stats.memUsage),
                    _KV('Network I/O', stats.netIo),
                    _KV('Block I/O', stats.blockIo),
                    _KV('PIDs', stats.pids),
                  ],
                );
              },
            ),

          const SizedBox(height: Spacing.md),

          // ── Config: Environment Variables ──
          if (config != null) ...[
            const _SectionLabel('Environment Variables'),
            if (config.env.isEmpty)
              const _EmptyHint('No global env vars configured')
            else
              for (final entry in config.env.entries)
                _KV(entry.key, entry.value),

            const SizedBox(height: Spacing.md),

            // ── Config: Workspace Directory ──
            const _SectionLabel('Workspace Directory'),
            _KV('workspace_dir', config.workspaceDir ?? '(project directory)'),

            const SizedBox(height: Spacing.md),

            // ── Config: Mounts ──
            const _SectionLabel('Mounts'),
            if (config.mounts.isEmpty)
              const _EmptyHint('No additional mounts')
            else
              for (final m in config.mounts) ...[
                _KV('Host', m.hostPath),
                _KV('Container', m.containerPath),
                _KV('Read-only', m.readOnly ? 'yes' : 'no'),
                const SizedBox(height: Spacing.xs),
              ],

            const SizedBox(height: Spacing.md),

            // ── Config: Docker ──
            const _SectionLabel('Docker'),
            _KV('Memory limit',
                config.docker.memoryLimit ?? 'default'),
            _KV('CPU limit',
                config.docker.cpuLimit?.toString() ?? 'default'),
            _KV('Network mode', config.docker.networkMode),
            if (config.docker.ports.isNotEmpty)
              _KV('Ports', config.docker.ports.join(', ')),
            _KV('GPU', config.docker.gpu ? 'enabled' : 'disabled'),

            const SizedBox(height: Spacing.md),

            // ── Config: Agents ──
            const _SectionLabel('Agent Configuration'),
            if (config.agents.isEmpty)
              const _EmptyHint('No agents configured')
            else
              for (final entry in config.agents.entries)
                _AgentConfigBlock(name: entry.key, config: entry.value),
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
                    label: '${a.agentKey} (${a.status.name})',
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

  BadgeVariant _statusVariant(AgentState s) {
    return switch (s) {
      AgentState.disconnected => BadgeVariant.secondary,
      AgentState.idle => BadgeVariant.secondary,
      AgentState.generating => BadgeVariant.success,
      AgentState.waitingForInquiry => BadgeVariant.warning,
      AgentState.waitingForAgent => BadgeVariant.warning,
      AgentState.completed => BadgeVariant.primary,
      AgentState.failed => BadgeVariant.destructive,
      AgentState.crashed => BadgeVariant.destructive,
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
  final AgentConfig config;

  @override
  Widget build(BuildContext context) {
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
                _KV('Template', config.template),
                if (config.env.isNotEmpty)
                  _KV('Env', config.env.entries
                      .map((e) => '${e.key}=${e.value}')
                      .join(', ')),
                if (config.peers.isNotEmpty)
                  _KV('Peers', config.peers.join(', ')),
                for (final sub in config.subAgents.entries)
                  _AgentConfigBlock(name: sub.key, config: sub.value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
