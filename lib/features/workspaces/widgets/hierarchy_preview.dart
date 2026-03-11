// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';


/// Tree visualization of agents parsed from workspace JSON config.
///
/// Shows each agent with its template name, instance count, peer connections,
/// and template resolution status. Also displays workspace directory,
/// additional mounts, and Docker configuration summaries.
class HierarchyPreview extends StatelessWidget {
  const HierarchyPreview({
    super.key,
    this.config,
    this.parseError,
  });

  final WorkspaceConfig? config;
  final String? parseError;

  @override
  Widget build(BuildContext context) {
    // Count agents (including sub-agents recursively).
    int agentCount = 0;
    void countAgents(Map<String, AgentConfig> agents) {
      for (final a in agents.values) {
        agentCount++;
        countAgents(a.subAgents);
      }
    }

    if (config != null) countAgents(config!.agents);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                const Icon(LucideIcons.git_branch,
                    size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: Spacing.xs),
                const Text(
                  'Workspace Preview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const Spacer(),
                if (config != null && agentCount > 0)
                  DspatchBadge(
                    icon: LucideIcons.user,
                    label:
                        '$agentCount agent${agentCount > 1 ? 's' : ''}',
                    variant: BadgeVariant.outline,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Error state: unparseable JSON
    if (parseError != null) {
      return EmptyState(
        compact: true,
        icon: LucideIcons.circle_alert,
        title: 'Invalid JSON',
        description: parseError,
      );
    }

    // No config yet (initial state)
    if (config == null) {
      return const EmptyState(
        compact: true,
        icon: LucideIcons.code,
        title: 'No configuration',
        description: 'Enter JSON to see the workspace preview.',
      );
    }

    // Empty agents map
    if (config!.agents.isEmpty) {
      return const EmptyState(
        compact: true,
        icon: LucideIcons.git_branch,
        title: 'No agents defined',
        description: 'Add agents to the configuration.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workspace name header
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Row(
              children: [
                const Icon(LucideIcons.folder,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: Spacing.xs),
                Text(
                  config!.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          // Global env summary
          if (config!.env.isNotEmpty) ...[
            _ConfigSection(
              icon: LucideIcons.key,
              title: 'Global Env',
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: config!.env.entries.map((e) {
                  final isApiKey =
                      e.value.contains(RegExp(r'\{\{apikey:'));
                  return DspatchBadge(
                    label: isApiKey ? '${e.key} (API Key)' : e.key,
                    variant: isApiKey
                        ? BadgeVariant.primary
                        : BadgeVariant.outline,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: Spacing.sm),
          ],
          // Agent nodes
          ...config!.agents.entries.map(
            (entry) => _AgentNode(
              agentKey: entry.key,
              agentConfig: entry.value,
              depth: 0,
              globalEnv: config!.env,
            ),
          ),

          const SizedBox(height: Spacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: Spacing.md),

          // ── Workspace Directory ──
          _ConfigSection(
            icon: LucideIcons.folder_open,
            title: 'Workspace Directory',
            child: config!.workspaceDir?.isNotEmpty == true
                ? Text(
                    config!.workspaceDir!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground,
                      fontFamily: AppFonts.mono,
                    ),
                  )
                : const Text(
                    'Not set (will use project directory)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),

          // ── Additional Mounts ──
          if (config!.mounts.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            _ConfigSection(
              icon: LucideIcons.file_output,
              title: 'Additional Mounts',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: config!.mounts.map((mount) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${mount.hostPath} \u2192 ${mount.containerPath}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.foreground,
                              fontFamily: AppFonts.mono,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        DspatchBadge(
                          label: mount.readOnly ? 'RO' : 'RW',
                          variant: mount.readOnly
                              ? BadgeVariant.secondary
                              : BadgeVariant.primary,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Docker Settings ──
          if (_hasDockerSettings()) ...[
            const SizedBox(height: Spacing.sm),
            _ConfigSection(
              icon: LucideIcons.settings,
              title: 'Docker Settings',
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _buildDockerBadges(),
              ),
            ),
          ],

          // ── Environment Help ──
          const SizedBox(height: Spacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: Spacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
            child: Text(
              'Tip: Use {{apikey:KeyName}} in env values to inject '
              'API keys stored in Settings \u2192 API Keys.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasDockerSettings() {
    if (config == null) return false;
    final d = config!.docker;
    return d.memoryLimit != null ||
        d.cpuLimit != null ||
        (d.networkMode.isNotEmpty && d.networkMode != 'host') ||
        d.ports.isNotEmpty ||
        d.gpu;
  }

  List<Widget> _buildDockerBadges() {
    final d = config!.docker;
    final badges = <Widget>[];
    if (d.memoryLimit != null) {
      badges.add(DspatchBadge(
        label: 'Memory: ${d.memoryLimit}',
        variant: BadgeVariant.outline,
      ));
    }
    if (d.cpuLimit != null) {
      badges.add(DspatchBadge(
        label: 'CPU: ${d.cpuLimit}',
        variant: BadgeVariant.outline,
      ));
    }
    if (d.networkMode.isNotEmpty && d.networkMode != 'host') {
      badges.add(DspatchBadge(
        label: 'Net: ${d.networkMode}',
        variant: BadgeVariant.outline,
      ));
    }
    for (final port in d.ports) {
      badges.add(DspatchBadge(
        label: 'Port: $port',
        variant: BadgeVariant.outline,
      ));
    }
    if (d.gpu) {
      badges.add(const DspatchBadge(
        label: 'GPU',
        variant: BadgeVariant.primary,
      ));
    }
    return badges;
  }
}

// ── Config Section Helper ──

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.mutedForeground),
            const SizedBox(width: Spacing.xs),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: child,
        ),
      ],
    );
  }
}

// ── Agent Node ──

class _AgentNode extends StatelessWidget {
  const _AgentNode({
    required this.agentKey,
    required this.agentConfig,
    required this.depth,
    this.globalEnv = const {},
  });

  final String agentKey;
  final AgentConfig agentConfig;
  final int depth;
  final Map<String, String> globalEnv;

  @override
  Widget build(BuildContext context) {
    final hasSubAgents = agentConfig.subAgents.isNotEmpty;

    final nodeContent = Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main agent row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                // Agent key
                Text(
                  agentKey,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                    fontFamily: AppFonts.mono,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                // Template name
                Flexible(
                  child: Text(
                    agentConfig.template,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      fontFamily: AppFonts.mono,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Environment variable overrides
          if (agentConfig.env.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: agentConfig.env.entries.map((e) {
                  final isOverride = globalEnv.containsKey(e.key);
                  final isApiKey = e.value.contains(RegExp(r'\{\{apikey:'));
                  final label = isOverride
                      ? '${e.key} (override)'
                      : isApiKey
                          ? '${e.key} (API Key)'
                          : e.key;
                  final variant = isOverride
                      ? BadgeVariant.warning
                      : isApiKey
                          ? BadgeVariant.primary
                          : BadgeVariant.outline;
                  return DspatchBadge(label: label, variant: variant);
                }).toList(),
              ),
            ),
          // Peer connections
          if (agentConfig.peers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  Icon(LucideIcons.link, size: 12, color: AppColors.mutedForeground),
                  ...agentConfig.peers.map(
                    (peer) => Text(
                      peer,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Template resolution warnings will be re-added once the Rust SDK
          // exposes the template resolver via the bridge.
        ],
      ),
    );

    if (!hasSubAgents) return nodeContent;

    // Collapsible sub-agents
    return Collapsible(
      defaultOpen: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollapsibleTrigger(child: nodeContent),
          CollapsibleContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: agentConfig.subAgents.entries
                  .map(
                    (entry) => _AgentNode(
                      agentKey: entry.key,
                      agentConfig: entry.value,
                      depth: depth + 1,
                      globalEnv: globalEnv,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
