// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

/// Timer-based debouncer for search/filter inputs.
///
/// Delays [action] execution until [duration] has passed without
/// another [run] call. Call [dispose] when the owner widget is disposed.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  final Duration duration;
  Timer? _timer;

  /// Schedules [action] to run after [duration]. Cancels any pending action.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending action. Safe to call multiple times.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
