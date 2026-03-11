import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'button.dart';

/// Color variant for [AlertBanner].
enum AlertBannerVariant { info, warning, success, destructive }

/// A themed alert banner with icon, label, optional metadata, and action button.
///
/// Can render as a standard rounded card or as a bottom bar (no border-radius,
/// top border only) via [isBottomBar].
class AlertBanner extends StatelessWidget {
  /// The text label to display.
  final String label;

  /// The action button label.
  final String buttonLabel;

  /// Called when the action button is pressed.
  final VoidCallback onPressed;

  /// Optional metadata text shown after the label (e.g. "Step 2/5").
  final String? metaText;

  /// Whether to render as a bottom bar (no border-radius, top border only).
  final bool isBottomBar;

  /// Color variant controlling the banner's color scheme.
  final AlertBannerVariant variant;

  /// Override the default icon for the variant.
  final IconData? icon;

  const AlertBanner({
    super.key,
    required this.label,
    required this.buttonLabel,
    required this.onPressed,
    this.metaText,
    this.isBottomBar = false,
    this.variant = AlertBannerVariant.warning,
    this.icon,
  });

  Color get _color => switch (variant) {
        AlertBannerVariant.info => AppColors.info,
        AlertBannerVariant.warning => AppColors.warning,
        AlertBannerVariant.success => AppColors.success,
        AlertBannerVariant.destructive => AppColors.destructive,
      };

  IconData get _icon =>
      icon ??
      switch (variant) {
        AlertBannerVariant.info => LucideIcons.info,
        AlertBannerVariant.warning => LucideIcons.triangle_alert,
        AlertBannerVariant.success => LucideIcons.circle_check,
        AlertBannerVariant.destructive => LucideIcons.circle_alert,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: isBottomBar ? 8 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius:
            isBottomBar ? null : BorderRadius.circular(AppRadius.md),
        border: isBottomBar
            ? Border(
                top: BorderSide(color: color.withValues(alpha: 0.25)))
            : Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_icon, size: isBottomBar ? 14 : 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isBottomBar ? color : null,
                fontWeight: isBottomBar ? FontWeight.w500 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (metaText != null) ...[
            const SizedBox(width: 8),
            Text(
              metaText!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
                fontFamily: AppFonts.mono,
              ),
            ),
          ],
          Button(
            variant: ButtonVariant.ghost,
            label: buttonLabel,
            compact: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
