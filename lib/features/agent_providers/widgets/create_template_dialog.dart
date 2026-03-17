// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/engine_database.dart' show AgentProvider;
import '../../../di/providers.dart';
import '../../../models/commands/commands.dart';

class CreateTemplateDialog extends ConsumerStatefulWidget {
  const CreateTemplateDialog({super.key});

  @override
  ConsumerState<CreateTemplateDialog> createState() =>
      _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<CreateTemplateDialog> {
  AgentProvider? _selectedProvider;
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(agentProvidersProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DialogHeader(children: [
          const DialogTitle(text: 'Create Template'),
          const DialogDescription(
            text: 'Create a configuration preset from an existing provider.',
          ),
        ]),
        DialogContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Source Provider',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: Spacing.xs),
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
                      'No providers available.',
                      style: TextStyle(
                          color: AppColors.mutedForeground, fontSize: 12),
                    );
                  }
                  return Select<String>(
                    value: _selectedProvider?.id,
                    hint: 'Select a provider...',
                    items: providers
                        .map((p) => SelectItem(
                              value: p.id,
                              label: p.name,
                            ))
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final provider =
                          providers.firstWhere((p) => p.id == id);
                      setState(() {
                        _selectedProvider = provider;
                        if (_nameController.text.isEmpty) {
                          _nameController.text =
                              'My ${provider.name} Template';
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: Spacing.md),
              const Text(
                'Template Name',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Input(
                controller: _nameController,
                placeholder: 'My Template',
              ),
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
            label: 'Create',
            loading: _isCreating,
            onPressed: _selectedProvider == null ? null : _create,
          ),
        ]),
      ],
    );
  }

  Future<void> _create() async {
    setState(() => _isCreating = true);
    try {
      final provider = _selectedProvider!;
      final author = provider.hubAuthor;
      final slug = provider.hubSlug;

      final sourceUri = (author != null && slug != null)
          ? 'dspatch://agent/$author/$slug'
          : 'local://${provider.id}';

      final client = ref.read(engineClientProvider);
      final result = await client.send(CreateAgentTemplate(
        name: _nameController.text.trim(),
        sourceUri: sourceUri,
      ));
      if (mounted) {
        Navigator.of(context).pop();
        toast('Template created',
            description: result.raw['file_path'] as String? ?? '');
      }
    } catch (e) {
      toast('Failed to create template: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
