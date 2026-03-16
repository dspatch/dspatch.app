// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:io';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaml/yaml.dart';

import '../../core/extensions/drift_extensions.dart';
import '../../core/extensions/string_ext.dart';
import '../../core/utils/agent_source_scanner.dart';
import '../../core/utils/debouncer.dart';
import '../../di/providers.dart';
import '../../models/commands/commands.dart';
import '../../models/hub_types.dart';
import '../hub/hub_agent_browser.dart';
import 'agent_provider_controller.dart';
import 'widgets/agent_provider_form_validator.dart';
import 'widgets/fields_editor.dart';
import 'widgets/required_env_editor.dart';
import 'widgets/required_mounts_editor.dart';

class AgentProviderFormScreen extends ConsumerStatefulWidget {
  final String? id;
  final String? templateId;
  final bool isNewTemplate;

  const AgentProviderFormScreen({
    super.key,
    this.id,
    this.templateId,
    this.isNewTemplate = false,
  });

  @override
  ConsumerState<AgentProviderFormScreen> createState() =>
      _AgentProviderFormScreenState();
}

class _AgentProviderFormScreenState
    extends ConsumerState<AgentProviderFormScreen> {
  final _nameController = TextEditingController();
  final _entryPointController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourcePathController = TextEditingController();
  final _gitUrlController = TextEditingController();
  final _gitBranchController = TextEditingController();

  String _sourceType = 'local';
  List<String> _requiredEnv = [];
  List<String> _requiredMounts = [];
  final Map<String, String?> _errors = {};
  final _debouncer = Debouncer();

  String? _readme;

  String? _sourceUri;

  bool get _isEdit => widget.id != null;
  bool get _isTemplateMode => widget.templateId != null || widget.isNewTemplate;
  bool get _isTemplateEdit => widget.templateId != null;
  bool _initialized = false;
  bool _templateInitialized = false;
  bool _entryPointAutoDetected = false;
  bool _envKeysAutoDetected = false;
  bool _mountsAutoDetected = false;
  bool _detectingEntryPoint = false;
  bool _importingEnvKeys = false;
  bool _importingMounts = false;
  Map<String, String> _fields = {};
  bool _fieldsAutoDetected = false;
  bool _importingFromGit = false;
  bool _gitImported = false;

  /// Converts a JSON list of {key, value} maps (from fieldsJson) to Map<String, String>.
  static Map<String, String> _parseFieldsList(List<dynamic> fields) {
    final result = <String, String>{};
    for (final entry in fields) {
      if (entry is Map) {
        final key = entry['key']?.toString() ?? '';
        final value = entry['value']?.toString() ?? '';
        if (key.isNotEmpty) result[key] = value;
      }
    }
    return result;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entryPointController.dispose();
    _descriptionController.dispose();
    _sourcePathController.dispose();
    _gitUrlController.dispose();
    _gitBranchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _validateField(String fieldName) {
    _debouncer.run(() {
      setState(() {
        _errors[fieldName] = switch (fieldName) {
          'name' => AgentProviderFormValidator.validateName(
              _nameController.text),
          'entryPoint' => AgentProviderFormValidator.validateEntryPoint(
              _entryPointController.text),
          'sourcePath' => AgentProviderFormValidator.validateSourcePath(
              _sourcePathController.text),
          'gitUrl' => AgentProviderFormValidator.validateGitUrl(
              _gitUrlController.text),
          _ => null,
        };
      });
    });
  }

  void _onSourcePathChanged(String path) {
    _validateField('sourcePath');

    // Only auto-detect if the path is valid (git repo).
    if (AgentProviderFormValidator.validateSourcePath(path) != null) return;

    // Auto-detect entry point if field is empty.
    if (_entryPointController.text.isEmpty) {
      AgentSourceScanner.readEntryPoint(path.trim()).then((entry) async {
        if (entry != null && mounted && _entryPointController.text.isEmpty) {
          setState(() {
            _entryPointController.text = entry;
            _entryPointAutoDetected = true;
          });
        } else {
          final detected = await AgentSourceScanner.detectEntryPoint(path.trim());
          if (detected != null && mounted && _entryPointController.text.isEmpty) {
            setState(() {
              _entryPointController.text = detected;
              _entryPointAutoDetected = true;
            });
          }
        }
      });
    }
    
    // Auto-fill description from dspatch.agent.yml if empty.
    if (_descriptionController.text.isEmpty) {
      AgentSourceScanner.readDescription(path.trim()).then((desc) {
        if (desc != null && mounted && _descriptionController.text.isEmpty) {
          setState(() => _descriptionController.text = desc);
        }
      });
    }

    // Auto-read required_env keys from dspatch.agent.yml if list is empty.
    if (_requiredEnv.isEmpty) {
      AgentSourceScanner.readRequiredEnv(path.trim()).then((keys) {
        if (keys.isNotEmpty && mounted && _requiredEnv.isEmpty) {
          setState(() {
            _requiredEnv = keys;
            _envKeysAutoDetected = true;
          });
        }
      });
    }

    // Auto-read required mounts from dspatch.agent.yml if list is empty.
    if (_requiredMounts.isEmpty) {
      AgentSourceScanner.readRequiredMounts(path.trim()).then((mounts) {
        if (mounts.isNotEmpty && mounted && _requiredMounts.isEmpty) {
          setState(() {
            _requiredMounts = mounts;
            _mountsAutoDetected = true;
          });
        }
      });
    }

    // Auto-read fields from dspatch.agent.yml if map is empty.
    if (_fields.isEmpty) {
      AgentSourceScanner.readFields(path.trim()).then((fields) {
        if (fields.isNotEmpty && mounted && _fields.isEmpty) {
          setState(() {
            _fields = fields;
            _fieldsAutoDetected = true;
          });
        }
      });
    }
  }

  Future<void> _autoDetectEntryPoint() async {
    final path = _sourcePathController.text.trim();
    if (path.isEmpty) return;

    setState(() => _detectingEntryPoint = true);
    final entry = await AgentSourceScanner.detectEntryPoint(path);
    if (!mounted) return;

    setState(() {
      _detectingEntryPoint = false;
      if (entry != null) {
        _entryPointController.text = entry;
        _entryPointAutoDetected = true;
        toast('Entry point detected: $entry', type: ToastType.success);
      } else {
        toast('No DspatchAgent pattern found', type: ToastType.warning);
      }
    });
  }

  Future<void> _importRequiredEnv() async {
    final path = _sourcePathController.text.trim();
    if (path.isEmpty) return;

    setState(() => _importingEnvKeys = true);
    final keys = await AgentSourceScanner.readRequiredEnv(path);
    if (!mounted) return;

    setState(() {
      _importingEnvKeys = false;
      if (keys.isNotEmpty) {
        final existing = _requiredEnv.toSet();
        final newKeys = keys.where((k) => !existing.contains(k)).toList();
        if (newKeys.isNotEmpty) {
          _requiredEnv = [..._requiredEnv, ...newKeys];
          _envKeysAutoDetected = true;
          toast('Imported ${newKeys.length} keys from dspatch.agent.yml',
              type: ToastType.success);
        } else {
          toast('All keys already present', type: ToastType.info);
        }
      } else {
        toast('No dspatch.agent.yml found or no required_env declared',
            type: ToastType.warning);
      }
    });
  }

  Future<void> _importMounts() async {
    final path = _sourcePathController.text.trim();
    if (path.isEmpty) return;

    setState(() => _importingMounts = true);
    final mounts = await AgentSourceScanner.readRequiredMounts(path);
    if (!mounted) return;

    setState(() {
      _importingMounts = false;
      if (mounts.isNotEmpty) {
        final existing = _requiredMounts.toSet();
        final newMounts =
            mounts.where((m) => !existing.contains(m)).toList();
        if (newMounts.isNotEmpty) {
          _requiredMounts = [..._requiredMounts, ...newMounts];
          _mountsAutoDetected = true;
          toast('Imported ${newMounts.length} mounts from dspatch.agent.yml',
              type: ToastType.success);
        } else {
          toast('All mounts already present', type: ToastType.info);
        }
      } else {
        toast('No dspatch.agent.yml found or no mounts declared',
            type: ToastType.warning);
      }
    });
  }

  Future<void> _importFields() async {
    final path = _sourcePathController.text.trim();
    if (path.isEmpty) return;

    final fields = await AgentSourceScanner.readFields(path);
    if (!mounted) return;

    setState(() {
      if (fields.isNotEmpty) {
        final existing = _fields.keys.toSet();
        final newFields = Map.fromEntries(
            fields.entries.where((e) => !existing.contains(e.key)));
        if (newFields.isNotEmpty) {
          _fields = {..._fields, ...newFields};
          _fieldsAutoDetected = true;
          toast('Imported ${newFields.length} fields from dspatch.agent.yml',
              type: ToastType.success);
        } else {
          toast('All fields already present', type: ToastType.info);
        }
      } else {
        toast('No dspatch.agent.yml found or no fields declared',
            type: ToastType.warning);
      }
    });
  }

  Future<void> _importFromGit() async {
    final url = _gitUrlController.text.trim();
    if (url.isEmpty) return;
    final branch = _gitBranchController.text.trim();

    setState(() => _importingFromGit = true);

    // Clone to temp directory.
    final tmpDir = await Directory.systemTemp.createTemp('dspatch_git_import_');
    try {
      final args = [
        'clone', '--depth', '1',
        if (branch.isNotEmpty) ...['--branch', branch],
        url, tmpDir.path,
      ];
      final cloneResult = await Process.run('git', args);
      if (cloneResult.exitCode != 0) {
        if (!mounted) return;
        setState(() => _importingFromGit = false);
        final stderr = (cloneResult.stderr as String).trim();
        toast(
          'Failed to clone repository',
          description: stderr.isNotEmpty ? stderr : 'git clone exited with code ${cloneResult.exitCode}',
          type: ToastType.error,
        );
        return;
      }

      // Run all scanners on the cloned repo.
      final results = await Future.wait([
        AgentSourceScanner.readName(tmpDir.path),
        AgentSourceScanner.readDescription(tmpDir.path),
        AgentSourceScanner.readEntryPoint(tmpDir.path),
        AgentSourceScanner.detectEntryPoint(tmpDir.path),
        AgentSourceScanner.readRequiredEnv(tmpDir.path),
        AgentSourceScanner.readRequiredMounts(tmpDir.path),
        AgentSourceScanner.readReadme(tmpDir.path),
        AgentSourceScanner.readFields(tmpDir.path),
      ]);

      if (!mounted) return;

      final name = results[0] as String?;
      final description = results[1] as String?;
      final entryPointFromYaml = results[2] as String?;
      final entryPointFromCode = results[3] as String?;
      final entryPoint = entryPointFromYaml ?? entryPointFromCode;
      final envKeys = results[4] as List<String>;
      final mounts = results[5] as List<String>;
      final readme = results[6] as String?;
      final fields = results[7] as Map<String, String>;

      setState(() {
        _importingFromGit = false;
        _gitImported = true;

        if (_nameController.text.isEmpty) {
          _nameController.text =
              name ?? AgentSourceScanner.extractRepoName(url) ?? '';
        }
        if (_descriptionController.text.isEmpty && description != null) {
          _descriptionController.text = description;
        }
        if (_entryPointController.text.isEmpty && entryPoint != null) {
          _entryPointController.text = entryPoint;
          _entryPointAutoDetected = true;
        }
        if (_requiredEnv.isEmpty && envKeys.isNotEmpty) {
          _requiredEnv = envKeys;
          _envKeysAutoDetected = true;
        }
        if (_requiredMounts.isEmpty && mounts.isNotEmpty) {
          _requiredMounts = mounts;
          _mountsAutoDetected = true;
        }
        if (_readme == null && readme != null) {
          _readme = readme;
        }
        if (_fields.isEmpty && fields.isNotEmpty) {
          _fields = fields;
          _fieldsAutoDetected = true;
        }
      });

      toast('Imported template details from repository', type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _importingFromGit = false);
      toast(
        'Failed to import from git',
        description: e.toString(),
        type: ToastType.error,
      );
    } finally {
      // Clean up temp directory.
      try {
        if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  void _populateFromTemplate() {
    if (_initialized || !_isEdit) return;
    final template = ref.read(agentProviderProvider(widget.id!)).valueOrNull;
    if (template == null) return;

    _initialized = true;
    _nameController.text = template.name;
    _entryPointController.text = template.entryPoint;
    _descriptionController.text = template.description ?? '';
    _sourceType = template.sourceType;
    _sourcePathController.text = template.sourcePath ?? '';
    _gitUrlController.text = template.gitUrl ?? '';
    _gitBranchController.text = template.gitBranch ?? '';
    _requiredEnv = template.requiredEnv.cast<String>();
    _requiredMounts = template.requiredMounts.cast<String>();
    _readme = template.readme;
    _fields = _parseFieldsList(template.fields);
  }

  void _populateFromTemplateData() {
    if (_templateInitialized || !_isTemplateEdit) return;
    final template = ref.read(agentTemplateProvider(widget.templateId!)).valueOrNull;
    if (template == null) return;

    _templateInitialized = true;
    _nameController.text = template.name;
    _sourceUri = template.sourceUri;

    // Read the dspatch.agent.yml at template.filePath to populate form fields.
    final file = File(template.filePath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final doc = loadYaml(content);
        if (doc is YamlMap) {
          if (doc['entry_point'] != null && _entryPointController.text.isEmpty) {
            _entryPointController.text = doc['entry_point'].toString();
          }
          if (doc['description'] != null && _descriptionController.text.isEmpty) {
            _descriptionController.text = doc['description'].toString();
          }
          if (doc['required_env'] is YamlList && _requiredEnv.isEmpty) {
            _requiredEnv = (doc['required_env'] as YamlList)
                .map((e) => e.toString())
                .toList();
          }
          if (doc['required_mounts'] is YamlList && _requiredMounts.isEmpty) {
            _requiredMounts = (doc['required_mounts'] as YamlList)
                .map((e) => e.toString())
                .toList();
          }
          if (doc['fields'] is YamlMap && _fields.isEmpty) {
            _fields = (doc['fields'] as YamlMap)
                .map((k, v) => MapEntry(k.toString(), v.toString()));
          }
          if (doc['source_type'] != null) {
            final st = doc['source_type'].toString();
            if (st == 'git') _sourceType = 'git';
            if (st == 'local') _sourceType = 'local';
          }
          if (doc['source_path'] != null) {
            _sourcePathController.text = doc['source_path'].toString();
          }
          if (doc['git_url'] != null) {
            _gitUrlController.text = doc['git_url'].toString();
          }
          if (doc['git_branch'] != null) {
            _gitBranchController.text = doc['git_branch'].toString();
          }
        }
      } catch (_) {
        // Ignore YAML parse errors — user can fill in manually.
      }
    }
  }

  Future<void> _writeTemplateYaml(String filePath) async {
    final buf = StringBuffer();
    final entryPoint = _entryPointController.text.trim();
    final description = _descriptionController.text.trim();

    if (entryPoint.isNotEmpty) buf.writeln('entry_point: $entryPoint');
    if (description.isNotEmpty) buf.writeln('description: $description');

    if (_sourceType == 'local' && _sourcePathController.text.trim().isNotEmpty) {
      buf.writeln('source_type: local');
      buf.writeln('source_path: ${_sourcePathController.text.trim()}');
    } else if (_sourceType == 'git' && _gitUrlController.text.trim().isNotEmpty) {
      buf.writeln('source_type: git');
      buf.writeln('git_url: ${_gitUrlController.text.trim()}');
      final branch = _gitBranchController.text.trim();
      if (branch.isNotEmpty) buf.writeln('git_branch: $branch');
    }

    if (_requiredEnv.isNotEmpty) {
      buf.writeln('required_env:');
      for (final key in _requiredEnv) {
        buf.writeln('  - $key');
      }
    }
    if (_requiredMounts.isNotEmpty) {
      buf.writeln('required_mounts:');
      for (final mount in _requiredMounts) {
        buf.writeln('  - $mount');
      }
    }
    if (_fields.isNotEmpty) {
      buf.writeln('fields:');
      for (final entry in _fields.entries) {
        buf.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(buf.toString());
  }

  Future<void> _saveTemplate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errors['name'] = 'Name is required');
      return;
    }
    if (_sourceUri == null || _sourceUri!.isEmpty) {
      toast('Please select a source provider', type: ToastType.error);
      return;
    }

    final controller = ref.read(agentProviderControllerProvider.notifier);

    if (_isTemplateEdit) {
      final success = await controller.updateAgentTemplate(
        widget.templateId!,
        name,
        _sourceUri!,
      );
      if (success) {
        // Write updated config YAML.
        final template = ref.read(agentTemplateProvider(widget.templateId!)).valueOrNull;
        if (template != null) {
          await _writeTemplateYaml(template.filePath);
        }
        if (mounted) context.go('/agent-providers');
      }
    } else {
      // New template: create first to get filePath, then write YAML.
      try {
        final client = ref.read(engineClientProvider);
        final result = await client.send(CreateAgentTemplate(request: {
          'name': name,
          'source_uri': _sourceUri!,
        }));
        await _writeTemplateYaml(result.raw['file_path'] as String? ?? '');
        toast('Template created', type: ToastType.success);
        if (mounted) context.go('/agent-providers');
      } catch (e) {
        toast('Failed to create template: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final entryPoint = _entryPointController.text.trim();

    final errors = AgentProviderFormValidator.validateAll(
      name: name,
      entryPoint: entryPoint,
      sourceType: _sourceType,
      sourcePath: _sourcePathController.text.trim(),
      gitUrl: _gitUrlController.text.trim(),
      requiredEnv: _requiredEnv,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
      });
      return;
    }

    final controller =
        ref.read(agentProviderControllerProvider.notifier);
    bool success;

    if (_isEdit) {
      success = await controller.updateAgentProvider(
        widget.id!,
        {
          'name': name,
          'sourceType': _sourceType,
          if (_sourceType == 'local')
            'sourcePath': _sourcePathController.text.trim(),
          if (_sourceType == 'git')
            'gitUrl': _gitUrlController.text.trim(),
          if (_sourceType == 'git')
            'gitBranch': _gitBranchController.text.trim().ifEmpty(null),
          'entryPoint': entryPoint,
          'description': _descriptionController.text.trim().ifEmpty(null),
          'requiredEnv': _requiredEnv,
          'requiredMounts': _requiredMounts,
          'fields': _fields,
        },
      );
    } else {
      success = await controller.createAgentProvider(
        {
          'name': name,
          'sourceType': _sourceType,
          if (_sourceType == 'local')
            'sourcePath': _sourcePathController.text.trim(),
          if (_sourceType == 'git')
            'gitUrl': _gitUrlController.text.trim(),
          if (_sourceType == 'git')
            'gitBranch': _gitBranchController.text.trim().ifEmpty(null),
          'entryPoint': entryPoint,
          'description': _descriptionController.text.trim().ifEmpty(null),
          'requiredEnv': _requiredEnv,
          'requiredMounts': _requiredMounts,
          'fields': _fields,
          'hubTags': const [],
        },
      );
    }

    if (success && mounted) {
      context.go('/agent-providers');
    }
  }

  Widget _buildSourcePicker() {
    final providersAsync = ref.watch(agentProvidersProvider);

    return _sectionCard(
      title: 'Source Provider',
      description: 'Select the agent provider this template is based on.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          providersAsync.when(
            loading: () => const Spinner(
                size: SpinnerSize.sm,
                color: AppColors.mutedForeground),
            error: (e, _) => Text('Failed to load providers: $e',
                style: const TextStyle(
                    color: AppColors.destructive, fontSize: 12)),
            data: (providers) {
              if (providers.isEmpty) {
                return const Text(
                  'No providers available. Create a provider first or browse the hub.',
                  style: TextStyle(
                      color: AppColors.mutedForeground, fontSize: 12),
                );
              }

              // Find which provider ID is currently selected based on _sourceUri.
              String? selectedId;
              if (_sourceUri != null) {
                for (final p in providers) {
                  if (p.hubAuthor != null && p.hubSlug != null) {
                    if (_sourceUri == 'dspatch://agent/${p.hubAuthor}/${p.hubSlug}') {
                      selectedId = p.id;
                      break;
                    }
                  }
                  if (_sourceUri == 'dspatch://provider/${p.id}') {
                    selectedId = p.id;
                    break;
                  }
                }
              }

              return Select<String>(
                value: selectedId,
                hint: 'Select a provider...',
                items: providers
                    .map((p) => SelectItem(
                          value: p.id,
                          label: p.name,
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final provider = providers.firstWhere((p) => p.id == id);
                  setState(() {
                    if (provider.hubAuthor != null && provider.hubSlug != null) {
                      _sourceUri = 'dspatch://agent/${provider.hubAuthor}/${provider.hubSlug}';
                    } else {
                      _sourceUri = 'dspatch://provider/${provider.id}';
                    }
                  });
                },
              );
            },
          ),
          const SizedBox(height: Spacing.md),
          Button(
            label: 'Browse Hub',
            icon: LucideIcons.globe,
            variant: ButtonVariant.outline,
            size: ButtonSize.sm,
            onPressed: () async {
              final result = await showDialog<HubAgentSummary>(
                context: context,
                builder: (_) => const Dialog(
                  child: HubAgentBrowserDialog(selectMode: true),
                ),
              );
              if (result != null && mounted) {
                // Create a local provider from the hub agent, then set source.
                try {
                  final client = ref.read(engineClientProvider);
                  final author = result.author ?? 'unknown';
                  final resolvedResp = await client.send(
                      HubResolveAgent(agentId: '$author/${result.slug}'));
                  await client.send(CreateAgentProvider(request: {
                    'name': result.name,
                    'sourceType': 'hub',
                    'hubSlug': result.slug,
                    'hubAuthor': result.author,
                    'hubCategory': result.category,
                    'hubTags': result.tags.map((t) => t.displayName).toList(),
                    'hubVersion': resolvedResp.raw['version'],
                    'hubRepoUrl': resolvedResp.raw['repo_url'],
                    'hubCommitHash': resolvedResp.raw['commit_hash'],
                    'entryPoint': resolvedResp.raw['entry_point'] ?? '',
                    'gitUrl': resolvedResp.raw['repo_url'],
                    'gitBranch': resolvedResp.raw['branch'],
                    'description': result.description,
                    'requiredEnv': const [],
                    'requiredMounts': const [],
                    'fields': const {},
                  }));
                  if (mounted) {
                    setState(() {
                      _sourceUri = 'dspatch://agent/${result.author}/${result.slug}';
                      if (_nameController.text.isEmpty) {
                        _nameController.text = 'My ${result.name} Template';
                      }
                    });
                    toast('Added "${result.name}" as provider', type: ToastType.success);
                  }
                } catch (e) {
                  if (mounted) {
                    toast('Failed to add hub agent: $e', type: ToastType.error);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      ref.watch(agentProviderProvider(widget.id!));
      _populateFromTemplate();
    }
    if (_isTemplateEdit) {
      ref.watch(agentTemplateProvider(widget.templateId!));
      _populateFromTemplateData();
    }

    final isLoading =
        ref.watch(agentProviderControllerProvider).isLoading;

    final String headerTitle;
    if (_isTemplateMode) {
      headerTitle = _isTemplateEdit ? 'Edit Template Preset' : 'New Template Preset';
    } else {
      headerTitle = _isEdit ? 'Edit Template' : 'New Template';
    }

    return SingleChildScrollView(
      child: ContentArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                DspatchIconButton(
                  icon: LucideIcons.arrow_left,
                  variant: IconButtonVariant.ghost,
                  size: IconButtonSize.sm,
                  onPressed: () => context.go('/agent-providers'),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  headerTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // ── Source Picker (template mode only) ──
            if (_isTemplateMode) ...[
              _buildSourcePicker(),
              const SizedBox(height: Spacing.lg),
            ],

            // ── Basic Information ──
            _sectionCard(
              title: 'Basic Information',
              description: 'Name and description for this agent template.',
              child: Column(
                children: [
                  Field(
                    label: 'Name',
                    required: true,
                    error: _errors['name'],
                    child: Input(
                      controller: _nameController,
                      placeholder: 'My Agent Template',
                      onChanged: (_) => _validateField('name'),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),
                  Field(
                    label: 'Description',
                    child: Input(
                      controller: _descriptionController,
                      placeholder: 'Optional description...',
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // ── Source & Entry Point ──
            _sectionCard(
              title: 'Source',
              description:
                  'Where the agent code lives and how to run it. '
                  'The source must be the root of a git repository.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Alert(
                    variant: AlertVariant.info,
                    icon: LucideIcons.file_code,
                    children: [
                      AlertTitle(text: 'Git Repository Required'),
                      AlertDescription(
                        text:
                            'The source directory must be the root of a git '
                            'repository. dspatch clones the repo into each '
                            'agent container at launch time.',
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  ToggleGroup(
                    style: ToggleGroupStyle.grouped,
                    variant: ToggleVariant.outline,
                    iconMode: false,
                    value: {_sourceType},
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        setState(() {
                          _sourceType = v.first == 'local'
                              ? 'local'
                              : 'git';
                        });
                      }
                    },
                    children: const [
                      ToggleGroupItem(value: 'local', label: 'Local'),
                      ToggleGroupItem(value: 'git', label: 'Git'),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (_sourceType == 'local') ...[
                    Field(
                      label: 'Source Path',
                      required: true,
                      description:
                          'Must point to the root of a git repository '
                          'containing your agent code.',
                      error: _errors['sourcePath'],
                      child: DirectoryPickerInput(
                        controller: _sourcePathController,
                        placeholder: '/path/to/agent/source',
                        dialogTitle: 'Select Source Directory',
                        buttonStyle: DirectoryPickerButtonStyle.primary,
                        onChanged: (_) => _onSourcePathChanged(
                            _sourcePathController.text),
                      ),
                    ),
                  ],
                  if (_sourceType == 'git') ...[
                    Field(
                      label: 'Repository URL',
                      required: true,
                      error: _errors['gitUrl'],
                      child: Input(
                        controller: _gitUrlController,
                        placeholder:
                            'https://github.com/org/repo.git',
                        onChanged: (_) {
                          setState(() {});
                          _validateField('gitUrl');
                        },
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    Field(
                      label: 'Branch',
                      description: 'Leave empty for default branch.',
                      child: Input(
                        controller: _gitBranchController,
                        placeholder: 'main',
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Button(
                          label: 'Import from Git',
                          icon: LucideIcons.download,
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          loading: _importingFromGit,
                          onPressed: _gitUrlController.text.trim().isNotEmpty
                              ? _importFromGit
                              : null,
                        ),
                        if (_gitImported) ...[
                          const SizedBox(width: Spacing.sm),
                          const DspatchBadge(
                            label: 'Imported from git',
                            variant: BadgeVariant.success,
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: Spacing.xxl),
                  Field(
                    label: 'Entry Point',
                    required: true,
                    description: _entryPointAutoDetected
                        ? 'Auto-detected from DspatchAgent pattern.'
                        : 'The Python file containing your DspatchAgent.',
                    error: _errors['entryPoint'],
                    child: _sourceType == 'local'
                        ? PathPickerInput(
                            mode: PathPickerMode.file,
                            controller: _entryPointController,
                            placeholder: 'agent.py',
                            dialogTitle: 'Select Entry Point',
                            buttonStyle: PathPickerButtonStyle.primary,
                            initialDirectory:
                                _sourcePathController.text.isNotEmpty
                                    ? _sourcePathController.text
                                    : null,
                            transformResult: (absolute) {
                              final source =
                                  _sourcePathController.text;
                              if (source.isNotEmpty &&
                                  absolute.startsWith(source)) {
                                var relative =
                                    absolute.substring(source.length);
                                if (relative.startsWith('/') ||
                                    relative.startsWith('\\')) {
                                  relative = relative.substring(1);
                                }
                                return relative;
                              }
                              return absolute;
                            },
                            onChanged: (_) {
                              _entryPointAutoDetected = false;
                              _validateField('entryPoint');
                            },
                          )
                        : Input(
                            controller: _entryPointController,
                            placeholder: 'agent.py',
                            onChanged: (_) {
                              _entryPointAutoDetected = false;
                              _validateField('entryPoint');
                            },
                          ),
                  ),
                  // Auto-detect button
                  if (_sourceType == 'local' &&
                      _sourcePathController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Row(
                        children: [
                          Button(
                            label: 'Auto-detect Entry Point',
                            icon: LucideIcons.search,
                            variant: ButtonVariant.outline,
                            size: ButtonSize.sm,
                            loading: _detectingEntryPoint,
                            onPressed: _autoDetectEntryPoint,
                          ),
                          if (_entryPointAutoDetected) ...[
                            const SizedBox(width: Spacing.sm),
                            const DspatchBadge(
                              label: 'Auto-detected',
                              variant: BadgeVariant.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // ── Required Environment Keys ──
            _sectionCard(
              title: 'Required Environment Keys',
              description: _envKeysAutoDetected
                  ? 'Auto-populated from dspatch.agent.yml. '
                    'Values are provided at the workspace level.'
                  : 'Environment variable keys this agent requires. '
                    'Values are provided at the workspace level.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequiredEnvEditor(
                    keys: _requiredEnv,
                    onChanged: (keys) {
                      _envKeysAutoDetected = false;
                      setState(() => _requiredEnv = keys);
                    },
                  ),
                  if (_sourceType == 'local' &&
                      _sourcePathController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Row(
                        children: [
                          Button(
                            label: 'Import from dspatch.agent.yml',
                            icon: LucideIcons.upload,
                            variant: ButtonVariant.outline,
                            size: ButtonSize.sm,
                            loading: _importingEnvKeys,
                            onPressed: _importRequiredEnv,
                          ),
                          if (_envKeysAutoDetected) ...[
                            const SizedBox(width: Spacing.sm),
                            const DspatchBadge(
                              label: 'Imported from dspatch.agent.yml',
                              variant: BadgeVariant.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // ── Required Mounts ──
            _sectionCard(
              title: 'Required Mounts',
              description: _mountsAutoDetected
                  ? 'Auto-populated from dspatch.agent.yml. '
                    'When a workspace uses this template, these mounts are '
                    'added automatically and the user specifies the host path (directory or file).'
                  : 'Container paths this agent needs mounted (directories or files). '
                    'When a workspace uses this template, these mounts are '
                    'added automatically and the user specifies the host path.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequiredMountsEditor(
                    paths: _requiredMounts,
                    onChanged: (paths) {
                      _mountsAutoDetected = false;
                      setState(() => _requiredMounts = paths);
                    },
                  ),
                  if (_sourceType == 'local' &&
                      _sourcePathController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Row(
                        children: [
                          Button(
                            label: 'Import from dspatch.agent.yml',
                            icon: LucideIcons.upload,
                            variant: ButtonVariant.outline,
                            size: ButtonSize.sm,
                            loading: _importingMounts,
                            onPressed: _importMounts,
                          ),
                          if (_mountsAutoDetected) ...[
                            const SizedBox(width: Spacing.sm),
                            const DspatchBadge(
                              label: 'Imported from dspatch.agent.yml',
                              variant: BadgeVariant.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // ── Template Fields ──
            _sectionCard(
              title: 'Template Fields',
              description: _fieldsAutoDetected
                  ? 'Auto-populated from dspatch.agent.yml. '
                    'Fields are passed as DSPATCH_FIELD_<KEY> environment variables. '
                    'system_prompt and authority are automatically used by the Python SDK.'
                  : 'Key-value pairs passed to the agent as environment variables. '
                    'system_prompt and authority are automatically used by the Python SDK.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldsEditor(
                    fields: _fields,
                    onChanged: (fields) {
                      _fieldsAutoDetected = false;
                      setState(() => _fields = fields);
                    },
                  ),
                  if (_sourceType == 'local' &&
                      _sourcePathController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Row(
                        children: [
                          Button(
                            label: 'Import from dspatch.agent.yml',
                            icon: LucideIcons.upload,
                            variant: ButtonVariant.outline,
                            size: ButtonSize.sm,
                            onPressed: _importFields,
                          ),
                          if (_fieldsAutoDetected) ...[
                            const SizedBox(width: Spacing.sm),
                            const DspatchBadge(
                              label: 'Imported from dspatch.agent.yml',
                              variant: BadgeVariant.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xxl),

            // ── Actions ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                  label: 'Cancel',
                  variant: ButtonVariant.outline,
                  onPressed: () => context.go('/agent-providers'),
                ),
                const SizedBox(width: Spacing.sm),
                Button(
                  label: _isTemplateMode
                      ? (_isTemplateEdit ? 'Save Changes' : 'Create Template')
                      : (_isEdit ? 'Save Changes' : 'Create Template'),
                  loading: isLoading,
                  onPressed: _isTemplateMode ? _saveTemplate : _save,
                ),
              ],
            ),

            const SizedBox(height: Spacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? description,
    required Widget child,
  }) {
    return DspatchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
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
          CardContent(child: child),
        ],
      ),
    );
  }
}
