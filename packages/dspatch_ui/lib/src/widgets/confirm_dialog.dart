import 'package:flutter/material.dart';

import 'button.dart';
import 'dialog.dart';

/// Reusable confirmation dialog for destructive actions.
///
/// Returns `true` if the user confirmed, `false` if cancelled.
///
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context: context,
///   title: 'Delete Provider',
///   description: 'Are you sure? This cannot be undone.',
/// );
/// if (confirmed) { /* perform action */ }
/// ```
class ConfirmDialog {
  ConfirmDialog._();

  /// Shows a confirmation dialog and returns whether the user confirmed.
  ///
  /// [confirmLabel] defaults to `'Delete'` and uses [ButtonVariant.destructive].
  /// Override [confirmVariant] for non-destructive confirmations.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String description,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    ButtonVariant confirmVariant = ButtonVariant.destructive,
  }) async {
    var confirmed = false;
    await DspatchDialog.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogHeader(children: [
            DialogTitle(text: title),
            DialogDescription(text: description),
          ]),
          DialogFooter(children: [
            Button(
              label: cancelLabel,
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            Button(
              label: confirmLabel,
              variant: confirmVariant,
              onPressed: () {
                confirmed = true;
                Navigator.of(ctx).pop();
              },
            ),
          ]),
        ],
      ),
    );
    return confirmed;
  }
}
