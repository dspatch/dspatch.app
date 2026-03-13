// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_engine/dspatch_engine.dart';
import 'package:dspatch_ui/dspatch_ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../shared/widgets/confirm_delete_dialog.dart';
import 'controllers/api_key_controller.dart';

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(apiKeysProvider);

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Button(
                icon: LucideIcons.arrow_left,
                variant: ButtonVariant.ghost,
                onPressed: () => context.go('/settings'),
              ),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'API Keys',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              Button(
                label: 'Add API Key',
                icon: LucideIcons.plus,
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: keys.when(
              loading: () => const Center(child: Spinner()),
              error: (e, _) => ErrorStateView(
                message: 'Error loading keys: $e',
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: LucideIcons.key,
                    title: 'No API keys yet',
                    description:
                        'Add API keys to use in provider environment variables.',
                    actions: [
                      Button(
                        label: 'Add API Key',
                        icon: LucideIcons.plus,
                        onPressed: () => _showAddDialog(context, ref),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) =>
                      _ApiKeyCard(apiKey: list[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    DspatchDialog.show(
      context: context,
      builder: (ctx) => const _AddApiKeyDialog(),
    );
  }
}

class _ApiKeyCard extends ConsumerWidget {
  final ApiKey apiKey;

  const _ApiKeyCard({required this.apiKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DspatchCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      apiKey.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    DspatchBadge(
                      label: apiKey.providerLabel,
                      variant: BadgeVariant.outline,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  apiKey.displayHint ?? _fallbackMask,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: AppFonts.mono,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Button(
            icon: LucideIcons.copy,
            variant: ButtonVariant.ghost,
            onPressed: () => _copyKey(ref),
          ),
          Button(
            icon: LucideIcons.trash_2,
            variant: ButtonVariant.ghost,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  /// Fallback mask for keys created before displayHint was added.
  static const _fallbackMask = '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022...\u2022\u2022\u2022\u2022';

  Future<void> _copyKey(WidgetRef ref) async {
    final controller = ref.read(apiKeyControllerProvider.notifier);
    final plaintext = await controller.decryptApiKey(apiKey.encryptedKey);
    if (plaintext != null) {
      await Clipboard.setData(ClipboardData(text: plaintext));
      toast('API key copied to clipboard', type: ToastType.success);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: 'Delete API Key',
      description: 'Delete "${apiKey.name}"? This cannot be undone.',
    );
    if (confirmed) {
      ref.read(apiKeyControllerProvider.notifier).deleteApiKey(apiKey.id);
    }
  }
}

class _AddApiKeyDialog extends ConsumerStatefulWidget {
  const _AddApiKeyDialog();

  @override
  ConsumerState<_AddApiKeyDialog> createState() => _AddApiKeyDialogState();
}

class _AddApiKeyDialogState extends ConsumerState<_AddApiKeyDialog> {
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  String _providerLabel = 'OpenAI';

  static const _providerLabels = [
    'OpenAI',
    'Anthropic',
    'Google',
    'Mistral',
    'Cohere',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final key = _keyController.text.trim();
    if (name.isEmpty || key.isEmpty) {
      toast('Name and key are required', type: ToastType.error);
      return;
    }
    final controller = ref.read(apiKeyControllerProvider.notifier);
    final success = await controller.createApiKey(
      name: name,
      providerLabel: _providerLabel,
      plaintext: key,
    );
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(apiKeyControllerProvider).isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DialogHeader(children: [
          DialogTitle(text: 'Add API Key'),
          DialogDescription(
            text: 'The key will be encrypted with AES-256-GCM.',
          ),
        ]),
        DialogContent(
          child: Column(
            children: [
              Field(
                label: 'Name',
                required: true,
                child: Input(
                  controller: _nameController,
                  placeholder: 'e.g. My OpenAI Key',
                  autofocus: true,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Field(
                label: 'Provider',
                child: Select<String>(
                  value: _providerLabel,
                  items: _providerLabels
                      .map((l) => SelectItem(value: l, label: l))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _providerLabel = v);
                  },
                ),
              ),
              const SizedBox(height: Spacing.md),
              Field(
                label: 'API Key',
                required: true,
                child: Input(
                  controller: _keyController,
                  placeholder: 'sk-...',
                  obscureText: true,
                ),
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
            label: 'Save',
            loading: isLoading,
            onPressed: _save,
          ),
        ]),
      ],
    );
  }
}
