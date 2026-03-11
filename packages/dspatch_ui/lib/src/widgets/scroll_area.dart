import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A styled scroll container with custom scrollbar, inspired by shadcn/ui ScrollArea.
///
/// ```dart
/// ScrollArea(
///   height: 300,
///   child: Column(children: [...]),
/// )
/// ```
class ScrollArea extends StatelessWidget {
  const ScrollArea({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.direction = Axis.vertical,
    this.controller,
  });

  /// Scrollable content.
  final Widget child;

  /// Constrained height (for vertical scrolling).
  final double? height;

  /// Constrained width (for horizontal scrolling).
  final double? width;

  /// Scroll direction.
  final Axis direction;

  /// Optional scroll controller.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      scrollDirection: direction,
      controller: controller,
      primary: false,
      child: child,
    );

    Widget result = Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(
            AppColors.border.withValues(alpha: 0.6),
          ),
          radius: const Radius.circular(AppRadius.lg),
          thickness: const WidgetStatePropertyAll(6),
          crossAxisMargin: 2,
        ),
      ),
      child: Scrollbar(
        controller: controller,
        child: scrollView,
      ),
    );

    if (height != null || width != null) {
      result = SizedBox(
        height: height,
        width: width,
        child: result,
      );
    }

    return result;
  }
}
