// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:flutter/widgets.dart';
import 'package:dspatch_ui/dspatch_ui.dart';

/// Convenience extensions on [BuildContext] for showing toasts.
extension ContextExt on BuildContext {
  /// Shows a success toast with the given [message].
  void showToast(String message) {
    toast(message, type: ToastType.success);
  }

  /// Shows an error toast with the given [message].
  void showErrorToast(String message) {
    toast(message, type: ToastType.error);
  }
}
