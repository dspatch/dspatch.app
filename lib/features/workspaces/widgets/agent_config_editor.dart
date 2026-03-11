// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/config_copy_with.dart';
import '../../../core/utils/agent_map_helpers.dart';
import '../../agent_providers/models/agent_list_item.dart';
import 'env_var_editor.dart';

/// Per-agent configuration form within the visual workspace editor.
///
/// Shows template selection, environment variables, peer connections,
/// and recursive sub-agents.
class AgentConfigEditor extends StatefulWidget {
  const AgentConfigEditor({
    super.key,
    required this.agentKey,
    required this.agentConfig,
    this.siblingKeys = const [],
    this.templates = const [],
    required this.onKeyChanged,
    required this.onConfigChanged,
    required this.onRemove,
    this.depth = 0,
  });

  final String agentKey;
  final AgentConfig agentConfig;
  final List<String> siblingKeys;
  final List<AgentListItem> templates;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<AgentConfig> onConfigChanged;
  final VoidCallback onRemove;

  final int depth;

  @override
  State<AgentConfigEditor> createState() => _AgentConfigEditorState();
}

class _AgentConfigEditorState extends State<AgentConfigEditor> {
  late final TextEditingController _keyCtl;

  @override
  void initState() {
    super.initState();
    _keyCtl = TextEditingController(text: widget.agentKey);
  }

  @override
  void didUpdateWidget(AgentConfigEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agentKey != widget.agentKey &&
        _keyCtl.text != widget.agentKey) {
      final key = widget.agentKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _keyCtl.text != key) _keyCtl.text = key;
      });
    }
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    super.dispose();
  }

  void _emit(AgentConfig updated) => widget.onConfigChanged(updated);

  /// Look up the selected template's required env keys.
  List<String> get _requiredKeys {
    final selected = widget.templates
        .where((t) => t.name == widget.agentConfig.template)
        .firstOrNull;
    if (selected == null) return [];
    if (selected.provider != null) return selected.provider!.requiredEnv;
    return []; // templates store config in YAML, no direct requiredEnv
  }

  // ── Sub-agent helpers ──

  void _addSubAgent() {
    final subAgents = AgentMapHelpers.addAgent(
      widget.agentConfig.subAgents,
      prefix: 'sub-agent',
    );
    _emit(widget.agentConfig.copyWith(subAgents: subAgents));
  }

  void _removeSubAgent(String key) {
    final subAgents = AgentMapHelpers.removeAgent(
      widget.agentConfig.subAgents,
      key,
    );
    _emit(widget.agentConfig.copyWith(subAgents: subAgents));
  }

  void _updateSubAgentKey(String oldKey, String newKey) {
    final subAgents = AgentMapHelpers.renameAgent(
      widget.agentConfig.subAgents,
      oldKey,
      newKey,
    );
    if (identical(subAgents, widget.agentConfig.subAgents)) return;
    _emit(widget.agentConfig.copyWith(subAgents: subAgents));
  }

  void _updateSubAgentConfig(String key, AgentConfig config) {
    final subAgents = Map<String, AgentConfig>.of(
        widget.agentConfig.subAgents);
    subAgents[key] = config;
    _emit(widget.agentConfig.copyWith(subAgents: subAgents));
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agentConfig;

    return Container(
      padding: const EdgeInsets.only(
        top: Spacing.md,
        left: Spacing.md,
        bottom: Spacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: Agent key + remove ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Field(
                label: 'Agent Key',
                child: Input(
                  controller: _keyCtl,
                  placeholder: 'lead',
                  onChanged: (val) => widget.onKeyChanged(val.trim()),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: DspatchIconButton(
                icon: LucideIcons.trash_2,
                variant: IconButtonVariant.ghost,
                size: IconButtonSize.md,
                tooltip: 'Remove agent',
                onPressed: widget.onRemove,
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacing.md),

        // ── Template dropdown ──
        Field(
          label: 'Template',
          child: Row(
            children: [
              Expanded(
                child: widget.templates.isEmpty
                    ? const Text(
                        'No templates available — create one first',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Select<String>(
                        value: agent.template.isEmpty
                            ? null
                            : agent.template,
                        hint: 'Select template...',
                        items: widget.templates
                            .map((t) => SelectItem(
                                value: t.name, label: t.name))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _emit(agent.copyWith(template: val));
                          }
                        },
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacing.md),

        // ── Auto-start ──
        //
        // Controls whether the engine starts an instance automatically
        // when the host connects. Defaults to true for root agents
        // (depth == 0) and false for sub-agents.
        Row(
          children: [
            DspatchCheckbox(
              value: agent.autoStart ?? (widget.depth == 0),
              onChanged: (val) =>
                  _emit(agent.copyWith(autoStart: val)),
            ),
            const SizedBox(width: Spacing.xs),
            const Text(
              'Auto-start',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(width: Spacing.xs),
            Tooltip(
              message: widget.depth == 0
                  ? 'Engine starts this agent automatically when the workspace connects'
                  : 'Sub-agents are normally started on demand (via talk_to). '
                    'Enable to auto-start on workspace connect.',
              child: const Icon(
                LucideIcons.info,
                size: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacing.md),

        // ── Env Overrides (collapsible) ──
        Collapsible(
          defaultOpen: agent.env.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollapsibleTrigger(
                child: _sectionHeader(
                  'Env Overrides',
                  count: agent.env.length,
                ),
              ),
              CollapsibleContent(
                child: Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: EnvVarEditor(
                    env: agent.env,
                    requiredKeys: _requiredKeys,
                    addButtonLabel: 'Add Override',
                    hintText: 'Override a global env var for this agent',
                    onChanged: (env) => _emit(agent.copyWith(env: env)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacing.sm),

        // ── Peers (collapsible) ──
        if (widget.siblingKeys.isNotEmpty)
          Collapsible(
            defaultOpen: agent.peers.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CollapsibleTrigger(
                  child: _sectionHeader(
                    'Peers',
                    count: agent.peers.length,
                  ),
                ),
                CollapsibleContent(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: Wrap(
                      spacing: Spacing.md,
                      runSpacing: Spacing.xs,
                      children: widget.siblingKeys.map((key) {
                        final selected = agent.peers.contains(key);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DspatchCheckbox(
                              value: selected,
                              onChanged: (val) {
                                final peers = List<String>.of(agent.peers);
                                if (val == true) {
                                  peers.add(key);
                                } else {
                                  peers.remove(key);
                                }
                                _emit(agent.copyWith(peers: peers));
                              },
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              key,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.foreground,
                                fontFamily: AppFonts.mono,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Sub-Agents (collapsible, max depth 3) ──
        if (widget.depth < 3) ...[
          const SizedBox(height: Spacing.sm),
          Collapsible(
            defaultOpen: agent.subAgents.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CollapsibleTrigger(
                  child: _sectionHeader(
                    'Sub-Agents',
                    count: agent.subAgents.length,
                  ),
                ),
                CollapsibleContent(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: Spacing.sm, left: Spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...agent.subAgents.entries.map((entry) {
                          final subKeys = agent.subAgents.keys
                              .where((k) => k != entry.key)
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: Spacing.md),
                            child: Container(
                              padding: const EdgeInsets.all(Spacing.sm),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: AppColors.border),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: AgentConfigEditor(
                                agentKey: entry.key,
                                agentConfig: entry.value,
                                siblingKeys: subKeys,
                                templates: widget.templates,
                                onKeyChanged: (newKey) =>
                                    _updateSubAgentKey(entry.key, newKey),
                                onConfigChanged: (config) =>
                                    _updateSubAgentConfig(
                                        entry.key, config),
                                onRemove: () =>
                                    _removeSubAgent(entry.key),
                                depth: widget.depth + 1,
                              ),
                            ),
                          );
                        }),
                        Button(
                          label: 'Add Sub-Agent',
                          icon: LucideIcons.plus,
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          onPressed: _addSubAgent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
    );
  }

  Widget _sectionHeader(String title, {int count = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: Spacing.xs),
            DspatchBadge(
              label: '$count',
              variant: BadgeVariant.secondary,
            ),
          ],
          const Spacer(),
          const Icon(
            LucideIcons.chevron_right,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
