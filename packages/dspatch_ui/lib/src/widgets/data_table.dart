import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A styled table header row.
///
/// Provides the standard muted-text styling for column labels.
/// Pass a [Row] of column widgets as [child].
class TableHeader extends StatelessWidget {
  final Widget child;

  /// Standard text style for header column labels.
  static const headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
  );

  const TableHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

/// A clickable, hoverable table row with a bottom border.
///
/// Pass a [Row] of cell widgets as [child].
class DspatchTableRow extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const DspatchTableRow({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.surfaceHover,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: child,
      ),
    );
  }
}
