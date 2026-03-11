import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Alert variants matching shadcn/ui conventions + dspatch extensions.
enum AlertVariant {
  /// Default muted alert.
  defaultVariant,

  /// Red-toned destructive alert.
  destructive,

  /// Blue informational alert.
  info,

  /// Amber warning alert.
  warning,

  /// Green success alert.
  success,
}

/// A themed alert container inspired by shadcn/ui Alert.
///
/// ```dart
/// Alert(
///   variant: AlertVariant.destructive,
///   children: [
///     AlertTitle(text: 'Error'),
///     AlertDescription(text: 'Something went wrong.'),
///   ],
/// )
/// ```
class Alert extends StatelessWidget {
  const Alert({
    super.key,
    this.variant = AlertVariant.defaultVariant,
    this.icon,
    required this.children,
  });

  /// Visual variant.
  final AlertVariant variant;

  /// Optional leading icon override.
  final IconData? icon;

  /// Alert content — typically [AlertTitle] and [AlertDescription].
  final List<Widget> children;

  Color get _color => switch (variant) {
        AlertVariant.defaultVariant => AppColors.foreground,
        AlertVariant.destructive => AppColors.destructive,
        AlertVariant.info => AppColors.info,
        AlertVariant.warning => AppColors.warning,
        AlertVariant.success => AppColors.success,
      };

  IconData get _icon =>
      icon ??
      switch (variant) {
        AlertVariant.defaultVariant => LucideIcons.info,
        AlertVariant.destructive => LucideIcons.circle_alert,
        AlertVariant.info => LucideIcons.info,
        AlertVariant.warning => LucideIcons.triangle_alert,
        AlertVariant.success => LucideIcons.circle_check,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final isDefault = variant == AlertVariant.defaultVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Spacing.md),
      decoration: BoxDecoration(
        color: isDefault
            ? Colors.transparent
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDefault ? AppColors.border : color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Title sub-component for [Alert].
class AlertTitle extends StatelessWidget {
  const AlertTitle({super.key, required this.text});

  /// Title text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

/// Description sub-component for [Alert].
class AlertDescription extends StatelessWidget {
  const AlertDescription({super.key, required this.text});

  /// Description text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.mutedForeground,
      ),
    );
  }
}
