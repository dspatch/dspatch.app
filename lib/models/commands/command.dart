// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Base types for the typed engine command system.
///
/// `EngineCommand<R>` provides type-safe command dispatch over the existing
/// WebSocket wire protocol. The wire protocol itself is unchanged — this is
/// a Dart-side abstraction layered on top of `sendCommand`.
library;


/// Base class for all typed engine responses.
///
/// Only top-level responses (direct results of commands) extend this.
/// Nested model classes remain plain classes.
abstract class EngineResponse {
  const EngineResponse();
}

/// Sentinel response for fire-and-forget commands.
class VoidResponse extends EngineResponse {
  const VoidResponse();
}

/// Response for bulk operations that return an affected count.
class CountResponse extends EngineResponse {
  const CountResponse({required this.count});

  final int count;

  factory CountResponse.fromJson(Map<String, dynamic> json) {
    return CountResponse(count: json['count'] as int? ?? 0);
  }
}

/// Base class for all engine commands.
///
/// [R] is the typed response this command produces.
abstract class EngineCommand<R extends EngineResponse> {
  /// Wire method name (e.g., 'detect_docker_status').
  String get method;

  /// Parameters to serialize into the command frame.
  /// Returns null for parameterless commands.
  Map<String, dynamic>? get params;

  /// Parse the engine's raw JSON response into a typed response object.
  R parseResponse(Map<String, dynamic> result);
}

/// Shortcut for commands that return no meaningful data.
abstract class VoidEngineCommand extends EngineCommand<VoidResponse> {
  @override
  VoidResponse parseResponse(Map<String, dynamic> result) =>
      const VoidResponse();
}
