import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A desktop-style horizontal menu bar inspired by shadcn/ui Menubar.
///
/// ```dart
/// DspatchMenubar(
///   menus: [
///     MenubarMenu(
///       label: 'File',
///       children: [
///         MenubarItem(label: 'New Tab', shortcut: '⌘T', onTap: () {}),
///         MenubarItem(label: 'New Window', shortcut: '⌘N', onTap: () {}),
///         MenubarSeparator(),
///         MenubarItem(label: 'Print', shortcut: '⌘P', onTap: () {}),
///       ],
///     ),
///     MenubarMenu(
///       label: 'Edit',
///       children: [
///         MenubarItem(label: 'Undo', shortcut: '⌘Z', onTap: () {}),
///         MenubarItem(label: 'Redo', shortcut: '⇧⌘Z', onTap: () {}),
///       ],
///     ),
///   ],
/// )
/// ```
class DspatchMenubar extends StatelessWidget {
  const DspatchMenubar({
    super.key,
    required this.menus,
  });

  /// Menu definitions.
  final List<MenubarMenu> menus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: Spacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final menu in menus) _MenubarTrigger(menu: menu),
        ],
      ),
    );
  }
}

/// Configuration for a single menubar dropdown.
class MenubarMenu {
  const MenubarMenu({
    required this.label,
    required this.children,
    this.width = 200,
  });

  final String label;
  final List<Widget> children;
  final double width;
}

class _MenubarTrigger extends StatefulWidget {
  const _MenubarTrigger({required this.menu});

  final MenubarMenu menu;

  @override
  State<_MenubarTrigger> createState() => _MenubarTriggerState();
}

class _MenubarTriggerState extends State<_MenubarTrigger> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _hovered = false;

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
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
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
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, Spacing.xs),
          child: Material(
            color: AppColors.popover,
            borderRadius: BorderRadius.circular(AppRadius.md),
            elevation: 4,
            child: Container(
              width: widget.menu.width,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.menu.children.map((child) {
                  if (child is MenubarItem) {
                    return MenubarItem(
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
    final isOpen = _entry != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: (isOpen || _hovered)
                  ? AppColors.surfaceHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              widget.menu.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A menu item within a menubar dropdown.
class MenubarItem extends StatefulWidget {
  const MenubarItem({
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
  State<MenubarItem> createState() => _MenubarItemState();
}

class _MenubarItemState extends State<MenubarItem> {
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

/// A separator line within a menubar dropdown.
class MenubarSeparator extends StatelessWidget {
  const MenubarSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Container(height: 1, color: AppColors.border),
    );
  }
}
