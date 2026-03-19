// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'engine_connection.dart';
import 'protocol/protocol.dart';
import '../models/commands/command.dart';

/// Exception thrown when the engine returns an error response to a command.
class EngineException implements Exception {
  final String code;
  final String message;

  const EngineException({required this.code, required this.message});

  @override
  String toString() => 'EngineException($code): $message';
}

/// Exception thrown when the engine connection fails.
class EngineConnectionException implements Exception {
  final String message;
  const EngineConnectionException(this.message);

  @override
  String toString() => 'EngineConnectionException: $message';
}

/// High-level typed client for the dspatch engine.
///
/// Wraps [EngineConnection] with typed command methods that return futures.
/// Each method constructs a [ClientFrame], sends it over the WebSocket,
/// and returns the result (or throws [EngineException] on error).
///
/// This class is pure Dart — no Flutter imports. Shared by GUI and future CLI.
class EngineClient {
  final EngineConnection connection;
  final _uuid = const Uuid();

  EngineClient(this.connection);

  // ── Public Streams (delegated from connection) ────────────────────────

  /// Stream of table invalidation events.
  Stream<List<String>> get invalidations => connection.invalidations;

  /// Stream of ephemeral events.
  Stream<EventFrame> get events => connection.events;

  /// Stream of connection state changes.
  Stream<bool> get connectionState => connection.connectionState;

  /// Whether the connection is currently active.
  bool get isConnected => connection.isConnected;

  // ── Command Infrastructure ────────────────────────────────────────────

  /// Sends a command to the engine and returns the result data.
  ///
  /// Throws [EngineException] if the engine returns an error response.
  /// Throws [StateError] if not connected.
  ///
  /// Private — external callers must use [send] with typed commands.
  Future<Map<String, dynamic>> _sendCommand(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    final id = _uuid.v4();
    final frame = ClientFrame.command(id: id, method: method, params: params);

    // Register the pending future BEFORE sending, to avoid race conditions.
    final responseFuture = connection.registerPendingCommand(id);

    // Send the frame.
    connection.sendRaw(jsonEncode(frame.toJson()));

    // Wait for the response, with a timeout to avoid hanging indefinitely.
    final response = await responseFuture.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        connection.removePendingCommand(id);
        throw TimeoutException('Engine command "$method" timed out after 30s');
      },
    );

    return switch (response) {
      ResultFrame(:final data) => data,
      ErrorFrame(:final code, :final message) =>
        throw EngineException(code: code, message: message),
      _ => throw StateError('Unexpected response type: $response'),
    };
  }

  /// Sends a typed command and returns a typed response.
  ///
  /// All external callers must use this method with typed [EngineCommand]
  /// subclasses instead of calling `_sendCommand` directly.
  Future<R> send<R extends EngineResponse>(EngineCommand<R> command) async {
    final result = await _sendCommand(command.method, command.params ?? const {});
    return command.parseResponse(result);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Disposes the client and closes the connection.
  void dispose() {
    connection.dispose();
  }
}
