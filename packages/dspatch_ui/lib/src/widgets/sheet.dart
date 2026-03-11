import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Side from which the sheet slides in.
enum SheetSide { top, bottom, left, right }

/// A side panel that slides in from any edge, inspired by shadcn/ui Sheet.
///
/// ```dart
/// Sheet.show(
///   context: context,
///   side: SheetSide.right,
///   builder: (context) => Column(
///     children: [
///       SheetHeader(children: [
///         SheetTitle(text: 'Edit Profile'),
///         SheetDescription(text: 'Make changes to your profile.'),
///       ]),
///       SheetContent(child: Text('Form here')),
///       SheetFooter(children: [
///         Button(label: 'Save', onPressed: () {}),
///       ]),
///     ],
///   ),
/// );
/// ```
class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    required this.child,
    this.side = SheetSide.right,
    this.size,
  });

  /// Content widget.
  final Widget child;

  /// Side from which the sheet appears.
  final SheetSide side;

  /// Width (for left/right) or height (for top/bottom). Defaults to 320.
  final double? size;

  /// Shows a sheet from the given side.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    SheetSide side = SheetSide.right,
    double? size,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Sheet',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim, secondaryAnim) => Sheet(
        side: side,
        size: size,
        child: builder(ctx),
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final offset = switch (side) {
          SheetSide.right => Offset(1 - anim.value, 0),
          SheetSide.left => Offset(anim.value - 1, 0),
          SheetSide.bottom => Offset(0, 1 - anim.value),
          SheetSide.top => Offset(0, anim.value - 1),
        };
        return FractionalTranslation(
          translation: offset,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal =
        side == SheetSide.left || side == SheetSide.right;
    final effectiveSize = size ?? 320;

    final alignment = switch (side) {
      SheetSide.right => Alignment.centerRight,
      SheetSide.left => Alignment.centerLeft,
      SheetSide.top => Alignment.topCenter,
      SheetSide.bottom => Alignment.bottomCenter,
    };

    return Align(
      alignment: alignment,
      child: Material(
        color: AppColors.card,
        child: Container(
          width: isHorizontal ? effectiveSize : double.infinity,
          height: !isHorizontal ? effectiveSize : double.infinity,
          decoration: BoxDecoration(
            border: _buildBorder(),
          ),
          child: child,
        ),
      ),
    );
  }

  Border _buildBorder() {
    return switch (side) {
      SheetSide.right => const Border(
          left: BorderSide(color: AppColors.border)),
      SheetSide.left => const Border(
          right: BorderSide(color: AppColors.border)),
      SheetSide.top => const Border(
          bottom: BorderSide(color: AppColors.border)),
      SheetSide.bottom => const Border(
          top: BorderSide(color: AppColors.border)),
    };
  }
}

/// Header section for [Sheet].
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.xxl, Spacing.xxl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Title for a sheet header.
class SheetTitle extends StatelessWidget {
  const SheetTitle({super.key, required this.text});

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

/// Description for a sheet header.
class SheetDescription extends StatelessWidget {
  const SheetDescription({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.mutedForeground,
      ),
    );
  }
}

/// Content area for [Sheet].
class SheetContent extends StatelessWidget {
  const SheetContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: child,
      ),
    );
  }
}

/// Footer area for [Sheet].
class SheetFooter extends StatelessWidget {
  const SheetFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxl, 0, Spacing.xxl, Spacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}
