import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A horizontal progress bar inspired by shadcn/ui Progress.
///
/// ```dart
/// Progress(value: 0.6)
/// ```
class Progress extends StatelessWidget {
  const Progress({
    super.key,
    required this.value,
    this.height = Spacing.sm,
  });

  /// Progress fraction between 0.0 and 1.0.
  final double value;

  /// Bar height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: AppColors.secondary,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          minHeight: height,
        ),
      ),
    );
  }
}
