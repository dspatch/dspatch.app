import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A horizontal navigation menu with dropdown panels,
/// inspired by shadcn/ui NavigationMenu.
///
/// ```dart
/// NavigationMenu(
///   items: [
///     NavigationMenuItemData(
///       label: 'Getting Started',
///       content: Padding(
///         padding: EdgeInsets.all(16),
///         child: Text('Getting started content'),
///       ),
///     ),
///     NavigationMenuItemData(
///       label: 'Components',
///       content: Padding(
///         padding: EdgeInsets.all(16),
///         child: Text('Components list'),
///       ),
///     ),
///     NavigationMenuItemData(
///       label: 'Documentation',
///       href: '/docs',
///       onTap: () {},
///     ),
///   ],
/// )
/// ```
class NavigationMenu extends StatefulWidget {
  const NavigationMenu({
    super.key,
    required this.items,
  });

  /// Menu items.
  final List<NavigationMenuItemData> items;

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

/// Data for a single navigation menu item.
class NavigationMenuItemData {
  const NavigationMenuItemData({
    required this.label,
    this.content,
    this.onTap,
    this.href,
  });

  /// Display label.
  final String label;

  /// Dropdown panel content. If null, item acts as a link.
  final Widget? content;

  /// Tap callback for link items.
  final VoidCallback? onTap;

  /// Optional href (informational).
  final String? href;
}

class _NavigationMenuState extends State<NavigationMenu> {
  int? _openIndex;
  final _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _onItemEnter(int index) {
    if (widget.items[index].content == null) return;
    if (_openIndex == index) return;
    _close();
    _openIndex = index;
    _open();
  }

  void _onItemExit() {
    // Delay to allow mouse to enter the panel.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      // If still no re-enter, close.
      if (_openIndex != null) {
        _close();
        setState(() => _openIndex = null);
      }
    });
  }

  void _onPanelEnter(int index) {
    _openIndex = index;
  }

  void _onPanelExit() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _close();
      setState(() => _openIndex = null);
    });
  }

  void _open() {
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildOverlay(BuildContext context) {
    if (_openIndex == null) return const SizedBox.shrink();

    final item = widget.items[_openIndex!];
    if (item.content == null) return const SizedBox.shrink();

    final idx = _openIndex!;

    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: MouseRegion(
        onEnter: (_) => _onPanelEnter(idx),
        onExit: (_) => _onPanelExit(),
        child: Material(
          color: AppColors.popover,
          borderRadius: BorderRadius.circular(AppRadius.md),
          elevation: 4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 400),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: item.content,
          ),
        ),
      ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.items.length; i++)
            _NavigationMenuTrigger(
              item: widget.items[i],
              isActive: _openIndex == i,
              onEnter: () => _onItemEnter(i),
              onExit: _onItemExit,
              onTap: widget.items[i].content == null
                  ? widget.items[i].onTap
                  : null,
            ),
        ],
      ),
    );
  }
}

class _NavigationMenuTrigger extends StatefulWidget {
  const _NavigationMenuTrigger({
    required this.item,
    required this.isActive,
    required this.onEnter,
    required this.onExit,
    this.onTap,
  });

  final NavigationMenuItemData item;
  final bool isActive;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback? onTap;

  @override
  State<_NavigationMenuTrigger> createState() => _NavigationMenuTriggerState();
}

class _NavigationMenuTriggerState extends State<_NavigationMenuTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.item.content != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onEnter();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onExit();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: (_hovered || widget.isActive)
                ? AppColors.surfaceHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
              if (hasContent) ...[
                const SizedBox(width: Spacing.xs),
                Icon(
                  widget.isActive
                      ? LucideIcons.chevron_up
                      : LucideIcons.chevron_down,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
