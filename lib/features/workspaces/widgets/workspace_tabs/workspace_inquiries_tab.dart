// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import '../../../../core/utils/datetime_ext.dart';
import 'dart:convert';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/providers.dart';
import '../../../../shared/widgets/markdown_view.dart';
import '../../workspace_controller.dart';

/// Workspace-level inquiries tab with inline response forms.
class WorkspaceInquiriesTab extends ConsumerWidget {
  const WorkspaceInquiriesTab({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(workspaceInquiriesProvider(workspaceId));

    return inquiriesAsync.when(
      data: (inquiries) {
        if (inquiries.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.circle_question_mark,
            title: 'No Inquiries',
            description: 'Agent inquiries will appear here.',
          );
        }

        // Sort: pending first, then by date descending
        final sorted = [...inquiries]..sort((a, b) {
            if (a.status == InquiryStatus.pending &&
                b.status != InquiryStatus.pending) {
              return -1;
            }
            if (b.status == InquiryStatus.pending &&
                a.status != InquiryStatus.pending) {
              return 1;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

        return ContentArea(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.zero,
          child: ListView.builder(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: sorted.length,
            itemBuilder: (context, index) =>
                _InquiryCard(inquiry: sorted[index]),
          ),
        );
      },
      loading: () => const Center(child: Spinner()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _InquiryCard extends ConsumerWidget {
  const _InquiryCard({required this.inquiry});
  final WorkspaceInquiry inquiry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = inquiry.status == InquiryStatus.pending;
    final borderColor = isPending
        ? AppColors.warning.withValues(alpha: 0.4)
        : AppColors.success.withValues(alpha: 0.4);
    final bgColor = isPending
        ? AppColors.warning.withValues(alpha: 0.05)
        : AppColors.success.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isPending ? LucideIcons.circle_question_mark : LucideIcons.circle_check,
                  size: 14,
                  color: isPending ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: Spacing.xs),
                DspatchBadge(
                  label: inquiry.agentKey,
                  variant: BadgeVariant.secondary,
                ),
                const Spacer(),
                DspatchBadge(
                  label: isPending ? 'Pending' : 'Responded',
                  variant:
                      isPending ? BadgeVariant.warning : BadgeVariant.success,
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  inquiry.createdAt.timeAgo(),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            // Forwarding chain
            if (inquiry.forwardingChainJson != null) ...[
              const SizedBox(height: Spacing.xs),
              _ForwardingChainBadges(chainJson: inquiry.forwardingChainJson!),
            ],
            const SizedBox(height: Spacing.sm),

            // Content
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: ClipRect(
                child: MarkdownView(data: inquiry.contentMarkdown),
              ),
            ),

            // Responded inquiry: show response
            if (!isPending && inquiry.responseText != null) ...[
              const SizedBox(height: Spacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.reply,
                            size: 12, color: AppColors.mutedForeground),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(
                            inquiry.responseText!,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (inquiry.respondedByAgentKey != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Responded by: ${inquiry.respondedByAgentKey}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Pending inquiry: show response form
            if (isPending) ...[
              const SizedBox(height: Spacing.sm),
              _InquiryResponseForm(inquiry: inquiry),
            ],
          ],
        ),
      ),
    );
  }
}

class _InquiryResponseForm extends ConsumerStatefulWidget {
  const _InquiryResponseForm({required this.inquiry});
  final WorkspaceInquiry inquiry;

  @override
  ConsumerState<_InquiryResponseForm> createState() =>
      _InquiryResponseFormState();
}

class _InquiryResponseFormState extends ConsumerState<_InquiryResponseForm> {
  final _controller = TextEditingController();
  int? _selectedSuggestion;
  bool _submitting = false;

  List<String> get _suggestions {
    final json = widget.inquiry.suggestionsJson;
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => (e as Map<String, dynamic>)['text'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedSuggestion == null) return;

    // Always resolve the response text so the SDK receives the actual text.
    final String? responseText;
    if (text.isNotEmpty) {
      responseText = text;
    } else if (_selectedSuggestion != null &&
        _selectedSuggestion! < _suggestions.length) {
      responseText = _suggestions[_selectedSuggestion!];
    } else {
      responseText = null;
    }

    setState(() => _submitting = true);
    final success =
        await ref.read(workspaceControllerProvider.notifier).respondToInquiry(
              widget.inquiry.id,
              responseText: responseText,
              responseSuggestionIndex: _selectedSuggestion,
            );
    if (mounted) {
      setState(() => _submitting = false);
      if (success) _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Suggestion chips
        if (suggestions.isNotEmpty) ...[
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              for (var i = 0; i < suggestions.length; i++)
                _SuggestionChip(
                  label: suggestions[i],
                  isSelected: _selectedSuggestion == i,
                  onTap: () {
                    setState(() {
                      _selectedSuggestion =
                          _selectedSuggestion == i ? null : i;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
        ],

        // Text input + submit
        Row(
          children: [
            Expanded(
              child: Input(
                controller: _controller,
                placeholder: 'Type a response...',
                disabled: _submitting,
              ),
            ),
            const SizedBox(width: Spacing.xs),
            Button(
              label: 'Send',
              icon: LucideIcons.send,
              size: ButtonSize.sm,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ],
    );
  }
}

class _ForwardingChainBadges extends StatelessWidget {
  const _ForwardingChainBadges({required this.chainJson});
  final String chainJson;

  @override
  Widget build(BuildContext context) {
    final chain = (jsonDecode(chainJson) as List).cast<String>();
    if (chain.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Text(
          'Bubbled through: ',
          style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
        ),
        ...chain.map((agentId) => Padding(
              padding: const EdgeInsets.only(right: Spacing.xs),
              child: DspatchBadge(
                label: agentId,
                variant: BadgeVariant.outline,
              ),
            )),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.foreground,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
