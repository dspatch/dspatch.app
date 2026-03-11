import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A bottom drawer with drag-to-dismiss inspired by shadcn/ui Drawer.
///
/// ```dart
/// DspatchDrawer.show(
///   context: context,
///   builder: (context) => Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       DrawerHeader(children: [
///         DrawerTitle(text: 'Settings'),
///         DrawerDescription(text: 'Adjust your preferences.'),
///       ]),
///       DrawerContent(child: Text('Content here')),
///       DrawerFooter(children: [
///         Button(label: 'Close', onPressed: () => Navigator.pop(context)),
///       ]),
///     ],
///   ),
/// );
/// ```
class DspatchDrawer extends StatelessWidget {
  const DspatchDrawer({
    super.key,
    required this.child,
  });

  /// Drawer content.
  final Widget child;

  /// Shows a bottom drawer.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DspatchDrawer(child: builder(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
            child: Container(
              width: 40,
              height: Spacing.xs,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Header section for [DspatchDrawer].
class DrawerHeader extends StatelessWidget {
  const DrawerHeader({super.key, required this.children});

  /// Typically [DrawerTitle] and [DrawerDescription].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.sm, Spacing.xxl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Title for a drawer header.
class DrawerTitle extends StatelessWidget {
  const DrawerTitle({super.key, required this.text});

  /// Title text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

/// Description for a drawer header.
class DrawerDescription extends StatelessWidget {
  const DrawerDescription({super.key, required this.text});

  /// Description text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.mutedForeground,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Content area for [DspatchDrawer].
class DrawerContent extends StatelessWidget {
  const DrawerContent({super.key, required this.child});

  /// Content widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: child,
    );
  }
}

/// Footer area for [DspatchDrawer], typically buttons.
class DrawerFooter extends StatelessWidget {
  const DrawerFooter({super.key, required this.children});

  /// Action widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxl, 0, Spacing.xxl, Spacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}
