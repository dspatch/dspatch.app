import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A styled checkbox inspired by shadcn/ui Checkbox.
///
/// ```dart
/// DspatchCheckbox(
///   value: _agreed,
///   onChanged: (v) => setState(() => _agreed = v ?? false),
/// )
/// ```
class DspatchCheckbox extends StatelessWidget {
  const DspatchCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.tristate = false,
  });

  /// Whether the checkbox is checked.
  final bool? value;

  /// Called when the value changes.
  final ValueChanged<bool?>? onChanged;

  /// Whether to allow an indeterminate state.
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        tristate: tristate,
        activeColor: AppColors.primary,
        checkColor: AppColors.primaryForeground,
        side: const BorderSide(color: AppColors.input, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
