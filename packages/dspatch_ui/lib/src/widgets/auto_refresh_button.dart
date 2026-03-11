import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'button.dart';
import 'tooltip.dart';

/// A compact circular countdown button that triggers a callback at a fixed
/// interval. Tap to fire an immediate refresh and reset the timer.
///
/// Self-contained — owns its own [Timer], so the parent only provides the
/// [interval] and [onRefresh] callback.
///
/// ```dart
/// AutoRefreshButton(
///   interval: Duration(seconds: 30),
///   onRefresh: () => ref.invalidate(myProvider),
/// )
///
/// AutoRefreshButton(
///   interval: Duration(seconds: 10),
///   variant: ButtonVariant.destructive,
///   onRefresh: () => reload(),
/// )
/// ```
class AutoRefreshButton extends StatefulWidget {
  const AutoRefreshButton({
    super.key,
    required this.interval,
    required this.onRefresh,
    this.variant = ButtonVariant.primary,
    this.size = 28.0,
  });

  /// Duration between automatic refreshes.
  final Duration interval;

  /// Called on each refresh (automatic or manual tap).
  final VoidCallback onRefresh;

  /// Color variant for the countdown ring.
  final ButtonVariant variant;

  /// Diameter of the indicator in logical pixels.
  final double size;

  @override
  State<AutoRefreshButton> createState() => _AutoRefreshButtonState();
}

class _AutoRefreshButtonState extends State<AutoRefreshButton> {
  Timer? _timer;
  late int _remaining;

  int get _intervalSeconds => widget.interval.inSeconds.clamp(1, 999);

  @override
  void initState() {
    super.initState();
    _remaining = _intervalSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant AutoRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval) {
      _remaining = widget.interval.inSeconds.clamp(1, 999);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        widget.onRefresh();
        _remaining = _intervalSeconds;
      }
    });
  }

  void _manualRefresh() {
    widget.onRefresh();
    setState(() => _remaining = _intervalSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _ringColor => switch (widget.variant) {
        ButtonVariant.primary => AppColors.primary,
        ButtonVariant.secondary => AppColors.mutedForeground,
        ButtonVariant.outline => AppColors.foreground,
        ButtonVariant.ghost => AppColors.mutedForeground,
        ButtonVariant.destructive => AppColors.destructive,
        ButtonVariant.link => AppColors.primary,
        ButtonVariant.accentOutline => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remaining / _intervalSeconds);
    final ringColor = _ringColor;

    return DspatchTooltip(
      message: 'Auto-refresh in ${_remaining}s \u2014 tap to refresh now',
      child: GestureDetector(
        onTap: _manualRefresh,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CountdownRingPainter(
                progress: progress.clamp(0.0, 1.0),
                color: ringColor,
              ),
              child: Center(
                child: Text(
                  '$_remaining',
                  style: TextStyle(
                    fontSize: widget.size * 0.32,
                    fontFamily: AppFonts.mono,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Filled arc (clockwise from top)
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      progress != old.progress || color != old.color;
}
