import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A shimmer loading placeholder inspired by shadcn/ui Skeleton.
///
/// ```dart
/// Skeleton(width: 200, height: 20)
/// Skeleton(width: 48, height: 48, circle: true)
/// ```
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.circle = false,
  });

  /// Width of the placeholder.
  final double? width;

  /// Height of the placeholder.
  final double? height;

  /// Custom border radius (defaults to [AppRadius.md]).
  final double? borderRadius;

  /// Whether to render as a circle.
  final bool circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.circle
        ? BoxShape.circle
        : BoxShape.rectangle;
    final radius = widget.circle
        ? null
        : BorderRadius.circular(widget.borderRadius ?? AppRadius.md);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.muted,
                AppColors.shimmer,
                AppColors.muted,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0, 1),
                _controller.value.clamp(0, 1),
                (_controller.value + 0.3).clamp(0, 1),
              ],
            ),
          ),
        );
      },
    );
  }
}
