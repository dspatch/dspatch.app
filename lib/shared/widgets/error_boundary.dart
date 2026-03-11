// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Signature for the toast display function, matching the subset of
/// [toast] parameters used by this observer.
typedef ToastFn = void Function(
  String message, {
  String? description,
  ToastType type,
});

/// Global [ProviderObserver] that catches unhandled [AsyncError] states
/// from stream/future providers and shows typed toast notifications.
///
/// Controller providers (which handle errors explicitly via try/catch)
/// are skipped to prevent double-toasting.
///
/// Deduplicates rapid-fire errors: same message within 5 seconds is ignored.
class AppProviderObserver extends ProviderObserver {
  AppProviderObserver({ToastFn? toastFn, DateTime Function()? clock})
      : _toastFn = toastFn ?? _defaultToast,
        _clock = clock ?? DateTime.now;

  final ToastFn _toastFn;
  final DateTime Function() _clock;
  DateTime? _lastErrorTime;
  String? _lastErrorMessage;

  static void _defaultToast(
    String message, {
    String? description,
    ToastType type = ToastType.normal,
  }) {
    toast(message, description: description, type: type);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is! AsyncError) return;

    // Skip controller providers — they handle errors explicitly
    final name = provider.name;
    if (name != null && name.contains('Controller')) return;

    final error = newValue.error;
    final message = error.toString();

    // Dedup: skip if same message within 5s
    final now = _clock();
    if (_lastErrorMessage == message &&
        _lastErrorTime != null &&
        now.difference(_lastErrorTime!).inSeconds < 5) {
      return;
    }
    _lastErrorTime = now;
    _lastErrorMessage = message;

    debugPrint(
      '[error_boundary] Unhandled provider error: $error\n'
      '${newValue.stackTrace}',
    );
    _toastFn(
      'Something went wrong',
      description: message,
      type: ToastType.error,
    );
  }
}
