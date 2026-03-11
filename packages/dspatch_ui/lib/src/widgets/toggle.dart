import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Toggle button variants.
enum ToggleVariant {
  /// Transparent background, hover highlight.
  defaultVariant,

  /// Border outline.
  outline,

  /// Primary accent color when pressed.
  primary,

  /// Secondary muted color when pressed.
  secondary,

  /// Red-toned when pressed.
  destructive,

  /// Transparent, subtle hover.
  ghost,

  /// Accent-colored when pressed (dspatch extension).
  accentOutline,
}

/// Toggle button sizes.
enum ToggleSize { sm, md, lg }

/// An on/off toggle button inspired by shadcn/ui Toggle.
///
/// ```dart
/// Toggle(
///   pressed: _bold,
///   onChanged: (v) => setState(() => _bold = v),
///   child: Icon(LucideIcons.bold),
/// )
///
/// Toggle(
///   pressed: _value,
///   iconMode: false,
///   variant: ToggleVariant.primary,
///   onChanged: (v) => setState(() => _value = v),
///   child: Text('Center'),
/// )
/// ```
class Toggle extends StatelessWidget {
  const Toggle({
    super.key,
    required this.pressed,
    this.onChanged,
    this.variant = ToggleVariant.defaultVariant,
    this.size = ToggleSize.md,
    this.iconMode = true,
    required this.child,
  });

  /// Whether currently pressed.
  final bool pressed;

  /// Called when toggled.
  final ValueChanged<bool>? onChanged;

  /// Visual variant.
  final ToggleVariant variant;

  /// Size preset.
  final ToggleSize size;

  /// When true (default), renders as a fixed square for icons or single
  /// characters. When false, uses horizontal padding for text labels.
  final bool iconMode;

  /// Content (typically an icon or text).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dim = switch (size) {
      ToggleSize.sm => 32.0,
      ToggleSize.md => 36.0,
      ToggleSize.lg => 40.0,
    };

    final bgColor = pressed ? _pressedBg : Colors.transparent;
    final fgColor = pressed ? _pressedFg : AppColors.mutedForeground;

    final border = variant == ToggleVariant.outline
        ? Border.all(color: AppColors.input, width: 1)
        : null;

    final hPadding = switch (size) {
      ToggleSize.sm => Spacing.sm,
      ToggleSize.md => Spacing.md,
      ToggleSize.lg => Spacing.lg,
    };

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!pressed) : null,
      child: MouseRegion(
        cursor: onChanged != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: iconMode ? dim : null,
          height: dim,
          padding:
              iconMode ? null : EdgeInsets.symmetric(horizontal: hPadding),
          decoration: BoxDecoration(
            color: bgColor,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: IconTheme(
            data: IconThemeData(color: fgColor, size: 16),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fgColor,
                fontFamily: AppFonts.sans,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Color get _pressedBg => switch (variant) {
        ToggleVariant.defaultVariant => AppColors.surfaceHover,
        ToggleVariant.outline => AppColors.surfaceHover,
        ToggleVariant.primary => AppColors.primary,
        ToggleVariant.secondary => AppColors.secondary,
        ToggleVariant.destructive => AppColors.destructive,
        ToggleVariant.ghost => AppColors.surfaceHover,
        ToggleVariant.accentOutline => AppColors.accentMuted,
      };

  Color get _pressedFg => switch (variant) {
        ToggleVariant.defaultVariant => AppColors.foreground,
        ToggleVariant.outline => AppColors.foreground,
        ToggleVariant.primary => AppColors.primaryForeground,
        ToggleVariant.secondary => AppColors.secondaryForeground,
        ToggleVariant.destructive => AppColors.destructiveForeground,
        ToggleVariant.ghost => AppColors.foreground,
        ToggleVariant.accentOutline => AppColors.primaryForeground,
      };
}
