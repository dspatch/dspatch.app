import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A styled tooltip inspired by shadcn/ui Tooltip.
///
/// ```dart
/// DspatchTooltip(
///   message: 'Delete this item',
///   child: IconButton(icon: Icon(LucideIcons.trash_2), onPressed: () {}),
/// )
/// ```
class DspatchTooltip extends StatelessWidget {
  const DspatchTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
  });

  /// Tooltip text.
  final String message;

  /// Widget that triggers the tooltip on hover.
  final Widget child;

  /// Whether to prefer showing below the child.
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      decoration: BoxDecoration(
        color: AppColors.popover,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      textStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.popoverForeground,
        fontFamily: AppFonts.sans,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
      waitDuration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
