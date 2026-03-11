import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A keyboard shortcut display widget inspired by shadcn/ui Kbd.
///
/// ```dart
/// Kbd(keys: ['⌘', 'K'])
/// Kbd(keys: ['Ctrl', 'Shift', 'P'])
/// ```
class Kbd extends StatelessWidget {
  const Kbd({
    super.key,
    required this.keys,
  });

  /// List of key labels to display.
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              keys[i],
              style: const TextStyle(
                fontSize: 11,
                fontFamily: AppFonts.mono,
                color: AppColors.mutedForeground,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
