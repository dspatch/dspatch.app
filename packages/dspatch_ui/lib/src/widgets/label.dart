import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A form label inspired by shadcn/ui Label.
///
/// ```dart
/// Label(text: 'Email')
/// Label(text: 'Password', required: true)
/// ```
class Label extends StatelessWidget {
  const Label({
    super.key,
    required this.text,
    this.required = false,
    this.disabled = false,
  });

  /// Label text.
  final String text;

  /// Whether to show a required asterisk.
  final bool required;

  /// Whether the label appears disabled (dimmed).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: AppFonts.sans,
          color: disabled ? AppColors.mutedForeground : AppColors.foreground,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.destructive),
            ),
        ],
      ),
    );
  }
}
