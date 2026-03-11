import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A collapsible sidebar inspired by shadcn/ui Sidebar.
///
/// ```dart
/// Sidebar(
///   children: [
///     SidebarHeader(child: Text('App Name')),
///     SidebarContent(
///       children: [
///         SidebarGroup(
///           label: 'Platform',
///           children: [
///             SidebarItem(icon: LucideIcons.house, label: 'Home', onTap: () {}),
///             SidebarItem(icon: LucideIcons.inbox, label: 'Inbox', onTap: () {}),
///           ],
///         ),
///       ],
///     ),
///     SidebarFooter(child: Text('v1.0')),
///   ],
/// )
/// ```
class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.children, this.width = 256});

  /// Sidebar content widgets.
  final List<Widget> children;

  /// Expanded width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final state = SidebarState.of(context);
    final collapsed = state?.collapsed ?? false;

    Widget content = IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    if (!collapsed) {
      content = SizedBox(width: width, child: content);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: AlignmentDirectional.topStart,
        clipBehavior: Clip.hardEdge,
        child: content,
      ),
    );
  }
}

/// Provides sidebar collapse state to descendants.
///
/// ```dart
/// SidebarProvider(
///   child: Row(
///     children: [
///       Sidebar(children: [...]),
///       Expanded(child: mainContent),
///     ],
///   ),
/// )
/// ```
class SidebarProvider extends StatefulWidget {
  const SidebarProvider({
    super.key,
    required this.child,
    this.defaultCollapsed = false,
  });

  final Widget child;
  final bool defaultCollapsed;

  @override
  State<SidebarProvider> createState() => SidebarProviderState();
}

class SidebarProviderState extends State<SidebarProvider> {
  late bool _collapsed;

  bool get collapsed => _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.defaultCollapsed;
  }

  void toggle() {
    setState(() => _collapsed = !_collapsed);
  }

  void setCollapsed(bool value) {
    setState(() => _collapsed = value);
  }

  @override
  Widget build(BuildContext context) {
    return SidebarState(
      collapsed: _collapsed,
      toggle: toggle,
      child: widget.child,
    );
  }
}

/// InheritedWidget for sidebar state.
class SidebarState extends InheritedWidget {
  const SidebarState({
    super.key,
    required super.child,
    required this.collapsed,
    required this.toggle,
  });

  final bool collapsed;
  final VoidCallback toggle;

  static SidebarState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SidebarState>();
  }

  @override
  bool updateShouldNotify(SidebarState oldWidget) =>
      collapsed != oldWidget.collapsed;
}

/// Header section of a [Sidebar].
class SidebarHeader extends StatelessWidget {
  const SidebarHeader({super.key, required this.child, this.padding});

  final Widget child;

  /// Custom padding. Defaults to [Spacing.lg] on all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(Spacing.lg),
      child: child,
    );
  }
}

/// Scrollable content area of a [Sidebar].
class SidebarContent extends StatelessWidget {
  const SidebarContent({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Footer section of a [Sidebar].
class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: child,
    );
  }
}

/// A labeled group of items within [SidebarContent].
class SidebarGroup extends StatelessWidget {
  const SidebarGroup({super.key, this.label, required this.children});

  /// Optional group label.
  final String? label;

  /// Group items.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final collapsed = SidebarState.of(context)?.collapsed ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && !collapsed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              child: Text(
                label!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// A single clickable item in the sidebar.
class SidebarItem extends StatefulWidget {
  const SidebarItem({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isActive = false,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isActive;
  final Widget? trailing;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final state = SidebarState.of(context);
    final collapsed = state?.collapsed ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? Spacing.sm : Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.surfaceHover
                : _hovered
                ? AppColors.surfaceHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive
                      ? AppColors.foreground
                      : AppColors.mutedForeground,
                ),
              if (!collapsed) ...[
                if (widget.icon != null) const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isActive
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: widget.isActive
                          ? AppColors.foreground
                          : AppColors.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A toggle button to collapse/expand the sidebar.
class SidebarTrigger extends StatelessWidget {
  const SidebarTrigger({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SidebarState.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: state?.toggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            state?.collapsed == true ? LucideIcons.menu : LucideIcons.panel_left,
            size: 18,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

/// A separator line within a sidebar.
class SidebarSeparator extends StatelessWidget {
  const SidebarSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Container(height: 1, color: AppColors.border),
    );
  }
}
