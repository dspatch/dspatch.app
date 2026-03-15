// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../models/workspace_config.dart';
import 'dart:io';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/debouncer.dart';
import '../../di/providers.dart';
import 'workspace_controller.dart';
import 'widgets/hierarchy_preview.dart';
import 'widgets/json_editor.dart';
import 'widgets/workspace_visual_editor.dart';

class WorkspaceCreateScreen extends ConsumerStatefulWidget {
  const WorkspaceCreateScreen({super.key});

  @override
  ConsumerState<WorkspaceCreateScreen> createState() =>
      _WorkspaceCreateScreenState();
}

class _WorkspaceCreateScreenState
    extends ConsumerState<WorkspaceCreateScreen> {
  static const _defaultConfig = WorkspaceConfig(
    name: 'my-workspace',
    env: {},
    agents: {
      'lead': AgentConfig(
        template: 'my-template',
        env: {},
        subAgents: {},
        subAgentOrder: [],
        peers: [],
        autoStart: true,
      ),
    },
    agentOrder: ['lead'],
    mounts: [],
    docker: DockerConfig(
      networkMode: 'host',
      ports: [],
      gpu: false,
      homePersistence: false,
    ),
  );

  // ── State ──

  String _activeTab = 'visual';
  int _jsonEditorRevision = 0;

  late String _configYaml;
  WorkspaceConfig? _parsedConfig;
  String? _parseError;
  List<JsonEditorError> _editorErrors = [];
  bool _isCreating = false;

  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _parsedConfig = _defaultConfig;
    _configYaml = ''; // Will be populated asynchronously.
    _initializeYaml();
  }

  Future<void> _initializeYaml() async {
    final yaml = await _configToYaml(_defaultConfig);
    if (!mounted) return;
    setState(() => _configYaml = yaml);
    _validateConfig(_configYaml);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<String> _configToYaml(WorkspaceConfig config) async {
    final result = await ref.read(engineClientProvider).sendCommand(
        'encode_workspace_yaml', {'config': _configToMap(config)});
    return result['yaml'] as String? ?? '';
  }

  // ── FRB ↔ Map bridging helpers ──

  static Map<String, dynamic> _configToMap(WorkspaceConfig config) {
    return {
      'name': config.name,
      'env': config.env,
      'agents': config.agents.map((k, v) => MapEntry(k, _agentConfigToMap(v))),
      'agent_order': config.agentOrder,
      if (config.workspaceDir != null) 'workspace_dir': config.workspaceDir,
      'mounts': config.mounts.map((m) => {
        'host_path': m.hostPath,
        'container_path': m.containerPath,
        'read_only': m.readOnly,
      }).toList(),
      'docker': {
        if (config.docker.memoryLimit != null) 'memory_limit': config.docker.memoryLimit,
        if (config.docker.cpuLimit != null) 'cpu_limit': config.docker.cpuLimit,
        'network_mode': config.docker.networkMode,
        'ports': config.docker.ports,
        'gpu': config.docker.gpu,
        'home_persistence': config.docker.homePersistence,
        if (config.docker.homeSize != null) 'home_size': config.docker.homeSize,
      },
    };
  }

  static Map<String, dynamic> _agentConfigToMap(AgentConfig agent) {
    return {
      'template': agent.template,
      'env': agent.env,
      'sub_agents': agent.subAgents.map((k, v) => MapEntry(k, _agentConfigToMap(v))),
      'sub_agent_order': agent.subAgentOrder,
      'peers': agent.peers,
      if (agent.autoStart != null) 'auto_start': agent.autoStart,
    };
  }

  static WorkspaceConfig _configFromMap(Map<String, dynamic> m) {
    final agentsMap = (m['agents'] as Map<String, dynamic>?) ?? {};
    return WorkspaceConfig(
      name: m['name'] as String? ?? '',
      env: ((m['env'] as Map<String, dynamic>?) ?? {}).cast<String, String>(),
      agents: agentsMap.map((k, v) => MapEntry(k, _agentConfigFromMap(v as Map<String, dynamic>))),
      agentOrder: ((m['agent_order'] as List<dynamic>?) ?? []).cast<String>(),
      workspaceDir: m['workspace_dir'] as String?,
      mounts: ((m['mounts'] as List<dynamic>?) ?? []).map((e) {
        final mm = e as Map<String, dynamic>;
        return MountConfig(
          hostPath: mm['host_path'] as String? ?? '',
          containerPath: mm['container_path'] as String? ?? '',
          readOnly: mm['read_only'] as bool? ?? true,
        );
      }).toList(),
      docker: _dockerConfigFromMap((m['docker'] as Map<String, dynamic>?) ?? {}),
    );
  }

  static AgentConfig _agentConfigFromMap(Map<String, dynamic> m) {
    final subMap = (m['sub_agents'] as Map<String, dynamic>?) ?? {};
    return AgentConfig(
      template: m['template'] as String? ?? '',
      env: ((m['env'] as Map<String, dynamic>?) ?? {}).cast<String, String>(),
      subAgents: subMap.map((k, v) => MapEntry(k, _agentConfigFromMap(v as Map<String, dynamic>))),
      subAgentOrder: ((m['sub_agent_order'] as List<dynamic>?) ?? []).cast<String>(),
      peers: ((m['peers'] as List<dynamic>?) ?? []).cast<String>(),
      autoStart: m['auto_start'] as bool?,
    );
  }

  static DockerConfig _dockerConfigFromMap(Map<String, dynamic> m) {
    return DockerConfig(
      memoryLimit: m['memory_limit'] as String?,
      cpuLimit: (m['cpu_limit'] as num?)?.toDouble(),
      networkMode: m['network_mode'] as String? ?? 'host',
      ports: ((m['ports'] as List<dynamic>?) ?? []).cast<String>(),
      gpu: m['gpu'] as bool? ?? false,
      homePersistence: m['home_persistence'] as bool? ?? false,
      homeSize: m['home_size'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Tab switching
  // ---------------------------------------------------------------------------

  Future<void> _onTabChanged(String tab) async {
    if (tab == _activeTab) return;

    final client = ref.read(engineClientProvider);
    if (tab == 'yaml') {
      // Visual → YAML: serialize current config.
      if (_parsedConfig != null) {
        _configYaml = await _configToYaml(_parsedConfig!);
      }
      _jsonEditorRevision++;
    } else {
      // YAML → Visual: parse current YAML.
      try {
        final result = await client.sendCommand(
            'parse_workspace_config', {'yaml': _configYaml});
        _parsedConfig = _configFromMap(result);
        _parseError = null;
      } on FormatException catch (e) {
        toast('Cannot switch to Visual: ${e.message}',
            type: ToastType.error);
        return;
      } catch (e) {
        toast('Cannot switch to Visual: $e', type: ToastType.error);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _activeTab = tab);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Called when the YAML editor content changes (YAML tab).
  void _onYamlChanged(String yaml) {
    _configYaml = yaml;
    _debouncer.run(() => _validateConfig(yaml));
  }

  /// Called when the visual form produces a new config (Visual tab).
  void _onVisualConfigChanged(WorkspaceConfig config) {
    _parsedConfig = config;
    _configToYaml(config).then((yaml) {
      if (!mounted) return;
      _configYaml = yaml;
      _debouncer.run(() => _validateConfig(_configYaml));
    });
  }

  Future<void> _validateConfig(String yaml) async {
    final client = ref.read(engineClientProvider);
    final errors = <JsonEditorError>[];
    WorkspaceConfig? config;
    String? parseError;

    // 1. Parse YAML
    try {
      final result = await client.sendCommand(
          'parse_workspace_config', {'yaml': yaml});
      config = _configFromMap(result);
    } on FormatException catch (e) {
      parseError = e.message;
      errors.add(JsonEditorError(
        message: 'YAML syntax error: ${e.message}',
        severity: JsonEditorSeverity.error,
      ));
    } catch (e) {
      parseError = e.toString();
      errors.add(JsonEditorError(
        message: 'Parse error: $e',
        severity: JsonEditorSeverity.error,
      ));
    }

    // 2. Validate config structure
    if (config != null) {
      try {
        final validationResult = await client.sendCommand(
            'validate_workspace_config', {'config': _configToMap(config)});
        final validationErrors =
            (validationResult['errors'] as List<dynamic>?) ?? [];
        for (final ve in validationErrors) {
          final veMap = ve as Map<String, dynamic>;
          errors.add(JsonEditorError(
            message: '${veMap['field']}: ${veMap['message']}',
            severity: JsonEditorSeverity.error,
          ));
        }
      } catch (_) {
        // Validation not available, skip
      }
    }

    // 3. Resolve templates (checks template existence, env, mounts, API keys)
    if (config != null) {
      try {
        final resolution = await client.sendCommand(
            'resolve_workspace_templates', {'config': _configToMap(config)});
        final unresolvedTemplates =
            (resolution['unresolved_templates'] as List<dynamic>?) ?? [];
        final missingApiKeys =
            (resolution['missing_api_keys'] as List<dynamic>?) ?? [];
        final missingRequiredEnv =
            (resolution['missing_required_env'] as List<dynamic>?) ?? [];
        final emptyRequiredEnv =
            (resolution['empty_required_env'] as List<dynamic>?) ?? [];
        final missingRequiredMounts =
            (resolution['missing_required_mounts'] as List<dynamic>?) ?? [];

        for (final t in unresolvedTemplates) {
          final tMap = t as Map<String, dynamic>;
          errors.add(JsonEditorError(
            message:
                '${tMap['agent_path']}: template "${tMap['template_name']}" not found',
            severity: JsonEditorSeverity.error,
          ));
        }
        for (final k in missingApiKeys) {
          final kMap = k as Map<String, dynamic>;
          errors.add(JsonEditorError(
            message:
                '${kMap['agent_path']}: API key "${kMap['key_name']}" not found',
            severity: JsonEditorSeverity.error,
          ));
        }
        for (final e in missingRequiredEnv) {
          final eMap = e as Map<String, dynamic>;
          errors.add(JsonEditorError(
            message:
                '${eMap['agent_path']}: required env "${eMap['env_key']}" missing (template: ${eMap['template_name']})',
            severity: JsonEditorSeverity.error,
          ));
        }
        for (final e in emptyRequiredEnv) {
          final eMap = e as Map<String, dynamic>;
          errors.add(JsonEditorError(
            message:
                '${eMap['agent_path']}: required env "${eMap['env_key']}" is empty (template: ${eMap['template_name']})',
            severity: JsonEditorSeverity.warning,
          ));
        }
        for (final m in missingRequiredMounts) {
          final mMap = m as Map<String, dynamic>;
          errors.add(JsonEditorError(
            message:
                '${mMap['agent_path']}: required mount "${mMap['container_path']}" not provided (template: ${mMap['template_name']})',
            severity: JsonEditorSeverity.error,
          ));
        }
      } catch (e) {
        // Template resolution requires DB — gracefully skip if unavailable.
        errors.add(JsonEditorError(
          message: 'Template resolution unavailable: $e',
          severity: JsonEditorSeverity.warning,
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _parsedConfig = config;
      _parseError = parseError;
      _editorErrors = errors;
    });
  }

  // ---------------------------------------------------------------------------
  // Creation flow
  // ---------------------------------------------------------------------------

  Future<void> _onCreatePressed() async {
    // Ensure _configYaml is current when in visual mode.
    if (_activeTab == 'visual' && _parsedConfig != null) {
      _configYaml = await _configToYaml(_parsedConfig!);
    }

    // Force-validate (bypass debouncer).
    await _validateConfig(_configYaml);

    final hasErrors =
        _editorErrors.any((e) => e.severity == JsonEditorSeverity.error);
    if (hasErrors) {
      toast('Fix validation errors before creating', type: ToastType.error);
      return;
    }

    final projectPath = _parsedConfig?.workspaceDir?.trim() ?? '';
    if (projectPath.isEmpty) {
      toast('Select a workspace directory', type: ToastType.error);
      return;
    }

    // Check for existing dspatch.workspace.yml
    final configFile = File('$projectPath/dspatch.workspace.yml');
    if (configFile.existsSync()) {
      final overwrite = await _confirmOverwrite();
      if (!overwrite) return;
    }

    setState(() => _isCreating = true);

    try {
      final success = await ref
          .read(workspaceControllerProvider.notifier)
          .createWorkspace(
            projectPath: projectPath,
            configYaml: _configYaml,
          );

      if (!mounted) return;

      if (success) {
        context.go('/workspaces');
      }
    } catch (_) {
      // Auto-dispose of the controller can cause state setter to throw.
      if (!mounted) return;
      toast('Failed to create workspace', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<bool> _confirmOverwrite() async {
    var confirmed = false;
    await DspatchDialog.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogHeader(children: [
            DialogTitle(text: 'Overwrite Configuration'),
            DialogDescription(
              text:
                  'A dspatch.workspace.yml already exists in this directory. '
                  'Do you want to overwrite it?',
            ),
          ]),
          DialogFooter(children: [
            Button(
              label: 'Cancel',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            Button(
              label: 'Overwrite',
              variant: ButtonVariant.destructive,
              onPressed: () {
                confirmed = true;
                Navigator.of(ctx).pop();
              },
            ),
          ]),
        ],
      ),
    );
    return confirmed;
  }


  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Keep the controller alive while this screen is mounted so the
    // auto-dispose notifier isn't collected mid-async-operation.
    ref.watch(workspaceControllerProvider);

    return ContentArea(
      maxWidth: 1400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: Spacing.md),
          Expanded(child: _buildEditorAndPreview()),
          const SizedBox(height: Spacing.md),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        DspatchIconButton(
          icon: LucideIcons.arrow_left,
          variant: IconButtonVariant.ghost,
          size: IconButtonSize.sm,
          tooltip: 'Back',
          onPressed: () => context.go('/workspaces'),
        ),
        const SizedBox(width: Spacing.sm),
        const Text(
          'New Workspace',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildEditorAndPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar row: validation bubble (left) + tab toggle (right)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Row(
            children: [
              _buildValidationBubble(),
              const Spacer(),
              ToggleGroup(
                style: ToggleGroupStyle.grouped,
                variant: ToggleVariant.outline,
                iconMode: false,
                value: {_activeTab},
                onChanged: (v) {
                  if (v.isNotEmpty) _onTabChanged(v.first);
                },
                children: const [
                  ToggleGroupItem(value: 'visual', label: 'Visual'),
                  ToggleGroupItem(value: 'yaml', label: 'YAML'),
                ],
              ),
            ],
          ),
        ),
        // Editor + Preview
        Expanded(
          child: Resizable(
            children: [
              ResizablePanel(
                initialFlex: 0.4,
                minFlex: 0.2,
                child: HierarchyPreview(
                  config: _parsedConfig,
                  parseError: _activeTab == 'yaml' ? _parseError : null,
                ),
              ),
              ResizablePanel(
                initialFlex: 0.6,
                minFlex: 0.3,
                child: _activeTab == 'visual'
                    ? WorkspaceVisualEditor(
                        config: _parsedConfig ?? _defaultConfig,
                        onChanged: _onVisualConfigChanged,
                      )
                    : JsonEditor(
                        key: ValueKey('yaml-editor-$_jsonEditorRevision'),
                        initialValue: _configYaml,
                        onChanged: _onYamlChanged,
                        errors: _editorErrors,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidationBubble() {
    final errors = _editorErrors
        .where((e) => e.severity == JsonEditorSeverity.error)
        .toList();
    final warnings = _editorErrors
        .where((e) => e.severity == JsonEditorSeverity.warning)
        .toList();

    final hasErrors = errors.isNotEmpty;
    final hasWarnings = warnings.isNotEmpty;
    final isValid = !hasErrors && !hasWarnings;

    // Build compact trigger badge
    final IconData icon;
    final BadgeVariant variant;
    final String label;

    if (hasErrors) {
      icon = LucideIcons.circle_alert;
      variant = BadgeVariant.destructive;
      final parts = <String>[];
      parts.add('${errors.length} error${errors.length > 1 ? 's' : ''}');
      if (hasWarnings) {
        parts.add(
            '${warnings.length} warning${warnings.length > 1 ? 's' : ''}');
      }
      label = parts.join(', ');
    } else if (hasWarnings) {
      icon = LucideIcons.triangle_alert;
      variant = BadgeVariant.warning;
      label = '${warnings.length} warning${warnings.length > 1 ? 's' : ''}';
    } else {
      icon = LucideIcons.circle_check;
      variant = BadgeVariant.success;
      label = 'Config valid';
    }

    final trigger = DspatchBadge(
      icon: icon,
      label: label,
      variant: variant,
    );

    // No hover details needed for valid state
    if (isValid) return trigger;

    // Wrap with HoverCard for full details
    return HoverCard(
      width: 320,
      anchorSide: PopoverSide.bottom,
      anchorAlign: PopoverAlign.start,
      trigger: trigger,
      content: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasErrors) ...[
              Row(
                children: [
                  const Icon(LucideIcons.circle_alert,
                      size: 14, color: AppColors.destructive),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${errors.length} error${errors.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.destructive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              ...errors.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 2),
                    child: Text(
                      '• ${e.message}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.foreground),
                    ),
                  )),
            ],
            if (hasErrors && hasWarnings)
              const SizedBox(height: Spacing.sm),
            if (hasWarnings) ...[
              Row(
                children: [
                  const Icon(LucideIcons.triangle_alert,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '${warnings.length} warning${warnings.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              ...warnings.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 2),
                    child: Text(
                      '• ${e.message}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.foreground),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Button(
          label: 'Cancel',
          variant: ButtonVariant.outline,
          onPressed: () => context.go('/workspaces'),
        ),
        const SizedBox(width: Spacing.sm),
        Button(
          label: 'Create Workspace',
          loading: _isCreating,
          onPressed: _isCreating ? null : _onCreatePressed,
        ),
      ],
    );
  }
}
