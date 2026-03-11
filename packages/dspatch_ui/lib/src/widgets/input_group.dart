import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// An input with prefix/suffix elements, inspired by shadcn/ui InputGroup.
///
/// ```dart
/// InputGroup(
///   prefix: Text('\$'),
///   child: Input(placeholder: 'Amount'),
///   suffix: Text('USD'),
/// )
/// ```
class InputGroup extends StatelessWidget {
  const InputGroup({
    super.key,
    required this.child,
    this.prefix,
    this.suffix,
  });

  /// The input widget (typically [Input]).
  final Widget child;

  /// Widget displayed before the input (e.g. icon, text, button).
  final Widget? prefix;

  /// Widget displayed after the input (e.g. icon, text, button).
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.input, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (prefix != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border(
                  right: BorderSide(color: AppColors.input, width: 1),
                ),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
                child: prefix!,
              ),
            ),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme:
                    Theme.of(context).inputDecorationTheme.copyWith(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
              ),
              child: child,
            ),
          ),
          if (suffix != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border(
                  left: BorderSide(color: AppColors.input, width: 1),
                ),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
                child: suffix!,
              ),
            ),
        ],
      ),
    );
  }
}
