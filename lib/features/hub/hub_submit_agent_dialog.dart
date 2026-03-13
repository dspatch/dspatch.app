// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:convert';

import 'package:dspatch_sdk/dspatch_sdk.dart' show HubTagRef;

import '../../database/engine_database.dart' show AgentProvider;
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'widgets/tag_autocomplete_input.dart';

/// Fixed category list for hub submissions.
const _hubCategories = [
  'coding',
  'research',
  'automation',
  'data',
  'devops',
  'security',
  'creative',
  'communication',
  'general',
];

/// Dialog form for submitting an agent template to the community hub.
///
/// Pre-fills name, description, and entry point from the local [template].
/// For ['local'] templates, the user must provide a public git repo URL.
/// For ['git'] templates, the existing [gitUrl] is pre-filled.
class HubSubmitAgentDialog extends ConsumerStatefulWidget {
  const HubSubmitAgentDialog({
    super.key,
    required this.template,
    this.detectedRemoteUrl,
    this.detectedBranch,
    this.hasUncommittedChanges = false,
    this.hasUnpushedCommits = false,
  });

  final AgentProvider template;
  final String? detectedRemoteUrl;
  final String? detectedBranch;
  final bool hasUncommittedChanges;
  final bool hasUnpushedCommits;

  @override
  ConsumerState<HubSubmitAgentDialog> createState() =>
      _HubSubmitAgentDialogState();
}

class _HubSubmitAgentDialogState
    extends ConsumerState<HubSubmitAgentDialog> {
  bool get _hasGitIssues =>
      widget.hasUncommittedChanges || widget.hasUnpushedCommits;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _repoUrlController;
  late final TextEditingController _branchController;
  late final TextEditingController _entryPointController;
  String? _selectedCategory;
  Set<HubTagRef> _generalTags = {};
  Set<HubTagRef> _modelTags = {};
  Set<HubTagRef> _frameworkTags = {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t.name);
    _descriptionController =
        TextEditingController(text: t.description ?? '');
    _repoUrlController = TextEditingController(
      text: widget.detectedRemoteUrl ??
          (t.sourceType == 'git' ? (t.gitUrl ?? '') : ''),
    );
    _branchController = TextEditingController(
      text: widget.detectedBranch ?? t.gitBranch ?? '',
    );
    _entryPointController = TextEditingController(text: t.entryPoint);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repoUrlController.dispose();
    _branchController.dispose();
    _entryPointController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final repoUrl = _repoUrlController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (repoUrl.isEmpty) {
      setState(() => _error = 'A public git repository URL is required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final client = ref.read(engineClientProvider);
      final allTags = [..._generalTags, ..._modelTags, ..._frameworkTags]
          .map((t) => {'slug': t.slug, 'category': t.category})
          .toList();
      final branch = _branchController.text.trim();
      final description = _descriptionController.text.trim();
      final entryPoint = _entryPointController.text.trim();

      await client.hubSubmitAgent(request: {
        'name': name,
        'repo_url': repoUrl,
        if (branch.isNotEmpty) 'branch': branch,
        if (description.isNotEmpty) 'description': description,
        if (_selectedCategory != null) 'category': _selectedCategory,
        if (allTags.isNotEmpty) 'tags_json': jsonEncode(allTags),
        if (entryPoint.isNotEmpty) 'entry_point': entryPoint,
      });

      if (mounted) {
        toast('Submitted -- pending review', type: ToastType.success);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Submission failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = widget.template.sourceType == 'local';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            DialogHeader(children: [
              const DialogTitle(text: 'Submit Agent to Community Hub'),
              const DialogDescription(
                text:
                    'Share your agent with the community. '
                    'Submissions are reviewed before being listed.',
              ),
            ]),

            if (widget.hasUncommittedChanges || widget.hasUnpushedCommits) ...[
              const SizedBox(height: Spacing.md),
              if (widget.hasUncommittedChanges)
                const Alert(
                  variant: AlertVariant.warning,
                  icon: LucideIcons.triangle_alert,
                  children: [
                    AlertTitle(text: 'Uncommitted Changes'),
                    AlertDescription(
                      text:
                          'You have uncommitted changes in your repository. '
                          'Commit and push all changes before submitting.',
                    ),
                  ],
                ),
              if (widget.hasUnpushedCommits) ...[
                if (widget.hasUncommittedChanges)
                  const SizedBox(height: Spacing.sm),
                const Alert(
                  variant: AlertVariant.warning,
                  icon: LucideIcons.triangle_alert,
                  children: [
                    AlertTitle(text: 'Unpushed Commits'),
                    AlertDescription(
                      text:
                          'You have local commits that are not pushed to the remote. '
                          'Push your changes before submitting.',
                    ),
                  ],
                ),
              ],
            ],

            DialogContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Field(
                    label: 'Name',
                    required: true,
                    child: Input(
                      controller: _nameController,
                      placeholder: 'Agent name',
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Description
                  Field(
                    label: 'Description',
                    child: Input(
                      controller: _descriptionController,
                      placeholder: 'What does this agent do?',
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Repo URL
                  Field(
                    label: 'Repository URL',
                    required: true,
                    description: isLocal && widget.detectedRemoteUrl != null
                        ? null
                        : isLocal
                            ? 'Enter a public git repo URL for this agent.'
                            : null,
                    child: Input(
                      controller: _repoUrlController,
                      placeholder: 'https://github.com/org/repo.git',
                    ),
                  ),
                  if (isLocal && widget.detectedRemoteUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: const DspatchBadge(
                        label: 'Detected from git remote',
                        variant: BadgeVariant.success,
                      ),
                    ),
                  const SizedBox(height: Spacing.lg),

                  // Branch
                  Field(
                    label: 'Branch',
                    description: 'Leave empty for default branch.',
                    child: Input(
                      controller: _branchController,
                      placeholder: 'main',
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Entry point
                  Field(
                    label: 'Entry Point',
                    child: Input(
                      controller: _entryPointController,
                      placeholder: 'agent.py',
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Category
                  Field(
                    label: 'Category',
                    child: Select<String>(
                      value: _selectedCategory,
                      hint: 'Select a category...',
                      items: _hubCategories
                          .map((c) => SelectItem(
                                value: c,
                                label: c[0].toUpperCase() +
                                    c.substring(1),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Tags
                  TagAutocompleteInput(
                    category: 'general',
                    label: 'General Tags',
                    selectedTags: _generalTags,
                    onChanged: (tags) =>
                        setState(() => _generalTags = tags),
                  ),
                  const SizedBox(height: Spacing.md),
                  TagAutocompleteInput(
                    category: 'model',
                    label: 'AI Models',
                    selectedTags: _modelTags,
                    onChanged: (tags) =>
                        setState(() => _modelTags = tags),
                  ),
                  const SizedBox(height: Spacing.md),
                  TagAutocompleteInput(
                    category: 'framework',
                    label: 'Frameworks',
                    selectedTags: _frameworkTags,
                    onChanged: (tags) =>
                        setState(() => _frameworkTags = tags),
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
                label: 'Submit',
                icon: LucideIcons.upload,
                loading: _submitting,
                onPressed: _hasGitIssues ? null : _submit,
              ),
            ]),
          ],
        ),
      );
  }
}
