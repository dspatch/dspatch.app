import 'package:flutter/material.dart' hide IconButton;

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Visual variants for [DspatchIconButton].
enum IconButtonVariant {
  /// Filled with accent color.
  primary,

  /// Muted background with border.
  secondary,

  /// Transparent with border.
  outline,

  /// Transparent, visible on hover.
  ghost,

  /// Red-toned for dangerous actions.
  destructive,

  /// Text link style — no background, accent foreground.
  link,

  /// Accent-colored filled variant (dspatch extension).
  accentOutline,
}

/// Size presets for [DspatchIconButton].
enum IconButtonSize {
  /// 28 px diameter.
  sm,

  /// 36 px diameter.
  md,

  /// 44 px diameter.
  lg,
}

/// A perfectly round icon button with variants, sizes, and loading support.
///
/// Provides hover-scale and press-scale micro-interactions for tactile
/// feedback.
///
/// ```dart
/// DspatchIconButton(
///   icon: LucideIcons.plus,
///   onPressed: () {},
/// )
///
/// DspatchIconButton(
///   icon: LucideIcons.trash_2,
///   variant: IconButtonVariant.destructive,
///   loading: true,
///   onPressed: () {},
/// )
/// ```
class DspatchIconButton extends StatefulWidget {
  const DspatchIconButton({
    super.key,
    required this.icon,
    this.variant = IconButtonVariant.primary,
    this.size = IconButtonSize.md,
    this.onPressed,
    this.loading = false,
    this.tooltip,
    this.badge,
  });

  /// The icon to display.
  final IconData icon;

  /// Visual variant.
  final IconButtonVariant variant;

  /// Size preset.
  final IconButtonSize size;

  /// Tap callback. When null the button appears disabled.
  final VoidCallback? onPressed;

  /// Shows a spinner and disables interaction.
  final bool loading;

  /// Optional tooltip shown on long-press / hover.
  final String? tooltip;

  /// Optional badge text shown as a notification dot (top-right).
  ///
  /// Pass an empty string for a plain dot, or a number string like `'3'`.
  final String? badge;

  @override
  State<DspatchIconButton> createState() => _DspatchIconButtonState();
}

class _DspatchIconButtonState extends State<DspatchIconButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );
    if (widget.loading) _loadingController.repeat();
  }

  @override
  void didUpdateWidget(covariant DspatchIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !oldWidget.loading) {
      _loadingController.repeat();
    } else if (!widget.loading && oldWidget.loading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  // ── Dimensions ──────────────────────────────────────────────────────

  double get _diameter => switch (widget.size) {
        IconButtonSize.sm => 28.0,
        IconButtonSize.md => 36.0,
        IconButtonSize.lg => 44.0,
      };

  double get _iconSize => switch (widget.size) {
        IconButtonSize.sm => 14.0,
        IconButtonSize.md => 18.0,
        IconButtonSize.lg => 22.0,
      };

  double get _spinnerSize => switch (widget.size) {
        IconButtonSize.sm => 12.0,
        IconButtonSize.md => 16.0,
        IconButtonSize.lg => 20.0,
      };

  double get _spinnerStroke => _spinnerSize > 14 ? 2.0 : 1.5;

  // ── Colors ──────────────────────────────────────────────────────────

  Color get _backgroundColor => switch (widget.variant) {
        IconButtonVariant.primary => AppColors.primary,
        IconButtonVariant.secondary => AppColors.secondary,
        IconButtonVariant.outline => Colors.transparent,
        IconButtonVariant.ghost => Colors.transparent,
        IconButtonVariant.destructive => AppColors.destructive,
        IconButtonVariant.link => Colors.transparent,
        IconButtonVariant.accentOutline => AppColors.accentMuted,
      };

  Color get _hoveredBackground => switch (widget.variant) {
        IconButtonVariant.primary => AppColors.primary.withValues(alpha: 0.85),
        IconButtonVariant.secondary =>
          AppColors.secondary.withValues(alpha: 0.85),
        IconButtonVariant.outline => AppColors.surfaceHover,
        IconButtonVariant.ghost => AppColors.surfaceHover,
        IconButtonVariant.destructive =>
          AppColors.destructive.withValues(alpha: 0.85),
        IconButtonVariant.link => Colors.transparent,
        IconButtonVariant.accentOutline =>
          AppColors.accentMuted.withValues(alpha: 0.85),
      };

  Color get _foregroundColor => switch (widget.variant) {
        IconButtonVariant.primary => AppColors.primaryForeground,
        IconButtonVariant.secondary => AppColors.secondaryForeground,
        IconButtonVariant.outline => AppColors.foreground,
        IconButtonVariant.ghost => AppColors.foreground,
        IconButtonVariant.destructive => AppColors.destructiveForeground,
        IconButtonVariant.link => AppColors.primary,
        IconButtonVariant.accentOutline => AppColors.primaryForeground,
      };

  Color? get _borderColor => switch (widget.variant) {
        IconButtonVariant.secondary => AppColors.border,
        IconButtonVariant.outline => AppColors.input,
        _ => null,
      };

  // ── Scale ───────────────────────────────────────────────────────────

  double get _scale {
    if (_pressed) return 0.92;
    if (_hovered) return 1.06;
    return 1.0;
  }

  // ── Enabled ─────────────────────────────────────────────────────────

  bool get _enabled => !widget.loading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final dim = _diameter;
    final fg = _foregroundColor;
    final bg = _hovered && _enabled ? _hoveredBackground : _backgroundColor;
    final border = _borderColor;
    final disabledOpacity = _enabled ? 1.0 : 0.5;

    Widget button = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: disabledOpacity,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border != null
                ? Border.all(color: border, width: 1)
                : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: widget.loading
                  ? SizedBox(
                      key: const ValueKey('spinner'),
                      width: _spinnerSize,
                      height: _spinnerSize,
                      child: CircularProgressIndicator(
                        strokeWidth: _spinnerStroke,
                        color: fg,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      key: ValueKey(widget.icon),
                      size: _iconSize,
                      color: fg,
                    ),
            ),
          ),
        ),
      ),
    );

    // Badge overlay
    if (widget.badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -2,
            right: -2,
            child: _Badge(text: widget.badge!),
          ),
        ],
      );
    }

    // Gesture handling
    button = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        child: button,
      ),
    );

    // Optional tooltip
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// ── Badge overlay ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final hasText = text.isNotEmpty;

    if (!hasText) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.destructive,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.destructiveForeground,
          height: 1.2,
          fontFamily: AppFonts.sans,
        ),
      ),
    );
  }
}
