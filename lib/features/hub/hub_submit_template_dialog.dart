// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:convert';
import 'dart:io';

import 'package:dspatch_sdk/dspatch_sdk.dart' show AgentTemplate, HubTagRef;
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
/// Unlike [HubSubmitAgentDialog], this does not require git repo fields — the
/// template config YAML is read from disk and submitted directly.
class HubSubmitTemplateDialog extends ConsumerStatefulWidget {
  const HubSubmitTemplateDialog({super.key, required this.template});

  final AgentTemplate template;

  @override
  ConsumerState<HubSubmitTemplateDialog> createState() =>
      _HubSubmitTemplateDialogState();
}

class _HubSubmitTemplateDialogState
    extends ConsumerState<HubSubmitTemplateDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  String? _selectedCategory;
  Set<HubTagRef> _generalTags = {};
  Set<HubTagRef> _modelTags = {};
  Set<HubTagRef> _frameworkTags = {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    // Read the config YAML from disk.
    final file = File(widget.template.filePath);
    if (!file.existsSync()) {
      setState(
          () => _error = 'Config file not found: ${widget.template.filePath}');
      return;
    }
    final configYaml = await file.readAsString();

    final sourceUri = widget.template.sourceUri;
    if (!sourceUri.startsWith('dspatch://agent/')) {
      setState(() => _error = 'Invalid source URI: $sourceUri');
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
      final description = _descController.text.trim();

      await client.hubSubmitTemplate(request: {
        'name': name,
        'config_yaml': configYaml,
        'source_slug': sourceUri,
        if (description.isNotEmpty) 'description': description,
        if (_selectedCategory != null) 'category': _selectedCategory,
        if (allTags.isNotEmpty) 'tags_json': jsonEncode(allTags),
      });

      if (mounted) {
        toast('Template submitted — pending review', type: ToastType.success);
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogHeader(children: [
            const DialogTitle(text: 'Submit Template to Community Hub'),
            const DialogDescription(
              text: 'Share your template configuration with the community. '
                  'Submissions are reviewed before being listed.',
            ),
          ]),

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
                    placeholder: 'Template name',
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // Description
                Field(
                  label: 'Description',
                  child: Input(
                    controller: _descController,
                    placeholder: 'What does this template do?',
                    maxLines: 3,
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
                              label: c[0].toUpperCase() + c.substring(1),
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

                // Source info
                const SizedBox(height: Spacing.lg),
                Text(
                  'Source: ${widget.template.sourceUri}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
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
              label: 'Submit',
              icon: LucideIcons.upload,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ]),
        ],
      ),
    );
  }
}
