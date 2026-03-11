import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A dialog container inspired by shadcn/ui Dialog.
///
/// ```dart
/// DspatchDialog.show(
///   context: context,
///   builder: (context) => Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       DialogHeader(
///         children: [
///           DialogTitle(text: 'Are you sure?'),
///           DialogDescription(text: 'This action cannot be undone.'),
///         ],
///       ),
///       DialogContent(child: Text('Content here')),
///       DialogFooter(children: [
///         Button(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.pop(context)),
///         Button(label: 'Confirm', onPressed: () {}),
///       ]),
///     ],
///   ),
/// );
/// ```
class DspatchDialog extends StatelessWidget {
  const DspatchDialog({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  /// Dialog content.
  final Widget child;

  /// Maximum width.
  final double maxWidth;

  /// Shows a dialog with the given builder.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    double maxWidth = 480,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black54,
      builder: (ctx) => DspatchDialog(
        maxWidth: maxWidth,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
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

/// Header section for [DspatchDialog].
class DialogHeader extends StatelessWidget {
  const DialogHeader({super.key, required this.children});

  /// Typically [DialogTitle] and [DialogDescription].
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

/// Title for a dialog header.
class DialogTitle extends StatelessWidget {
  const DialogTitle({super.key, required this.text});

  /// Title text.
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

/// Description for a dialog header.
class DialogDescription extends StatelessWidget {
  const DialogDescription({super.key, required this.text});

  /// Description text.
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

/// Content area for [DspatchDialog].
class DialogContent extends StatelessWidget {
  const DialogContent({super.key, required this.child});

  /// Content widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: child,
    );
  }
}

/// Footer area for [DspatchDialog], typically buttons.
class DialogFooter extends StatelessWidget {
  const DialogFooter({super.key, required this.children});

  /// Action widgets (buttons).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.xxl, Spacing.xxl, Spacing.xxl),
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
