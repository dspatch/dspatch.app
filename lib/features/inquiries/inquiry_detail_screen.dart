// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:convert';

import '../../core/extensions/drift_extensions.dart';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../shared/widgets/markdown_view.dart';
import 'widgets/priority_badge.dart';
import 'widgets/suggestion_selector.dart';
import '../workspaces/workspace_controller.dart';

class InquiryDetailScreen extends ConsumerStatefulWidget {
  const InquiryDetailScreen({
    super.key,
    required this.workspaceId,
    required this.inquiryId,
  });

  final String workspaceId;
  final String inquiryId;

  @override
  ConsumerState<InquiryDetailScreen> createState() =>
      _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends ConsumerState<InquiryDetailScreen> {
  int? _selectedSuggestion;
  final _customController = TextEditingController();
  bool _isSubmitting = false;
  static const _customIndex = -1;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller alive while this screen is mounted so the
    // auto-dispose notifier isn't collected mid-async-operation.
    ref.watch(workspaceControllerProvider);

    final inquiryAsync = ref.watch(workspaceInquiryProvider(widget.inquiryId));

    return PopScope(
      canPop: !(_customController.text.trim().isNotEmpty && !_isSubmitting),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text(
              'Discard response?',
              style: TextStyle(color: AppColors.foreground),
            ),
            content: const Text(
              'You have unsaved text. Leave without submitting?',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          context.pop();
        }
      },
      child: inquiryAsync.when(
        data: (inquiry) {
          if (inquiry == null) {
            return ContentArea(
              child: EmptyState(
                icon: LucideIcons.circle_alert,
                title: 'Inquiry Not Found',
                description: 'This inquiry may have been deleted.',
              ),
            );
          }

          final isPending = inquiry.isPending;
        final isExpired = inquiry.isExpired;
        final suggestions = _parseSuggestions(inquiry.suggestionsJson);
        final filePaths = _parseFilePaths(inquiry.attachmentsJson);

        return ContentArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Button(
                    icon: LucideIcons.arrow_left,
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.icon,
                    onPressed: () =>
                        context.go('/workspaces/${widget.workspaceId}'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Expanded(
                    child: Text(
                      'Inquiry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  PriorityBadge(inquiry: inquiry),
                  const SizedBox(width: Spacing.sm),
                  DspatchBadge(
                    label: isExpired
                        ? 'Expired'
                        : isPending
                            ? 'Pending'
                            : 'Responded',
                    variant: isExpired
                        ? BadgeVariant.secondary
                        : isPending
                            ? BadgeVariant.warning
                            : BadgeVariant.success,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question content
                      MarkdownView(data: inquiry.contentMarkdown),
                      const SizedBox(height: Spacing.xl),

                      // Referenced files
                      if (filePaths.isNotEmpty) ...[
                        const Text(
                          'Referenced Files',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        for (final path in filePaths)
                          _buildFileEntry(path),
                        const SizedBox(height: Spacing.md),
                      ],

                      if (isExpired) ...[
                        const Separator(),
                        const SizedBox(height: Spacing.md),
                        const Alert(
                          icon: LucideIcons.timer_off,
                          children: [
                            AlertDescription(
                              text:
                                  'This inquiry expired after 72 hours without a response.',
                            ),
                          ],
                        ),
                      ] else if (isPending) ...[
                        // Suggestions + custom response option
                        if (suggestions.isNotEmpty) ...[
                          const Text(
                            'Suggestions',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          SuggestionSelector(
                            suggestions: [
                              ...suggestions,
                              (text: 'Custom response', isRecommended: false),
                            ],
                            selectedIndex: _selectedSuggestion == _customIndex
                                ? suggestions.length
                                : _selectedSuggestion,
                            onSelected: (index) => setState(() {
                              if (index == suggestions.length) {
                                _selectedSuggestion = _customIndex;
                              } else {
                                _selectedSuggestion = index;
                                _customController.clear();
                              }
                            }),
                          ),
                          if (_selectedSuggestion == _customIndex) ...[
                            const SizedBox(height: Spacing.sm),
                            Input(
                              controller: _customController,
                              maxLines: 4,
                              placeholder: 'Type your response...',
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                          const SizedBox(height: Spacing.lg),
                        ],

                        // Submit button
                        Button(
                          label: _isSubmitting
                              ? 'Submitting...'
                              : 'Submit Response',
                          onPressed: _canSubmit ? () => _submit(suggestions) : null,
                        ),
                      ] else ...[
                        // Show response (read-only)
                        const Separator(),
                        const SizedBox(height: Spacing.md),
                        if (suggestions.isNotEmpty) ...[
                          const Text(
                            'Suggestions',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          SuggestionSelector(
                            suggestions: suggestions,
                            selectedIndex:
                                inquiry.responseSuggestionIndex,
                            onSelected: (_) {},
                            readOnly: true,
                          ),
                          const SizedBox(height: Spacing.md),
                        ],
                        if (inquiry.responseText != null) ...[
                          const Text(
                            'Response',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Alert(
                            variant: AlertVariant.success,
                            children: [
                              AlertDescription(text: inquiry.responseText!),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
        loading: () => const Center(child: Spinner()),
        error: (e, _) => EmptyState(
          icon: LucideIcons.circle_alert,
          title: 'Inquiry Not Found',
          description: '$e',
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      (_selectedSuggestion != null && _selectedSuggestion != _customIndex ||
          _customController.text.trim().isNotEmpty);

  Future<void> _submit(List<({String text, bool isRecommended})> suggestions) async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    // Always resolve the response text — either from custom input or from
    // the selected suggestion — so the SDK always receives the actual text.
    final customText = _customController.text.trim();
    final String? responseText;
    final int? suggestionIndex;

    if (_selectedSuggestion == _customIndex || _selectedSuggestion == null) {
      responseText = customText.isEmpty ? null : customText;
      suggestionIndex = null;
    } else {
      suggestionIndex = _selectedSuggestion;
      responseText = suggestions[_selectedSuggestion!].text;
    }

    try {
      await ref
          .read(workspaceControllerProvider.notifier)
          .respondToInquiry(
            widget.inquiryId,
            responseText: responseText,
            responseSuggestionIndex: suggestionIndex,
          );
    } catch (e) {
      toast('Failed to submit: $e', type: ToastType.error);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<({String text, bool isRecommended})> _parseSuggestions(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = (jsonDecode(json) as List).cast<String>();
      return list.map((e) => (text: e, isRecommended: false)).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> _parseFilePaths(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final paths = map['file_paths'] as List<dynamic>?;
      return paths?.cast<String>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Widget _buildFileEntry(String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.file,
                size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                path,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
