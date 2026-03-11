// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:ui';

import 'package:dspatch_ui/dspatch_ui.dart';

/// Shows a persistent toast for storage/database errors with a retry action.
///
/// Unlike standard toasts, this stays visible for 8 seconds (double default)
/// and includes a "Retry" action button that calls the provided callback.
String showStorageError({
  required String message,
  VoidCallback? onRetry,
}) {
  return toast(
    'Database error',
    description: message,
    type: ToastType.error,
    duration: const Duration(seconds: 8),
    action: onRetry,
    actionLabel: onRetry != null ? 'Retry' : null,
  );
}
