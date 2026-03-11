import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A styled slider inspired by shadcn/ui Slider.
///
/// ```dart
/// DspatchSlider(
///   value: _value,
///   onChanged: (v) => setState(() => _value = v),
/// )
/// ```
class DspatchSlider extends StatelessWidget {
  const DspatchSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.disabled = false,
  });

  /// Current value.
  final double value;

  /// Called when the value changes.
  final ValueChanged<double>? onChanged;

  /// Called when the user is done selecting a new value (finger up / mouse up).
  final ValueChanged<double>? onChangeEnd;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Number of discrete divisions.
  final int? divisions;

  /// Whether the slider is disabled.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: disabled
            ? AppColors.muted
            : AppColors.primary,
        inactiveTrackColor: AppColors.secondary,
        thumbColor: disabled
            ? AppColors.mutedForeground
            : AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.1),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: AppRadius.md,
        ),
      ),
      child: Slider(
        value: value,
        onChanged: disabled ? null : onChanged,
        onChangeEnd: disabled ? null : onChangeEnd,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }
}
