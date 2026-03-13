// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

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
  final String token;

  /// How long to wait before the first reconnect attempt.
  final Duration initialReconnectDelay;

  /// Maximum reconnect delay (caps exponential backoff).
  final Duration maxReconnectDelay;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _disposed = false;
  bool _connected = false;

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
    required this.token,
    this.initialReconnectDelay = const Duration(milliseconds: 500),
    this.maxReconnectDelay = const Duration(seconds: 30),
  });

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
    if (_disposed) throw StateError('EngineConnection has been disposed');
    if (_connected) return;

    final uri = Uri.parse('ws://$host:$port/ws?token=$token');
    _channel = WebSocketChannel.connect(uri);

    // Wait for the connection to be established.
    await _channel!.ready;
    _setConnected(true);

    _subscription = _channel!.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (Object error) {
        developer.log(
          'WebSocket error: $error',
          name: 'EngineConnection',
        );
        _onDisconnected();
      },
    );
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
  /// Exposed for testing. In production, use [EngineClient.sendCommand].
  Future<ServerFrame> registerPendingCommand(String id) {
    final completer = Completer<ServerFrame>();
    _pendingCommands[id] = completer;
    return completer.future;
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
          developer.log(
            'Unsolicited error: ${(frame).code} — ${(frame).message}',
            name: 'EngineConnection',
          );
        }
      case InvalidateFrame(:final tables):
        _invalidationController.add(tables);
      case EventFrame():
        _eventController.add(frame);
    }
  }

  /// Closes the connection and releases all resources.
  ///
  /// All pending command futures are completed with a CONNECTION_CLOSED error.
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    _setConnected(false);

    // Complete all pending commands with an error.
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
      developer.log(
        'Failed to parse server frame: $e\nRaw: $message',
        name: 'EngineConnection',
      );
    }
  }

  void _onDisconnected() {
    _setConnected(false);
    if (!_disposed) {
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
    if (completer != null && !completer.isCompleted) {
      completer.complete(frame);
    }
  }

  void _scheduleReconnect() {
    _reconnectWithBackoff(initialReconnectDelay);
  }

  Future<void> _reconnectWithBackoff(Duration delay) async {
    if (_disposed) return;

    await Future.delayed(delay);
    if (_disposed) return;

    try {
      developer.log(
        'Attempting reconnect...',
        name: 'EngineConnection',
      );
      await connect();
      developer.log(
        'Reconnected successfully',
        name: 'EngineConnection',
      );
    } catch (e) {
      developer.log(
        'Reconnect failed: $e',
        name: 'EngineConnection',
      );
      // Exponential backoff, capped at maxReconnectDelay.
      final nextDelay = Duration(
        milliseconds: (delay.inMilliseconds * 2)
            .clamp(0, maxReconnectDelay.inMilliseconds),
      );
      _reconnectWithBackoff(nextDelay);
    }
  }
}
