// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_engine/dspatch_engine.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/config_copy_with.dart';
import '../../../core/utils/agent_map_helpers.dart';
import '../../../core/utils/env_resolver.dart';
import '../../../di/providers.dart';
import '../../agent_providers/models/agent_list_item.dart';
import 'agent_config_editor.dart';
import 'docker_settings_editor.dart';
import 'env_var_editor.dart';
import 'mount_editor.dart';

/// Main visual form for workspace configuration.
///
/// Composes all sub-editors (agents, mounts, docker settings) and
/// propagates changes upward via [onChanged].
class WorkspaceVisualEditor extends ConsumerStatefulWidget {
  const WorkspaceVisualEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final WorkspaceConfig config;
  final ValueChanged<WorkspaceConfig> onChanged;

  @override
  ConsumerState<WorkspaceVisualEditor> createState() =>
      _WorkspaceVisualEditorState();
}

class _WorkspaceVisualEditorState
    extends ConsumerState<WorkspaceVisualEditor> {
  late TextEditingController _nameCtl;
  late TextEditingController _workspaceDirCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.config.name);
    _workspaceDirCtl =
        TextEditingController(text: widget.config.workspaceDir ?? '');
  }

  @override
  void didUpdateWidget(WorkspaceVisualEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.name != widget.config.name &&
        _nameCtl.text != widget.config.name) {
      final name = widget.config.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _nameCtl.text != name) _nameCtl.text = name;
      });
    }
    final dir = widget.config.workspaceDir ?? '';
    if (oldWidget.config.workspaceDir != widget.config.workspaceDir &&
        _workspaceDirCtl.text != dir) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _workspaceDirCtl.text != dir) {
          _workspaceDirCtl.text = dir;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _workspaceDirCtl.dispose();
    super.dispose();
  }

  void _emit(WorkspaceConfig updated) => widget.onChanged(updated);

  // ── Agent helpers ──

  void _addAgent() {
    final agents = AgentMapHelpers.addAgent(widget.config.agents);
    _emit(widget.config.copyWith(agents: agents));
  }

  void _removeAgent(String key) {
    final agents = AgentMapHelpers.removeAgent(widget.config.agents, key);
    _emit(widget.config.copyWith(agents: agents));
  }

  void _renameAgent(String oldKey, String newKey) {
    final agents =
        AgentMapHelpers.renameAgent(widget.config.agents, oldKey, newKey);
    if (identical(agents, widget.config.agents)) return;
    _emit(widget.config.copyWith(agents: agents));
  }

  void _updateAgent(String key, AgentConfig config) {
    final agents = Map<String, AgentConfig>.of(widget.config.agents);
    final oldTemplate = agents[key]?.template;
    agents[key] = config;

    var updatedConfig = widget.config.copyWith(agents: agents);

    // When the template changes, auto-add its required env keys to the
    // workspace-level global env and required mounts to workspace mounts.
    if (config.template != oldTemplate && config.template.isNotEmpty) {
      final items =
          ref.read(agentListItemsProvider).valueOrNull ?? <AgentListItem>[];
      final item =
          items.where((t) => t.name == config.template).firstOrNull;
      final provider = item?.provider;
      if (provider != null) {
        // Auto-add required env keys to global env.
        if (provider.requiredEnv.isNotEmpty) {
          final env = Map<String, String>.of(updatedConfig.env);
          for (final envKey in provider.requiredEnv) {
            env.putIfAbsent(envKey, () => '');
          }
          updatedConfig = updatedConfig.copyWith(env: env);
        }

        // Auto-add required mounts.
        if (provider.requiredMounts.isNotEmpty) {
          final mounts = List<MountConfig>.of(updatedConfig.mounts);
          final existingPaths = mounts.map((m) => m.containerPath).toSet();
          for (final path in provider.requiredMounts) {
            if (path.isNotEmpty && !existingPaths.contains(path)) {
              mounts.add(MountConfig(hostPath: '', containerPath: path, readOnly: true));
            }
          }
          updatedConfig = updatedConfig.copyWith(mounts: mounts);
        }
      }
    }

    _emit(updatedConfig);
  }

  /// Union of all required env keys across templates used by agents.
  Set<String> _allRequiredKeys(List<AgentListItem> items) {
    final templateRequiredEnv = <String, List<String>>{};
    for (final item in items) {
      if (item.provider != null) {
        templateRequiredEnv[item.name] = item.provider!.requiredEnv;
      }
    }
    return EnvResolver.collectAllRequiredKeys(
      widget.config.agents,
      templateRequiredEnv,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(agentListItemsProvider);
    final agentItems = itemsAsync.valueOrNull ?? <AgentListItem>[];
    final config = widget.config;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Workspace Name + Directory ──
          _sectionCard(
            title: 'Workspace',
            description: 'Basic workspace configuration.',
            child: Column(
              children: [
                Field(
                  label: 'Workspace Directory',
                  required: true,
                  description:
                      'This directory is mounted as /workspace (read-write) '
                      'inside the container. dspatch.workspace.yml will be saved here.',
                  child: DirectoryPickerInput(
                    controller: _workspaceDirCtl,
                    placeholder: '/path/to/project',
                    dialogTitle: 'Select Workspace Directory',
                    buttonStyle: DirectoryPickerButtonStyle.primary,
                    onChanged: (val) =>
                        _emit(config.copyWith(workspaceDir: val.trim())),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Field(
                  label: 'Name',
                  required: true,
                  child: Input(
                    controller: _nameCtl,
                    placeholder: 'my-workspace',
                    onChanged: (val) =>
                        _emit(config.copyWith(name: val.trim())),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── 2. Environment Variables (global) ──
          _sectionCard(
            title: 'Environment Variables',
            description:
                'Global env vars shared across all agents. '
                'Templates declare required keys — only those are forwarded.',
            child: EnvVarEditor(
              env: config.env,
              requiredKeys: _allRequiredKeys(agentItems).toList(),
              onChanged: (env) => _emit(config.copyWith(env: env)),
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── 3. Agents ──
          _sectionCard(
            title: 'Agents',
            description:
                'Configure the agent hierarchy. Each agent references '
                'a template and can have environment variables and peers.',
            trailing: Button(
              label: 'Add Agent',
              icon: LucideIcons.plus,
              variant: ButtonVariant.outline,
              size: ButtonSize.sm,
              onPressed: _addAgent,
            ),
            child: config.agents.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: LucideIcons.user_plus,
                    title: 'No agents',
                    description: 'Add an agent to get started.',
                  )
                : Accordion(
                    type: AccordionType.multiple,
                    defaultValue: {config.agents.keys.first},
                    children: config.agents.entries.map((entry) {
                      final siblingKeys = config.agents.keys
                          .where((k) => k != entry.key)
                          .toList();
                      return AccordionItem(
                        value: entry.key,
                        title:
                            '${entry.key}  ·  ${entry.value.template.isEmpty ? "(no template)" : entry.value.template}',
                        content: AgentConfigEditor(
                          agentKey: entry.key,
                          agentConfig: entry.value,
                          siblingKeys: siblingKeys,
                          templates: agentItems,
                          onKeyChanged: (newKey) =>
                              _renameAgent(entry.key, newKey),
                          onConfigChanged: (cfg) =>
                              _updateAgent(entry.key, cfg),
                          onRemove: () => _removeAgent(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── 4. Additional Mounts ──
          _sectionCard(
            title: 'Additional Mounts',
            description:
                'Extra directories or files to bind-mount into containers. '
                'The workspace directory is always mounted at /workspace.',
            child: MountEditor(
              mounts: config.mounts,
              onChanged: (mounts) =>
                  _emit(config.copyWith(mounts: mounts)),
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── 5. Docker Settings ──
          _sectionCard(
            title: 'Docker Settings',
            description:
                'Container resource limits and networking. '
                'Leave empty for Docker defaults.',
            child: DockerSettingsEditor(
              docker: config.docker,
              onChanged: (docker) =>
                  _emit(config.copyWith(docker: docker)),
            ),
          ),

          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? description,
    Widget? trailing,
    required Widget child,
  }) {
    return DspatchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle(text: title),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: CardDescription(text: description),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          CardContent(child: child),
        ],
      ),
    );
  }
}
