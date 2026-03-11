import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Switch sizes.
enum SwitchSize {
  /// 28 × 16, thumb 12.
  sm,

  /// 36 × 20, thumb 16 (default).
  md,

  /// 44 × 24, thumb 20.
  lg,
}

/// A compact toggle switch inspired by shadcn/ui Switch.
///
/// ```dart
/// DspatchSwitch(
///   value: _enabled,
///   onChanged: (v) => setState(() => _enabled = v),
/// )
///
/// DspatchSwitch(
///   value: _on,
///   size: SwitchSize.sm,
///   onChanged: (v) => setState(() => _on = v),
/// )
/// ```
class DspatchSwitch extends StatefulWidget {
  const DspatchSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.size = SwitchSize.md,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called when toggled. Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Size variant.
  final SwitchSize size;

  @override
  State<DspatchSwitch> createState() => _DspatchSwitchState();
}

class _DspatchSwitchState extends State<DspatchSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(DspatchSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null;

  ({double track, double trackH, double thumb, double pad}) get _dims {
    return switch (widget.size) {
      SwitchSize.sm => (track: 28, trackH: 16, thumb: 12, pad: 2),
      SwitchSize.md => (track: 36, trackH: 20, thumb: 16, pad: 2),
      SwitchSize.lg => (track: 44, trackH: 24, thumb: 20, pad: 2),
    };
  }

  @override
  Widget build(BuildContext context) {
    final d = _dims;

    return GestureDetector(
      onTap: _enabled ? () => widget.onChanged!(!widget.value) : null,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final t = _curve.value;
            final trackColor = Color.lerp(
              AppColors.input,
              AppColors.primary,
              t,
            )!;
            final opacity = _enabled ? (_hovered ? 0.85 : 1.0) : 0.4;

            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: d.track,
                height: d.trackH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(d.trackH / 2),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(d.pad),
                    child: Align(
                      alignment: Alignment.lerp(
                        Alignment.centerLeft,
                        Alignment.centerRight,
                        t,
                      )!,
                      child: SizedBox(
                        width: d.thumb,
                        height: d.thumb,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primaryForeground,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
