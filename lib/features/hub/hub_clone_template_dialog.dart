// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../database/engine_database.dart' show AgentProvider;
import '../../models/commands/settings.dart';
import 'dart:io';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';

/// Dialog for cloning a hub-sourced template into an editable local copy.
class HubCloneTemplateDialog extends ConsumerStatefulWidget {
  const HubCloneTemplateDialog({
    super.key,
    required this.template,
  });

  final AgentProvider template;

  @override
  ConsumerState<HubCloneTemplateDialog> createState() =>
      _HubCloneTemplateDialogState();
}

class _HubCloneTemplateDialogState
    extends ConsumerState<HubCloneTemplateDialog> {
  late final TextEditingController _nameController;
  final _directoryController = TextEditingController();
  bool _cloning = false;
  String? _error;

  /// Extract cloneable URL from pinned URL.
  /// Pinned: https://github.com/user/repo/tree/abc123
  /// Cloneable: https://github.com/user/repo.git
  String? get _cloneableUrl {
    final url = widget.template.hubRepoUrl;
    if (url == null || url.isEmpty) return null;
    final treeIdx = url.indexOf('/tree/');
    if (treeIdx != -1) {
      return '${url.substring(0, treeIdx)}.git';
    }
    // Already a plain repo URL
    return url;
  }

  String? get _repoName => _extractRepoName(_cloneableUrl ?? '');

  String? get _finalPath {
    final dir = _directoryController.text.trim();
    final repo = _repoName;
    if (dir.isEmpty || repo == null) return null;
    return '$dir/$repo';
  }

  /// Extract repository name from a git URL.
  static String? _extractRepoName(String url) {
    if (url.isEmpty) return null;
    // Handle common URL formats:
    //   https://github.com/user/repo.git
    //   https://github.com/user/repo
    //   git@github.com:user/repo.git
    var name = url.split('/').last;
    if (name.endsWith('.git')) {
      name = name.substring(0, name.length - 4);
    }
    return name.isEmpty ? null : name;
  }

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: '${widget.template.name} (clone)');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _directoryController.dispose();
    super.dispose();
  }

  Future<void> _clone() async {
    final name = _nameController.text.trim();
    final dir = _directoryController.text.trim();
    final cloneUrl = _cloneableUrl;
    final commitHash = widget.template.hubCommitHash;

    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (dir.isEmpty) {
      setState(() => _error = 'Please select a directory.');
      return;
    }
    if (cloneUrl == null || cloneUrl.isEmpty) {
      setState(() => _error = 'Template has no repository URL.');
      return;
    }

    final finalPath = _finalPath;
    if (finalPath == null) {
      setState(() => _error = 'Could not determine clone path.');
      return;
    }

    // Check if directory already exists.
    if (Directory(finalPath).existsSync()) {
      setState(() => _error = 'Directory already exists: $finalPath');
      return;
    }

    setState(() {
      _cloning = true;
      _error = null;
    });

    try {
      // 1. Clone the repository.
      final cloneResult = await Process.run(
        'git',
        ['clone', cloneUrl, finalPath],
      );
      if (cloneResult.exitCode != 0) {
        final stderr = (cloneResult.stderr as String).trim();
        throw Exception(
          stderr.isNotEmpty
              ? stderr
              : 'git clone exited with code ${cloneResult.exitCode}',
        );
      }

      // 2. Checkout the pinned commit.
      if (commitHash != null && commitHash.isNotEmpty) {
        final checkoutResult = await Process.run(
          'git',
          ['checkout', commitHash],
          workingDirectory: finalPath,
        );
        if (checkoutResult.exitCode != 0) {
          final stderr = (checkoutResult.stderr as String).trim();
          throw Exception(
            stderr.isNotEmpty
                ? stderr
                : 'git checkout exited with code ${checkoutResult.exitCode}',
          );
        }
      }

      // 3. Create the local provider via the engine.
      final client = ref.read(engineClientProvider);
      await client.send(CreateAgentProvider(request: {
        'name': name,
        'source_type': 'local',
        'source_path': finalPath,
        'entry_point': widget.template.entryPoint,
        'description': widget.template.description,
        'git_url': _cloneableUrl,
        'git_branch': widget.template.gitBranch,
        'required_env_json': widget.template.requiredEnvJson,
        'required_mounts_json': widget.template.requiredMountsJson,
        'fields_json': widget.template.fieldsJson,
        'hub_tags': const [],
      }));

      if (mounted) {
        toast("Cloned '$name' to $finalPath", type: ToastType.success);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Clean up cloned directory on failure.
      try {
        final clonedDir = Directory(finalPath);
        if (clonedDir.existsSync()) {
          await clonedDir.delete(recursive: true);
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cloning = false;
          _error = 'Clone failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;

    return DspatchDialog(
      maxWidth: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogHeader(children: [
              const DialogTitle(text: 'Clone Template'),
              const DialogDescription(
                text: 'Create an editable local copy of this hub template.',
              ),
            ]),
            DialogContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read-only info
                  _infoRow('Template', t.name),
                  if (t.hubAuthor != null)
                    _infoRow('Author', t.hubAuthor!),
                  if (t.hubRepoUrl != null)
                    _infoRow('Repository', t.hubRepoUrl!),
                  const SizedBox(height: Spacing.lg),

                  // Directory picker
                  Field(
                    label: 'Clone to',
                    required: true,
                    child: DirectoryPickerInput(
                      controller: _directoryController,
                      placeholder: 'Select parent directory...',
                      dialogTitle: 'Select Clone Directory',
                      buttonStyle: DirectoryPickerButtonStyle.primary,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Preview path
                  if (_finalPath != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      _finalPath!,
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.lg),

                  // Name
                  Field(
                    label: 'Name',
                    required: true,
                    child: Input(
                      controller: _nameController,
                      placeholder: 'Template name',
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.md),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.destructive,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            DialogFooter(children: [
              Button(
                label: 'Cancel',
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Button(
                label: 'Clone',
                icon: LucideIcons.copy,
                loading: _cloning,
                onPressed: _clone,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
