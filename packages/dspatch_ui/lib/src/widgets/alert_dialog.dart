import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A modal dialog for destructive or important confirmations,
/// inspired by shadcn/ui AlertDialog.
///
/// Unlike [DspatchDialog], this cannot be dismissed by tapping the backdrop.
///
/// ```dart
/// DspatchAlertDialog.show(
///   context: context,
///   builder: (context) => Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       AlertDialogHeader(children: [
///         AlertDialogTitle(text: 'Are you absolutely sure?'),
///         AlertDialogDescription(text: 'This action cannot be undone.'),
///       ]),
///       AlertDialogFooter(children: [
///         Button(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
///         Button(label: 'Continue', variant: ButtonVariant.destructive, onPressed: () {}),
///       ]),
///     ],
///   ),
/// );
/// ```
class DspatchAlertDialog extends StatelessWidget {
  const DspatchAlertDialog({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  /// Dialog content.
  final Widget child;

  /// Maximum width.
  final double maxWidth;

  /// Shows a non-dismissible alert dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double maxWidth = 480,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => DspatchAlertDialog(
        maxWidth: maxWidth,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Header section for [DspatchAlertDialog].
class AlertDialogHeader extends StatelessWidget {
  const AlertDialogHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.xxl, Spacing.xxl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Title for an alert dialog header.
class AlertDialogTitle extends StatelessWidget {
  const AlertDialogTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

/// Description for an alert dialog header.
class AlertDialogDescription extends StatelessWidget {
  const AlertDialogDescription({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.mutedForeground,
      ),
    );
  }
}

/// Footer with action buttons for [DspatchAlertDialog].
class AlertDialogFooter extends StatelessWidget {
  const AlertDialogFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}
