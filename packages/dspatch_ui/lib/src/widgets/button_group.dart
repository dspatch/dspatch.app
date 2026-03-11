import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A connected row of buttons with shared borders, inspired by shadcn/ui ButtonGroup.
///
/// ```dart
/// ButtonGroup(
///   children: [
///     Button(label: 'Left', variant: ButtonVariant.outline, onPressed: () {}),
///     Button(label: 'Center', variant: ButtonVariant.outline, onPressed: () {}),
///     Button(label: 'Right', variant: ButtonVariant.outline, onPressed: () {}),
///   ],
/// )
/// ```
class ButtonGroup extends StatelessWidget {
  const ButtonGroup({
    super.key,
    required this.children,
  });

  /// Buttons to display in a connected row.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.input, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  color: AppColors.input,
                ),
              _ButtonGroupChild(child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ButtonGroupChild extends StatelessWidget {
  const _ButtonGroupChild({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Remove individual button border radius and borders since the group
    // handles them.
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            side: BorderSide.none,
          ),
        ),
      ),
      child: child,
    );
  }
}
