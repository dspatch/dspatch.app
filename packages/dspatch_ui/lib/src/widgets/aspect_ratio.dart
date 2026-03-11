import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A thin wrapper around Flutter's [AspectRatio] with optional clip and border,
/// inspired by shadcn/ui AspectRatio.
///
/// ```dart
/// DspatchAspectRatio(
///   ratio: 16 / 9,
///   child: Image.network('https://example.com/image.jpg', fit: BoxFit.cover),
/// )
/// ```
class DspatchAspectRatio extends StatelessWidget {
  const DspatchAspectRatio({
    super.key,
    required this.ratio,
    required this.child,
    this.borderRadius,
    this.border = false,
  });

  /// Width-to-height ratio (e.g. 16/9).
  final double ratio;

  /// Content widget.
  final Widget child;

  /// Clip radius (defaults to [AppRadius.md] when [border] is true).
  final double? borderRadius;

  /// Whether to show a border.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (border ? AppRadius.md : 0);

    Widget result = AspectRatio(
      aspectRatio: ratio,
      child: child,
    );

    if (radius > 0) {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: result,
      );
    }

    if (border) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: result,
      );
    }

    return result;
  }
}
