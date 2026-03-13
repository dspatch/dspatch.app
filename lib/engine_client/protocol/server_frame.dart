// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// A frame sent from the engine to the client over WebSocket.
///
/// Parsed from JSON using [ServerFrame.fromJson]. The `type` field
/// determines the concrete subclass.
sealed class ServerFrame {
  const ServerFrame();

  /// Parses a JSON map into the appropriate [ServerFrame] subclass.
  ///
  /// Throws [FormatException] if the `type` field is missing or unknown.
  factory ServerFrame.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'result' => ResultFrame(
          id: json['id'] as String,
          data: json['data'] as Map<String, dynamic>? ?? {},
        ),
      'error' => ErrorFrame(
          id: json['id'] as String?,
          code: json['code'] as String,
          message: json['message'] as String,
        ),
      'invalidate' => InvalidateFrame(
          tables: (json['tables'] as List<dynamic>).cast<String>(),
        ),
      'event' => EventFrame(
          name: json['name'] as String,
          data: json['data'] as Map<String, dynamic>? ?? {},
        ),
      _ => throw FormatException('Unknown server frame type: $type'),
    };
  }
}

/// Successful command result, correlated by [id].
class ResultFrame extends ServerFrame {
  final String id;
  final Map<String, dynamic> data;

  const ResultFrame({required this.id, required this.data});
}

/// Command error, optionally correlated by [id].
class ErrorFrame extends ServerFrame {
  final String? id;
  final String code;
  final String message;

  const ErrorFrame({this.id, required this.code, required this.message});
}

/// Table invalidation — the engine modified these tables, Drift should re-query.
class InvalidateFrame extends ServerFrame {
  final List<String> tables;

  const InvalidateFrame({required this.tables});
}

/// Ephemeral event (engine lifecycle, P2P status, etc.).
class EventFrame extends ServerFrame {
  final String name;
  final Map<String, dynamic> data;

  const EventFrame({required this.name, required this.data});
}
