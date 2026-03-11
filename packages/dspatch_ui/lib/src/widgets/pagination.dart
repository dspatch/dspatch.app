import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A pagination component inspired by shadcn/ui Pagination.
///
/// ```dart
/// Pagination(
///   currentPage: 3,
///   totalPages: 10,
///   onPageChanged: (page) => setState(() => _page = page),
/// )
/// ```
class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.siblingCount = 1,
  });

  /// Current active page (1-based).
  final int currentPage;

  /// Total number of pages.
  final int totalPages;

  /// Called when a page is selected.
  final ValueChanged<int> onPageChanged;

  /// Number of sibling pages shown on each side of the current page.
  final int siblingCount;

  List<int?> _getPageNumbers() {
    final pages = <int?>[];
    final leftSibling = (currentPage - siblingCount).clamp(1, totalPages);
    final rightSibling = (currentPage + siblingCount).clamp(1, totalPages);

    final showLeftDots = leftSibling > 2;
    final showRightDots = rightSibling < totalPages - 1;

    if (!showLeftDots && showRightDots) {
      final leftRange = 3 + 2 * siblingCount;
      for (int i = 1; i <= leftRange.clamp(1, totalPages); i++) {
        pages.add(i);
      }
      pages.add(null); // ellipsis
      pages.add(totalPages);
    } else if (showLeftDots && !showRightDots) {
      pages.add(1);
      pages.add(null);
      final rightRange = 3 + 2 * siblingCount;
      for (int i = (totalPages - rightRange + 1).clamp(1, totalPages);
          i <= totalPages;
          i++) {
        pages.add(i);
      }
    } else if (showLeftDots && showRightDots) {
      pages.add(1);
      pages.add(null);
      for (int i = leftSibling; i <= rightSibling; i++) {
        pages.add(i);
      }
      pages.add(null);
      pages.add(totalPages);
    } else {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _getPageNumbers();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button
        _PaginationButton(
          onTap: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
          child: const Icon(LucideIcons.chevron_left, size: 16),
        ),
        const SizedBox(width: 2),
        // Page numbers
        for (final page in pages) ...[
          if (page == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
              child: Icon(
                LucideIcons.ellipsis,
                size: 14,
                color: AppColors.mutedForeground,
              ),
            )
          else
            _PaginationButton(
              active: page == currentPage,
              onTap: () => onPageChanged(page),
              child: Text(
                '$page',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: page == currentPage
                      ? AppColors.primaryForeground
                      : AppColors.foreground,
                ),
              ),
            ),
          const SizedBox(width: 2),
        ],
        // Next button
        _PaginationButton(
          onTap: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          child: const Icon(LucideIcons.chevron_right, size: 16),
        ),
      ],
    );
  }
}

class _PaginationButton extends StatefulWidget {
  const _PaginationButton({
    required this.child,
    this.onTap,
    this.active = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool active;

  @override
  State<_PaginationButton> createState() => _PaginationButtonState();
}

class _PaginationButtonState extends State<_PaginationButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.primary
                : _hovered && !disabled
                    ? AppColors.surfaceHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.active
                  ? AppColors.primary
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: disabled
                    ? AppColors.muted
                    : widget.active
                        ? AppColors.primaryForeground
                        : AppColors.foreground,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
