import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';

/// A single breadcrumb entry.
///
/// When [onTap] is non-null the item is rendered as a clickable link.
/// When null it is treated as the current (non-navigable) page.
class BreadcrumbItem {
  const BreadcrumbItem({required this.label, this.subtitle, this.onTap});

  /// Display text.
  final String label;

  /// Optional subtitle shown after the label on the current page.
  final String? subtitle;

  /// Tap callback. Null means this is the current page.
  final VoidCallback? onTap;
}

/// A horizontal breadcrumb trail inspired by shadcn/ui Breadcrumb.
///
/// ```dart
/// Breadcrumb(
///   items: [
///     BreadcrumbItem(label: 'Home', onTap: () {}),
///     BreadcrumbItem(label: 'Products', onTap: () {}),
///     BreadcrumbItem(label: 'Widget'),
///   ],
/// )
/// ```
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({
    super.key,
    required this.items,
    this.separator,
    this.maxItems,
  });

  /// Breadcrumb entries from root to current page.
  final List<BreadcrumbItem> items;

  /// Custom separator widget (defaults to chevron icon).
  final Widget? separator;

  /// Max visible items before collapsing with ellipsis.
  /// When set, items in the middle are replaced by [BreadcrumbEllipsis].
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final sep = separator ??
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            LucideIcons.chevron_right,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        );

    List<BreadcrumbItem> visible = items;
    bool showEllipsis = false;

    if (maxItems != null && maxItems! >= 2 && items.length > maxItems!) {
      visible = [
        items.first,
        ...items.sublist(items.length - (maxItems! - 1)),
      ];
      showEllipsis = true;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0) sep,
          if (i == 1 && showEllipsis) ...[
            const BreadcrumbEllipsis(),
            sep,
          ],
          _buildItem(visible[i]),
        ],
      ],
    );
  }

  Widget _buildItem(BreadcrumbItem item) {
    if (item.onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: item.onTap,
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (item.subtitle != null) ...[
          const SizedBox(width: 6),
          Text(
            item.subtitle!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}

/// An ellipsis indicator for collapsed breadcrumb items.
class BreadcrumbEllipsis extends StatelessWidget {
  const BreadcrumbEllipsis({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      LucideIcons.ellipsis,
      size: 16,
      color: AppColors.mutedForeground,
    );
  }
}
