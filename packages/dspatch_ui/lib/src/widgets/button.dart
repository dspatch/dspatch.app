import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Button variants matching shadcn/ui conventions.
enum ButtonVariant {
  /// Primary filled button with accent color (shadcn "default").
  primary,

  /// Secondary filled button with muted background.
  secondary,

  /// Transparent button with border.
  outline,

  /// Transparent button, visible on hover.
  ghost,

  /// Red-toned button for dangerous actions.
  destructive,

  /// Text link style.
  link,

  /// Accent-colored filled variant (dspatch extension).
  accentOutline,
}

/// Button size presets.
enum ButtonSize {
  /// Extra small — 28 px tall.
  xs,

  /// Small — 32 px tall.
  sm,

  /// Default — 36 px tall.
  md,

  /// Large — 40 px tall.
  lg,

  /// Square icon-only — 36 × 36 px.
  icon,
}

/// A versatile button inspired by shadcn/ui Button.
///
/// ```dart
/// Button(label: 'Save', onPressed: () {})
///
/// Button(
///   variant: ButtonVariant.outline,
///   size: ButtonSize.sm,
///   icon: LucideIcons.plus,
///   label: 'Add',
///   onPressed: () {},
/// )
///
/// Button(
///   variant: ButtonVariant.ghost,
///   size: ButtonSize.icon,
///   icon: LucideIcons.ellipsis_vertical,
///   onPressed: () {},
/// )
/// ```
class Button extends StatelessWidget {
  const Button({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.lg,
    this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  /// Text label displayed on the button.
  final String? label;

  /// Custom child widget. When set, [label] is ignored.
  final Widget? child;

  /// Leading icon.
  final IconData? icon;

  /// Visual variant.
  final ButtonVariant variant;

  /// Size preset.
  final ButtonSize size;

  /// Tap callback. When null the button appears disabled.
  final VoidCallback? onPressed;

  /// Shows a spinner and disables interaction.
  final bool loading;

  /// Legacy compact mode — maps to [ButtonSize.sm]. Use [size] instead.
  final bool compact;

  ButtonSize get _effectiveSize => compact ? ButtonSize.sm : size;

  @override
  Widget build(BuildContext context) {
    final sz = _effectiveSize;
    final iconSize = sz == ButtonSize.xs ? 14.0 : 16.0;
    final fg = _foregroundColor;

    Widget content;
    if (sz == ButtonSize.icon) {
      content = loading
          ? _spinner(iconSize, fg)
          : Icon(icon, size: iconSize);
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            _spinner(14, fg)
          else if (icon != null)
            Icon(icon, size: iconSize),
          if ((icon != null || loading) && (label != null || child != null))
            const SizedBox(width: 6),
          if (child != null)
            child!
          else if (label != null)
            Text(label!),
        ],
      );
    }

    return TextButton(
      onPressed: loading ? null : onPressed,
      style: _buildStyle(sz),
      child: content,
    );
  }

  static Widget _spinner(double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Color get _foregroundColor => switch (variant) {
        ButtonVariant.primary => AppColors.primaryForeground,
        ButtonVariant.secondary => AppColors.secondaryForeground,
        ButtonVariant.outline => AppColors.foreground,
        ButtonVariant.ghost => AppColors.foreground,
        ButtonVariant.destructive => AppColors.destructiveForeground,
        ButtonVariant.link => AppColors.primary,
        ButtonVariant.accentOutline => AppColors.primaryForeground,
      };

  ButtonStyle _buildStyle(ButtonSize sz) {
    final padding = switch (sz) {
      ButtonSize.xs =>
        const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      ButtonSize.sm =>
        const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
      ButtonSize.md =>
        const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 10),
      ButtonSize.lg =>
        const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.md),
      ButtonSize.icon => EdgeInsets.zero,
    };

    final minSize = switch (sz) {
      ButtonSize.xs => const Size(0, 28),
      ButtonSize.sm => const Size(0, 32),
      ButtonSize.md => const Size(0, 36),
      ButtonSize.lg => const Size(0, 40),
      ButtonSize.icon => const Size(36, 36),
    };

    final fontSize = switch (sz) {
      ButtonSize.xs => 12.0,
      ButtonSize.sm || ButtonSize.md || ButtonSize.icon => 13.0,
      ButtonSize.lg => 14.0,
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    final textStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500);

    final base = ButtonStyle(
      shape: WidgetStatePropertyAll(shape),
      padding: WidgetStatePropertyAll(padding),
      minimumSize: WidgetStatePropertyAll(minSize),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(textStyle),
      elevation: const WidgetStatePropertyAll(0),
    );

    return switch (variant) {
      ButtonVariant.primary => base.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primaryForeground),
        ),
      ButtonVariant.secondary => base.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.secondary),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.secondaryForeground),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
          ),
        ),
      ButtonVariant.ghost => base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.surfaceHover;
            }
            return Colors.transparent;
          }),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.foreground),
        ),
      ButtonVariant.destructive => base.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.destructive),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.destructiveForeground),
        ),
      ButtonVariant.outline => base.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.foreground),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.input, width: 1),
            ),
          ),
        ),
      ButtonVariant.link => base.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primary),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          minimumSize: const WidgetStatePropertyAll(Size.zero),
        ),
      ButtonVariant.accentOutline => base.copyWith(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.accentMuted),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primaryForeground),
        ),
    };
  }
}
