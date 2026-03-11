import 'package:flutter/material.dart';

/// An animated pulsing circle indicator.
///
/// Pulses between 40% and 100% opacity over [duration]. Useful for indicating
/// an active or waiting state on step indicators, status dots, etc.
class PulsingDot extends StatefulWidget {
  final Color color;
  final String? label;
  final double size;
  final Duration duration;

  const PulsingDot({
    super.key,
    required this.color,
    this.label,
    this.size = 24,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final opacity = 0.4 + (_ctrl.value * 0.6);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.15),
              border: Border.all(color: widget.color, width: 2),
            ),
            child: widget.label != null
                ? Center(
                    child: Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: widget.size * 0.42,
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
