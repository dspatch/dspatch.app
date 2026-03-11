import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A dropdown menu inspired by shadcn/ui DropdownMenu.
///
/// Uses an overlay to display menu items when the trigger is tapped.
///
/// ```dart
/// DropdownMenu(
///   trigger: Button(label: 'Open', variant: ButtonVariant.outline, onPressed: null),
///   children: [
///     DropdownMenuLabel(text: 'My Account'),
///     DropdownMenuSeparator(),
///     DropdownMenuItem(label: 'Profile', onTap: () {}),
///     DropdownMenuItem(label: 'Settings', onTap: () {}),
///     DropdownMenuSeparator(),
///     DropdownMenuItem(label: 'Log out', onTap: () {}),
///   ],
/// )
/// ```
class DspatchDropdownMenu extends StatefulWidget {
  const DspatchDropdownMenu({
    super.key,
    required this.trigger,
    required this.children,
    this.width = 200,
    this.side = DropdownSide.bottom,
    this.align = DropdownAlign.start,
  });

  /// Widget that opens the menu on tap.
  final Widget trigger;

  /// Menu items.
  final List<Widget> children;

  /// Menu width.
  final double width;

  /// Side from which the menu appears.
  final DropdownSide side;

  /// Alignment along the side.
  final DropdownAlign align;

  @override
  State<DspatchDropdownMenu> createState() => _DspatchDropdownMenuState();
}

enum DropdownSide { bottom, top }
enum DropdownAlign { start, center, end }

class _DspatchDropdownMenuState extends State<DspatchDropdownMenu> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _toggle() {
    if (_entry != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  Alignment _getTargetAnchor() {
    final isBottom = widget.side == DropdownSide.bottom;
    return switch (widget.align) {
      DropdownAlign.start =>
        isBottom ? Alignment.bottomLeft : Alignment.topLeft,
      DropdownAlign.center =>
        isBottom ? Alignment.bottomCenter : Alignment.topCenter,
      DropdownAlign.end =>
        isBottom ? Alignment.bottomRight : Alignment.topRight,
    };
  }

  Alignment _getFollowerAnchor() {
    final isBottom = widget.side == DropdownSide.bottom;
    return switch (widget.align) {
      DropdownAlign.start =>
        isBottom ? Alignment.topLeft : Alignment.bottomLeft,
      DropdownAlign.center =>
        isBottom ? Alignment.topCenter : Alignment.bottomCenter,
      DropdownAlign.end =>
        isBottom ? Alignment.topRight : Alignment.bottomRight,
    };
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: _getTargetAnchor(),
          followerAnchor: _getFollowerAnchor(),
          offset: Offset(0, widget.side == DropdownSide.bottom ? Spacing.xs : -Spacing.xs),
          child: Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            elevation: 4,
            child: Container(
              width: widget.width,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children.map((child) {
                  if (child is DropdownMenuItem) {
                    return DropdownMenuItem(
                      label: child.label,
                      icon: child.icon,
                      shortcut: child.shortcut,
                      disabled: child.disabled,
                      onTap: child.onTap != null
                          ? () {
                              _close();
                              child.onTap!();
                            }
                          : null,
                    );
                  }
                  return child;
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: widget.trigger,
      ),
    );
  }
}

/// A label header within a dropdown menu.
class DropdownMenuLabel extends StatelessWidget {
  const DropdownMenuLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

/// A separator line within a dropdown menu.
class DropdownMenuSeparator extends StatelessWidget {
  const DropdownMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Container(height: 1, color: AppColors.border),
    );
  }
}

/// A single item within a dropdown menu.
class DropdownMenuItem extends StatefulWidget {
  const DropdownMenuItem({
    super.key,
    required this.label,
    this.icon,
    this.shortcut,
    this.onTap,
    this.disabled = false,
  });

  final String label;
  final IconData? icon;
  final String? shortcut;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  State<DropdownMenuItem> createState() => _DropdownMenuItemState();
}

class _DropdownMenuItemState extends State<DropdownMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled || widget.onTap == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
          color: _hovered && !disabled
              ? AppColors.surfaceHover
              : Colors.transparent,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled
                      ? AppColors.muted
                      : AppColors.mutedForeground,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: disabled
                        ? AppColors.muted
                        : AppColors.foreground,
                  ),
                ),
              ),
              if (widget.shortcut != null)
                Text(
                  widget.shortcut!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    fontFamily: AppFonts.mono,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
