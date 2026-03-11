// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

/// A horizontal strip of hub items with a section header.
/// Used on both workspace and agent template list screens.
class HubStrip<T> extends StatelessWidget {
  const HubStrip({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.onBrowseAll,
    this.onRefresh,
  });

  final List<T> items;
  final Widget Function(T item) cardBuilder;
  final VoidCallback onBrowseAll;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Row(
          children: [
            const Icon(LucideIcons.globe,
                size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: Spacing.xs),
            const Text(
              'Community Hub',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(LucideIcons.refresh_cw,
                    size: 14, color: AppColors.mutedForeground),
                iconSize: 14,
                splashRadius: 16,
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onRefresh,
              ),
            Button(
              label: 'Browse All',
              variant: ButtonVariant.ghost,
              size: ButtonSize.sm,
              onPressed: onBrowseAll,
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),

        // Horizontal card list
        SizedBox(
          height: 120,
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'No community items yet.',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: Spacing.sm),
                  itemBuilder: (_, index) => cardBuilder(items[index]),
                ),
        ),
      ],
    );
  }
}

/// A responsive grid of hub items with a section header.
/// Used on the main overview screens as an alternative to [HubStrip].
class HubTileGrid<T> extends StatelessWidget {
  const HubTileGrid({
    super.key,
    required this.items,
    required this.tileBuilder,
    required this.onBrowseAll,
    this.onRefresh,
  });

  final List<T> items;
  final Widget Function(T item) tileBuilder;
  final VoidCallback onBrowseAll;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Row(
          children: [
            const Icon(LucideIcons.globe,
                size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: Spacing.xs),
            const Text(
              'Community Hub',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(LucideIcons.refresh_cw,
                    size: 14, color: AppColors.mutedForeground),
                iconSize: 14,
                splashRadius: 16,
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onRefresh,
              ),
            Button(
              label: 'Browse All',
              variant: ButtonVariant.ghost,
              size: ButtonSize.sm,
              onPressed: onBrowseAll,
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),

        // Grid content
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.xl),
            child: Center(
              child: Text(
                'No community items yet.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth > 800
                  ? 4
                  : maxWidth > 500
                      ? 3
                      : 2;
              final tileWidth =
                  (maxWidth - (columns - 1) * Spacing.sm) / columns;

              return Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: tileWidth,
                      child: tileBuilder(item),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
