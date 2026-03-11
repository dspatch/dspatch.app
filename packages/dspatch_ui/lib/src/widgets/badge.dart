import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Badge variants matching shadcn/ui conventions plus dspatch extensions.
enum BadgeVariant {
  /// Accent-filled badge.
  primary,

  /// Muted background with border.
  secondary,

  /// Red-toned for errors / destructive status.
  destructive,

  /// Transparent with border only.
  outline,

  /// Green semantic status (dspatch extension).
  success,

  /// Amber semantic status (dspatch extension).
  warning,

  /// Blue semantic status (dspatch extension).
  info,
}

/// A small status indicator inspired by shadcn/ui Badge.
///
/// ```dart
/// DspatchBadge(label: 'New')
/// DspatchBadge(label: 'Error', variant: BadgeVariant.destructive, icon: LucideIcons.circle_alert)
/// ```
class DspatchBadge extends StatelessWidget {
  const DspatchBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.secondary,
    this.icon,
  });

  /// Text displayed inside the badge.
  final String label;

  /// Visual variant.
  final BadgeVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: border != null ? Border.all(color: border, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: Spacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
              fontFamily: AppFonts.mono,
            ),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg, Color? border) _colors() {
    return switch (variant) {
      BadgeVariant.primary => (
          AppColors.primary,
          AppColors.primaryForeground,
          null,
        ),
      BadgeVariant.secondary => (
          AppColors.secondary,
          AppColors.secondaryForeground,
          AppColors.border,
        ),
      BadgeVariant.destructive => (
          AppColors.destructive.withValues(alpha: 0.15),
          AppColors.destructive,
          null,
        ),
      BadgeVariant.outline => (
          Colors.transparent,
          AppColors.foreground,
          AppColors.border,
        ),
      BadgeVariant.success => (
          AppColors.success.withValues(alpha: 0.15),
          AppColors.success,
          null,
        ),
      BadgeVariant.warning => (
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning,
          null,
        ),
      BadgeVariant.info => (
          AppColors.info.withValues(alpha: 0.15),
          AppColors.info,
          null,
        ),
    };
  }
}
