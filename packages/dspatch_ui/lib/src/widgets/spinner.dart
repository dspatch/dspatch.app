import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Spinner size presets.
enum SpinnerSize {
  /// 16 px.
  sm,

  /// 24 px.
  md,

  /// 36 px.
  lg,
}

/// A custom animated loading spinner inspired by shadcn/ui Spinner.
///
/// ```dart
/// const Spinner()
/// const Spinner(size: SpinnerSize.lg, color: AppColors.destructive)
/// ```
class Spinner extends StatefulWidget {
  const Spinner({
    super.key,
    this.size = SpinnerSize.md,
    this.color,
  });

  /// Size preset.
  final SpinnerSize size;

  /// Override the spinner color (defaults to [AppColors.primary]).
  final Color? color;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
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
    final dim = switch (widget.size) {
      SpinnerSize.sm => 16.0,
      SpinnerSize.md => 24.0,
      SpinnerSize.lg => 36.0,
    };
    final color = widget.color ?? AppColors.primary;
    final strokeWidth = dim > 20 ? 2.5 : 2.0;

    return Center(
      child: SizedBox(
        width: dim,
        height: dim,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _SpinnerPainter(
                  progress: _controller.value,
                  color: color,
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Rotating arc
    final startAngle = progress * 2 * math.pi - math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 1.2,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
