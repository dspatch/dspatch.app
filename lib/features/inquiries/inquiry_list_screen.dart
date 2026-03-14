// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../core/extensions/drift_extensions.dart';
import '../../core/utils/datetime_ext.dart';
import '../../database/engine_database.dart';
import '../../models/enums.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';

final _inquiryStatusFilterProvider = StateProvider<InquiryStatus?>((_) => null);

const _kPageSize = 5;

class InquiryListScreen extends ConsumerWidget {
  const InquiryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(_inquiryStatusFilterProvider);
    final inquiriesAsync = ref.watch(allInquiriesProvider);

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Inquiries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              Button(
                label: 'Refresh',
                icon: LucideIcons.refresh_cw,
                variant: ButtonVariant.secondary,
                onPressed: () => ref.invalidate(allInquiriesProvider),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Filter chips
          ToggleGroup(
            type: ToggleGroupType.single,
            style: ToggleGroupStyle.grouped,
            variant: ToggleVariant.primary,
            size: ToggleSize.sm,
            iconMode: false,
            value: {statusFilter?.name ?? 'all'},
            onChanged: (values) {
              final v = values.firstOrNull;
              ref.read(_inquiryStatusFilterProvider.notifier).state =
                  switch (v) {
                'pending' => InquiryStatus.pending,
                'responded' => InquiryStatus.responded,
                'expired' => InquiryStatus.expired,
                _ => null,
              };
            },
            children: const [
              ToggleGroupItem(value: 'all', label: 'All'),
              ToggleGroupItem(value: 'pending', label: 'Pending'),
              ToggleGroupItem(value: 'responded', label: 'Responded'),
              ToggleGroupItem(value: 'expired', label: 'Expired'),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Inquiry list grouped by workspace
          Expanded(
            child: inquiriesAsync.when(
              data: (items) {
                final filtered = statusFilter == null
                    ? items
                    : items
                        .where((i) =>
                            i.status == statusFilter.name ||
                            (statusFilter == InquiryStatus.responded &&
                                i.isDelivered))
                        .toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.circle_question_mark,
                    title: 'No Inquiries',
                    description:
                        'Agent inquiries will appear here when agents need your input.',
                  );
                }

                // Already sorted by created_at DESC from the DAO.
                // Group by runId, preserving order of first appearance.
                final groupOrder = <String>[];
                final groupNames = <String, String>{};
                final grouped = <String, List<WorkspaceInquiry>>{};
                for (final item in filtered) {
                  final wId = item.runId;
                  if (!grouped.containsKey(wId)) {
                    groupOrder.add(wId);
                    groupNames[wId] = item.agentKey;
                  }
                  grouped.putIfAbsent(wId, () => []).add(item);
                }

                return ListView.separated(
                  itemCount: groupOrder.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.lg),
                  itemBuilder: (context, index) {
                    final wId = groupOrder[index];
                    return _WorkspaceSection(
                      workspaceId: wId,
                      workspaceName: groupNames[wId]!,
                      inquiries: grouped[wId]!,
                    );
                  },
                );
              },
              loading: () => const Center(child: Spinner()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workspace section ──

class _WorkspaceSection extends ConsumerStatefulWidget {
  const _WorkspaceSection({
    required this.workspaceId,
    required this.workspaceName,
    required this.inquiries,
  });

  final String workspaceId;
  final String workspaceName;
  final List<WorkspaceInquiry> inquiries;

  @override
  ConsumerState<_WorkspaceSection> createState() => _WorkspaceSectionState();
}

class _WorkspaceSectionState extends ConsumerState<_WorkspaceSection> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant _WorkspaceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceName != widget.workspaceName) {
      _page = 0;
    }
    // Clamp page if data shrunk.
    final maxPage = (widget.inquiries.length - 1) ~/ _kPageSize;
    if (_page > maxPage) _page = maxPage;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.workspaceName;
    final total = widget.inquiries.length;
    final totalPages = (total / _kPageSize).ceil();
    final start = _page * _kPageSize;
    final end = (start + _kPageSize).clamp(0, total);
    final visible = widget.inquiries.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              DspatchBadge(
                label: '$total',
                variant: BadgeVariant.secondary,
              ),
            ],
          ),
        ),

        // Inquiry cards
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          _InquiryListCard(
            inquiry: visible[i],
            onTap: () => context.go(
              '/workspaces/${widget.workspaceId}/inquiries/${visible[i].id}',
            ),
          ),
        ],

        // Pagination controls
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Row(
              children: [
                Button(
                  label: 'Previous',
                  icon: LucideIcons.chevron_left,
                  variant: ButtonVariant.ghost,
                  size: ButtonSize.sm,
                  onPressed: _page > 0
                      ? () => setState(() => _page--)
                      : null,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '${_page + 1} / $totalPages',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontFamily: AppFonts.mono,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Button(
                  label: 'Next',
                  icon: LucideIcons.chevron_right,
                  variant: ButtonVariant.ghost,
                  size: ButtonSize.sm,
                  onPressed: _page < totalPages - 1
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Inquiry card ──

class _InquiryListCard extends StatelessWidget {
  const _InquiryListCard({required this.inquiry, this.onTap});

  final WorkspaceInquiry inquiry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPending = inquiry.isPending;
    final isExpired = inquiry.isExpired;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: DspatchCard(
          child: Row(
            children: [
              // Status icon
              Icon(
                isExpired
                    ? LucideIcons.timer_off
                    : isPending
                        ? LucideIcons.circle_question_mark
                        : LucideIcons.circle_check,
                color: isExpired
                    ? AppColors.mutedForeground
                    : isPending
                        ? AppColors.warning
                        : AppColors.success,
                size: 14,
              ),
              const SizedBox(width: Spacing.sm),

              // Priority badge
              if (inquiry.isHighPriority)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.sm),
                  child: DspatchBadge(
                    label: 'High',
                    variant: BadgeVariant.destructive,
                  ),
                ),

              // Status badge
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
              const SizedBox(width: Spacing.sm),

              // Agent badge
              DspatchBadge(
                label: inquiry.agentKey,
                variant: BadgeVariant.outline,
              ),
              const SizedBox(width: Spacing.md),

              // Content preview
              Expanded(
                child: Text(
                  inquiry.contentMarkdown.replaceAll('\n', ' '),
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Time ago
              Text(
                inquiry.createdAtDate.timeAgo(),
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
