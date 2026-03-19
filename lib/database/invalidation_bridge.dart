// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges engine invalidation events to the Drift database.
///
/// Listens to a stream of table-name lists (from the Engine Client's
/// WebSocket connection) and forwards each event to a callback (typically
/// [EngineDatabase.handleInvalidation]).
///
/// Lifecycle:
/// 1. Construct with the invalidation stream and callback.
/// 2. Call [start] to begin listening.
/// 3. Call [dispose] to cancel the subscription (e.g., on disconnect).
///
/// This is the glue between M6 (Engine Client) and M7 (Drift):
///
/// ```
/// Engine writes to SQLite
///   -> Engine sends WS: {"type": "invalidate", "tables": [...]}
///   -> Engine Client parses InvalidateFrame, emits on invalidations stream
///   -> InvalidationBridge receives the event
///   -> Calls EngineDatabase.handleInvalidation(tables)
///   -> Drift re-runs active watch queries
///   -> Riverpod StreamProviders emit new values
///   -> Flutter widgets rebuild
/// ```
class InvalidationBridge {
  final Stream<List<String>> invalidationStream;
  final void Function(List<String> tableNames) onInvalidation;

  StreamSubscription<List<String>>? _subscription;
  bool _disposed = false;

  InvalidationBridge({
    required this.invalidationStream,
    required this.onInvalidation,
  });

  /// Start listening for invalidation events.
  void start() {
    if (_disposed) return;
    _subscription?.cancel();
    _subscription = invalidationStream.listen(
      _onInvalidation,
      onError: (Object e) {
        debugPrint('[InvalidationBridge] Stream error: $e');
        Future.delayed(const Duration(seconds: 1), _reconnect);
      },
      onDone: () {
        debugPrint('[InvalidationBridge] Stream closed');
        if (!_disposed) {
          Future.delayed(const Duration(seconds: 1), _reconnect);
        }
      },
    );
  }

  void _onInvalidation(List<String> tables) {
    if (_disposed) return;
    onInvalidation(tables);
  }

  void _reconnect() {
    if (_disposed) return;
    debugPrint('[InvalidationBridge] Reconnecting...');
    start();
  }

  /// Stop listening for invalidation events.
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
  }
}
