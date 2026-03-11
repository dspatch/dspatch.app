import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A right-click context menu inspired by shadcn/ui ContextMenu.
///
/// ```dart
/// ContextMenu(
///   children: [
///     ContextMenuItem(label: 'Back', shortcut: '⌘[', onTap: () {}),
///     ContextMenuItem(label: 'Forward', shortcut: '⌘]', onTap: () {}),
///     ContextMenuSeparator(),
///     ContextMenuItem(label: 'Reload', shortcut: '⌘R', onTap: () {}),
///   ],
///   child: Container(
///     width: 300,
///     height: 200,
///     color: AppColors.card,
///     child: Center(child: Text('Right click here')),
///   ),
/// )
/// ```
class ContextMenu extends StatefulWidget {
  const ContextMenu({
    super.key,
    required this.child,
    required this.children,
    this.width = 200,
  });

  /// Widget that accepts the right click.
  final Widget child;

  /// Menu items to show.
  final List<Widget> children;

  /// Menu width.
  final double width;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  OverlayEntry? _entry;

  void _show(Offset globalPosition) {
    _close();

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              onSecondaryTap: _close,
            ),
          ),
          Positioned(
            left: globalPosition.dx,
            top: globalPosition.dy,
            child: Material(
              color: AppColors.popover,
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
                    if (child is ContextMenuItem) {
                      return ContextMenuItem(
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
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _show(details.globalPosition),
      child: widget.child,
    );
  }
}

/// A single item within a context menu.
class ContextMenuItem extends StatefulWidget {
  const ContextMenuItem({
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
  State<ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<ContextMenuItem> {
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
          color:
              _hovered && !disabled ? AppColors.surfaceHover : Colors.transparent,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled ? AppColors.muted : AppColors.mutedForeground,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: disabled ? AppColors.muted : AppColors.foreground,
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

/// A label within a context menu.
class ContextMenuLabel extends StatelessWidget {
  const ContextMenuLabel({super.key, required this.text});

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

/// A separator line within a context menu.
class ContextMenuSeparator extends StatelessWidget {
  const ContextMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Container(height: 1, color: AppColors.border),
    );
  }
}
