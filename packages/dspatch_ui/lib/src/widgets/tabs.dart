import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A tab container inspired by shadcn/ui Tabs.
///
/// ```dart
/// DspatchTabs(
///   defaultValue: 'account',
///   child: Column(children: [
///     TabsList(children: [
///       TabsTrigger(value: 'account', child: Text('Account')),
///       TabsTrigger(value: 'password', child: Text('Password')),
///     ]),
///     SizedBox(height: 16),
///     TabsContent(value: 'account', child: Text('Account settings')),
///     TabsContent(value: 'password', child: Text('Change password')),
///   ]),
/// )
/// ```
class DspatchTabs extends StatefulWidget {
  const DspatchTabs({
    super.key,
    required this.defaultValue,
    this.onChanged,
    required this.child,
  });

  /// Initial active tab value.
  final String defaultValue;

  /// Called when the active tab changes.
  final ValueChanged<String>? onChanged;

  /// Widget tree containing [TabsList] and [TabsContent] widgets.
  final Widget child;

  /// Access the nearest tabs scope.
  static _DspatchTabsScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DspatchTabsScope>()!;
  }

  @override
  State<DspatchTabs> createState() => _DspatchTabsState();
}

class _DspatchTabsState extends State<DspatchTabs> {
  late String _activeValue;

  @override
  void initState() {
    super.initState();
    _activeValue = widget.defaultValue;
  }

  void _setActive(String value) {
    setState(() => _activeValue = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return _DspatchTabsScope(
      activeValue: _activeValue,
      setActive: _setActive,
      child: widget.child,
    );
  }
}

class _DspatchTabsScope extends InheritedWidget {
  const _DspatchTabsScope({
    required this.activeValue,
    required this.setActive,
    required super.child,
  });

  final String activeValue;
  final void Function(String) setActive;

  @override
  bool updateShouldNotify(_DspatchTabsScope oldWidget) =>
      activeValue != oldWidget.activeValue;
}

/// Horizontal strip containing [TabsTrigger] widgets.
class TabsList extends StatelessWidget {
  const TabsList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.xs),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// A single tab trigger within a [TabsList].
class TabsTrigger extends StatelessWidget {
  const TabsTrigger({
    super.key,
    required this.value,
    required this.child,
  });

  /// Value that matches the corresponding [TabsContent].
  final String value;

  /// Label widget (usually [Text]).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = DspatchTabs.of(context);
    final isActive = scope.activeValue == value;

    return GestureDetector(
      onTap: () => scope.setActive(value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.sans,
              color: isActive
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Content pane that is visible only when its [value] matches the active tab.
class TabsContent extends StatelessWidget {
  const TabsContent({
    super.key,
    required this.value,
    required this.child,
  });

  /// Value that must match the active [TabsTrigger].
  final String value;

  /// Content shown when this tab is active.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = DspatchTabs.of(context);
    if (scope.activeValue != value) return const SizedBox.shrink();
    return child;
  }
}
