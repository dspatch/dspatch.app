import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A horizontal or vertical divider inspired by shadcn/ui Separator.
///
/// ```dart
/// Separator()
/// Separator(direction: Axis.vertical, height: 24)
/// ```
class Separator extends StatelessWidget {
  const Separator({
    super.key,
    this.direction = Axis.horizontal,
    this.height,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  /// Whether horizontal or vertical.
  final Axis direction;

  /// Explicit height (horizontal) or width (vertical) of the separator area.
  final double? height;

  /// Line thickness in logical pixels.
  final double thickness;

  /// Override color (defaults to [AppColors.border]).
  final Color? color;

  /// Leading indent.
  final double indent;

  /// Trailing indent.
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.border;

    if (direction == Axis.vertical) {
      return Container(
        width: thickness,
        height: height,
        margin: EdgeInsets.only(top: indent, bottom: endIndent),
        color: c,
      );
    }

    return Container(
      height: thickness,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: c,
    );
  }
}
