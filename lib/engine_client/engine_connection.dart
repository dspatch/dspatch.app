// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'protocol/protocol.dart';

/// Manages a single WebSocket connection to the dspatch engine.
///
/// Routes incoming [ServerFrame]s to the appropriate handler:
/// - [ResultFrame] / [ErrorFrame] with an `id` → resolves the pending command future
/// - [InvalidateFrame] → emitted on [invalidations]
/// - [EventFrame] → emitted on [events]
///
/// Reconnects automatically when the connection drops, with exponential backoff.
/// This class is pure Dart — no Flutter imports.
class EngineConnection {
  final String host;
  final int port;
  String _token;

  String get token => _token;

  /// How long to wait before the first reconnect attempt.
  final Duration initialReconnectDelay;

  /// Maximum reconnect delay (caps exponential backoff).
  final Duration maxReconnectDelay;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _disposed = false;
  bool _connected = false;

  final _random = Random();

  /// Called during auto-reconnect when `connect()` fails.
  ///
  /// Must return a fresh session token, or `null` to stop reconnecting.
  /// Returning `null` signals that the callback handled the failure
  /// (e.g., by triggering logout or a phase transition).
  /// If the callback throws, the reconnect loop continues with normal
  /// backoff — useful when the engine is temporarily unreachable.
  Future<String?> Function()? onTokenRefresh;

  /// Monotonically increasing counter used to invalidate stale [connect]
  /// calls. When [reconnect] (or another connect cycle) starts, the epoch
  /// is bumped so that any in-flight [connect] from auto-reconnect notices
  /// the change and abandons its work instead of installing a duplicate
  /// listener — which would complete a pending-command Completer twice
  /// ("Bad state: Future already completed").
  int _connectEpoch = 0;

  /// Pending command futures, keyed by correlation ID.
  final _pendingCommands = <String, Completer<ServerFrame>>{};

  /// Controller for table invalidation events.
  final _invalidationController =
      StreamController<List<String>>.broadcast();

  /// Controller for ephemeral events.
  final _eventController = StreamController<EventFrame>.broadcast();

  /// Controller for connection state changes.
  final _connectionStateController =
      StreamController<bool>.broadcast();

  EngineConnection({
    required this.host,
    required this.port,
    required String token,
    this.initialReconnectDelay = const Duration(milliseconds: 500),
    this.maxReconnectDelay = const Duration(seconds: 30),
  }) : _token = token;

  // ── Public API ──────────────────────────────────────────────────────

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _connected;

  /// Stream of table invalidation events from the engine.
  /// Each event is a list of table names that were modified.
  Stream<List<String>> get invalidations => _invalidationController.stream;

  /// Stream of ephemeral events from the engine (lifecycle, P2P status).
  Stream<EventFrame> get events => _eventController.stream;

  /// Stream of connection state changes (true = connected, false = disconnected).
  Stream<bool> get connectionState => _connectionStateController.stream;

  /// Opens the WebSocket connection to the engine.
  ///
  /// Resolves when the connection is established and the welcome event
  /// has been received. Throws if the initial connection fails.
  Future<void> connect() async {
    if (_disposed) {
      print('[CONN] connect() called but DISPOSED');
      throw StateError('EngineConnection has been disposed');
    }
    if (_connected) {
      print('[CONN] connect() called but already connected');
      return;
    }

    final epoch = ++_connectEpoch;
    print('[CONN] connect() epoch=$epoch, token=${_token.substring(0, 8)}...');

    // Cancel any leaked subscription from a previous connection cycle
    // (e.g. _onDisconnected was called but the subscription wasn't
    // cancelled because it was overwritten by a prior connect() call).
    await _subscription?.cancel();
    _subscription = null;

    final uri = Uri.parse('ws://$host:$port/ws?token=$_token');
    final channel = WebSocketChannel.connect(uri);

    // Don't assign to _channel yet — if reconnect() runs while we're
    // awaiting ready, we don't want it closing this channel (which can
    // cause web_socket_channel to double-complete its internal Completer,
    // triggering "Bad state: Future already completed").
    try {
      print('[CONN] Awaiting channel.ready...');
      await channel.ready;
      print('[CONN] channel.ready completed');
    } catch (e) {
      print('[CONN] channel.ready FAILED: $e (epoch=$epoch, current=$_connectEpoch)');
      if (epoch != _connectEpoch) return;
      rethrow;
    }

    if (epoch != _connectEpoch) {
      print('[CONN] Stale epoch after ready ($epoch != $_connectEpoch), closing');
      channel.sink.close();
      return;
    }

    _channel = channel;
    _setConnected(true);
    print('[CONN] Connected successfully (epoch=$epoch)');

    // cancelOnError: true ensures that after a WebSocket error, only
    // onError fires — not onDone as well. Without this, both callbacks
    // fire, causing double _onDisconnected() calls and cascading leaked
    // subscriptions that interfere with subsequent connections.
    _subscription = channel.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (Object error) {
        print('[CONN] WebSocket error: $error');
        _onDisconnected();
      },
      cancelOnError: true,
    );
  }

  /// Tears down the current connection and opens a new one with [newToken].
  ///
  /// All pending commands are completed with a CONNECTION_CLOSED error.
  /// If [connect] fails, the old token is restored so the auto-reconnect
  /// loop does not keep retrying with a known-bad token.
  Future<void> reconnect(String newToken) async {
    print(
      '[CONN] reconnect() called, newToken=${newToken.substring(0, 8)}..., '
      'pendingCommands=${_pendingCommands.length}, connected=$_connected',
    );
    final oldToken = _token;

    // Bump epoch to invalidate any in-flight auto-reconnect connect() call.
    ++_connectEpoch;
    print('[CONN] Bumped epoch to $_connectEpoch');

    // Cancel existing subscription and close channel.
    print('[CONN] Cancelling subscription and closing channel...');
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;

    // Complete all pending commands with error.
    if (_pendingCommands.isNotEmpty) {
      print('[CONN] Completing ${_pendingCommands.length} pending commands with CONNECTION_CLOSED');
    }
    for (final entry in _pendingCommands.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete(ErrorFrame(
          id: entry.key,
          code: 'CONNECTION_CLOSED',
          message: 'Engine connection was closed for reconnect',
        ));
      }
    }
    _pendingCommands.clear();

    _setConnected(false);
    _token = newToken;
    try {
      print('[CONN] Calling connect() with new token...');
      await connect();
      print('[CONN] reconnect() completed successfully');
    } catch (e) {
      print('[CONN] reconnect() connect() FAILED: $e — restoring old token');
      _token = oldToken;
      rethrow;
    }
  }

  /// Tears down the current WebSocket connection without disposing.
  ///
  /// Unlike [dispose], the connection can be re-established later via
  /// [reconnect]. Used during logout to cleanly disconnect before the
  /// user navigates to the login screen.
  Future<void> disconnect() async {
    // Bump epoch to invalidate any in-flight auto-reconnect.
    ++_connectEpoch;

    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;

    for (final entry in _pendingCommands.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete(ErrorFrame(
          id: entry.key,
          code: 'CONNECTION_CLOSED',
          message: 'Engine connection was closed',
        ));
      }
    }
    _pendingCommands.clear();
    _setConnected(false);
  }

  /// Sends a raw JSON string over the WebSocket.
  ///
  /// Used internally by [EngineClient] to send command frames.
  void sendRaw(String json) {
    if (!_connected || _channel == null) {
      throw StateError('Not connected to engine');
    }
    _channel!.sink.add(json);
  }

  /// Registers a pending command with the given [id] and returns a future
  /// that completes when the engine sends the response.
  ///
  /// Exposed for testing. In production, use [EngineClient.send].
  Future<ServerFrame> registerPendingCommand(String id) {
    final completer = Completer<ServerFrame>();
    _pendingCommands[id] = completer;
    return completer.future;
  }

  /// Removes a pending command by [id] without completing it.
  ///
  /// Used by [EngineClient] to clean up timed-out commands.
  void removePendingCommand(String id) {
    _pendingCommands.remove(id);
  }

  /// Routes a [ServerFrame] to the appropriate handler.
  ///
  /// Exposed for testing. In production, frames arrive via the WebSocket.
  void handleServerFrame(ServerFrame frame) {
    switch (frame) {
      case ResultFrame(:final id):
        _completePendingCommand(id, frame);
      case ErrorFrame(:final id):
        if (id != null) {
          _completePendingCommand(id, frame);
        } else {
          // Unsolicited error — log it.
          print('[CONN] Unsolicited error: ${(frame).code} — ${(frame).message}');
        }
      case InvalidateFrame(:final tables):
        _invalidationController.add(tables);
      case EventFrame():
        _eventController.add(frame);
    }
  }

  /// Closes the connection and releases all resources.
  ///
  /// All pending command futures are completed with an error.
  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (e) {
      debugPrint('[EngineConnection] dispose: sink close failed: $e');
    }
    _channel = null;
    _setConnected(false);

    // Complete all pending commands with an error.
    for (final entry in _pendingCommands.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(StateError('Connection disposed'));
      }
    }
    _pendingCommands.clear();

    _invalidationController.close();
    _eventController.close();
    _connectionStateController.close();
  }

  // ── Internals ─────────────────────────────────────────────────────────

  void _onMessage(dynamic message) {
    if (message is! String) return;

    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final frame = ServerFrame.fromJson(json);
      handleServerFrame(frame);
    } catch (e) {
      print('[CONN] Failed to parse server frame: $e\nRaw: $message');
    }
  }

  void _onDisconnected() {
    print(
      '[CONN] _onDisconnected called (epoch=$_connectEpoch, disposed=$_disposed, '
      'pendingCommands=${_pendingCommands.length})',
    );
    // Null out the subscription so connect() doesn't try to cancel a
    // dead subscription, and so we don't hold a reference to a stream
    // that could still fire stale onDone/onError callbacks.
    _subscription = null;
    _channel = null;
    _setConnected(false);

    // Fail all pending commands immediately — callers should not hang
    // waiting for responses that will never arrive. The 30s timeout in
    // EngineClient is a last resort; this provides faster failure.
    if (_pendingCommands.isNotEmpty) {
      print('[CONN] Failing ${_pendingCommands.length} pending commands on disconnect');
      for (final entry in _pendingCommands.entries) {
        if (!entry.value.isCompleted) {
          entry.value.completeError(
            StateError('Connection lost while waiting for response to "${entry.key}"'),
          );
        }
      }
      _pendingCommands.clear();
    }

    if (!_disposed) {
      print('[CONN] Scheduling reconnect...');
      _scheduleReconnect();
    }
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(value);
    }
  }

  void _completePendingCommand(String id, ServerFrame frame) {
    final completer = _pendingCommands.remove(id);
    if (completer == null) {
      print('[CONN] No pending command for id=$id (already completed or unknown)');
    } else if (completer.isCompleted) {
      print('[CONN] WARNING: Completer for id=$id already completed! Ignoring duplicate.');
    } else {
      completer.complete(frame);
    }
  }

  /// Returns an exponentially increasing delay with ±50 % jitter, capped at
  /// [maxReconnectDelay]. Jitter prevents reconnect storms when many clients
  /// lose connection simultaneously.
  Duration _reconnectDelay(int attempt) {
    final base = initialReconnectDelay.inMilliseconds;
    final exponential = (base * pow(2, attempt.clamp(0, 6))).toInt();
    final capped = exponential.clamp(0, maxReconnectDelay.inMilliseconds);
    final jitter = 0.5 + _random.nextDouble() * 0.5; // 0.5–1.0
    return Duration(milliseconds: (capped * jitter).toInt());
  }

  void _scheduleReconnect() {
    _reconnectWithBackoff(0, _connectEpoch);
  }

  Future<void> _reconnectWithBackoff(int attempt, int epoch) async {
    if (_disposed) return;

    final delay = attempt == 0 ? initialReconnectDelay : _reconnectDelay(attempt);
    await Future.delayed(delay);
    if (_disposed || epoch != _connectEpoch) return;

    try {
      print('[CONN] Attempting reconnect (attempt=$attempt)...');
      await connect();
      print('[CONN] Reconnected successfully');
    } catch (e) {
      print('[CONN] Reconnect failed: $e');

      // Try to refresh the session token (e.g., engine restarted and
      // wiped its in-memory session store).
      if (onTokenRefresh != null) {
        try {
          final newToken = await onTokenRefresh!();
          if (_disposed || epoch != _connectEpoch) return;

          if (newToken != null) {
            print('[CONN] Token refreshed, retrying immediately');
            _token = newToken;
            // Reset backoff — we have a fresh token, retry promptly.
            _reconnectWithBackoff(0, _connectEpoch);
            return;
          } else {
            // Callback returned null — it handled the failure (logout,
            // phase transition, etc.). Stop reconnecting.
            print('[CONN] Token refresh returned null, stopping reconnect');
            return;
          }
        } catch (refreshError) {
          // Token refresh itself failed (engine probably down).
          // Fall through to normal backoff.
          print('[CONN] Token refresh failed: $refreshError');
        }
      }

      _reconnectWithBackoff(attempt + 1, _connectEpoch);
    }
  }
}
