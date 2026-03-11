import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A themed status card displaying an icon/spinner and a text message.
///
/// Useful for showing loading, success, error, or informational states.
class StatusCard extends StatelessWidget {
  /// The icon to display (ignored when [showSpinner] is true).
  final IconData icon;

  /// The accent color for the icon/spinner and text.
  final Color color;

  /// The status message.
  final String text;

  /// When true, shows a [CircularProgressIndicator] instead of the icon.
  final bool showSpinner;

  /// Optional trailing widget (e.g. action buttons).
  final Widget? trailing;

  const StatusCard({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.showSpinner = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (showSpinner)
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
