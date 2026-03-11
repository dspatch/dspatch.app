import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'alert.dart';
import 'copy_button.dart';

/// Inline error alert used for form-level errors (e.g. auth failures).
///
/// Wraps [Alert] with [AlertVariant.destructive] and adds a copy button
/// so users can easily share the error message.
///
/// ```dart
/// if (_error != null) ...[
///   const SizedBox(height: Spacing.md),
///   ErrorAlert(
///     title: 'Authentication failed',
///     message: _error!,
///   ),
/// ]
/// ```
class ErrorAlert extends StatelessWidget {
  const ErrorAlert({
    super.key,
    required this.title,
    required this.message,
  });

  /// Short heading describing the failure context.
  final String title;

  /// Detailed error message (selectable and copyable).
  final String message;

  @override
  Widget build(BuildContext context) {
    return Alert(
      variant: AlertVariant.destructive,
      children: [
        AlertTitle(text: title),
        SelectableText(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: CopyButton(textToCopy: message, iconSize: 16),
        ),
      ],
    );
  }
}
