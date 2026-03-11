import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'button.dart';
import 'copy_button.dart';

/// Shared error state view used across screens.
///
/// Shows a centered error icon, selectable message, copy button, and
/// optional retry button.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.circle_alert,
            size: 40,
            color: AppColors.destructive,
          ),
          const SizedBox(height: 8),
          SelectableText(
            message,
            style: const TextStyle(
              color: AppColors.destructive,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CopyButton(textToCopy: message, iconSize: 16),
              if (onRetry != null) ...[
                const SizedBox(width: Spacing.sm),
                Button(
                  label: 'Retry',
                  size: ButtonSize.sm,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
