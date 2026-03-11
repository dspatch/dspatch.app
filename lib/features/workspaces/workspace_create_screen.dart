// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
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

  Future<String> _configToYaml(WorkspaceConfig config) {
    return ref.read(sdkProvider).encodeWorkspaceYaml(config: config);
  }

  // ---------------------------------------------------------------------------
  // Tab switching
  // ---------------------------------------------------------------------------

  Future<void> _onTabChanged(String tab) async {
    if (tab == _activeTab) return;

    final sdk = ref.read(sdkProvider);
    if (tab == 'yaml') {
      // Visual → YAML: serialize current config.
      if (_parsedConfig != null) {
        _configYaml = await _configToYaml(_parsedConfig!);
      }
      _jsonEditorRevision++;
    } else {
      // YAML → Visual: parse current YAML.
      try {
        _parsedConfig = await sdk.parseWorkspaceConfig(yaml: _configYaml);
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
    final sdk = ref.read(sdkProvider);
    final errors = <JsonEditorError>[];
    WorkspaceConfig? config;
    String? parseError;

    // 1. Parse YAML
    try {
      config = await sdk.parseWorkspaceConfig(yaml: yaml);
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
      final validationErrors =
          await sdk.validateWorkspaceConfig(config: config);
      for (final ve in validationErrors) {
        errors.add(JsonEditorError(
          message: '${ve.field}: ${ve.message}',
          severity: JsonEditorSeverity.error,
        ));
      }
    }

    // 3. Resolve templates (checks template existence, env, mounts, API keys)
    if (config != null) {
      try {
        final resolution =
            await sdk.resolveWorkspaceTemplates(config: config);
        for (final t in resolution.unresolvedTemplates) {
          errors.add(JsonEditorError(
            message:
                '${t.agentPath}: template "${t.templateName}" not found',
            severity: JsonEditorSeverity.error,
          ));
        }
        for (final k in resolution.missingApiKeys) {
          errors.add(JsonEditorError(
            message:
                '${k.agentPath}: API key "${k.keyName}" not found',
            severity: JsonEditorSeverity.error,
          ));
        }
        for (final e in resolution.missingRequiredEnv) {
          errors.add(JsonEditorError(
            message:
                '${e.agentPath}: required env "${e.envKey}" missing (template: ${e.templateName})',
            severity: JsonEditorSeverity.error,
          ));
        }
        for (final e in resolution.emptyRequiredEnv) {
          errors.add(JsonEditorError(
            message:
                '${e.agentPath}: required env "${e.envKey}" is empty (template: ${e.templateName})',
            severity: JsonEditorSeverity.warning,
          ));
        }
        for (final m in resolution.missingRequiredMounts) {
          errors.add(JsonEditorError(
            message:
                '${m.agentPath}: required mount "${m.containerPath}" not provided (template: ${m.templateName})',
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
          .createWorkspace(CreateWorkspaceRequest(
            projectPath: projectPath,
            configYaml: _configYaml,
          ));

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
