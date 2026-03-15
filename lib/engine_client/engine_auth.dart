// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Exception thrown when authentication with the engine fails.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException($statusCode): $message';
}

/// Parsed response from a successful authentication request.
class AuthResult {
  final String sessionToken;
  final String authMode;
  final String? username;
  final int? expiresAt;

  const AuthResult({
    required this.sessionToken,
    required this.authMode,
    this.username,
    this.expiresAt,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      sessionToken: json['session_token'] as String,
      authMode: json['auth_mode'] as String,
      username: json['username'] as String?,
      expiresAt: json['expires_at'] as int?,
    );
  }
}

/// HTTP client for the engine's `/auth/*` endpoints.
///
/// Obtains session tokens that are passed to the WebSocket connection.
/// Pure Dart — no Flutter imports.
class EngineAuth {
  final String host;
  final int port;
  final http.Client _httpClient;

  EngineAuth({
    required this.host,
    required this.port,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Authenticates anonymously (local-only session, no server connection).
  ///
  /// Always succeeds if the engine is reachable.
  Future<AuthResult> authenticateAnonymous() async {
    return _postAuth('/auth/anonymous', {});
  }

  /// Connects to the engine with a backend-issued token.
  ///
  /// Called after the full backend auth flow completes (scope=full).
  Future<AuthResult> connect({required String backendToken}) async {
    return _postAuth('/auth/connect', {
      'backend_token': backendToken,
    });
  }

  /// Refreshes the engine session using a backend token and existing session.
  Future<AuthResult> refresh({
    required String backendToken,
    required String sessionToken,
  }) async {
    return _postAuth('/auth/refresh', {
      'backend_token': backendToken,
      'session_token': sessionToken,
    });
  }

  Future<AuthResult> _postAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('http://$host:$port$path');
      final response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResult.fromJson(json);
      }

      // Try to parse error body.
      String errorMessage;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = json['error'] as String? ?? response.body;
      } catch (_) {
        errorMessage = response.body;
      }

      throw AuthException(
        errorMessage,
        statusCode: response.statusCode,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Failed to connect to engine: $e',
      );
    }
  }

  /// Fetches engine info including the current database file path.
  ///
  /// Called after the engine signals `database_state_changed` → `ready` so
  /// the Flutter app can open its read-only Drift connection at the correct
  /// path (which varies by auth state: anonymous vs per-user).
  Future<EngineInfo> fetchEngineInfo() async {
    try {
      final uri = Uri.parse('http://$host:$port/engine-info');
      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return EngineInfo.fromJson(json);
      }

      throw AuthException(
        'Failed to fetch engine info: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to fetch engine info: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Parsed response from `GET /engine-info`.
class EngineInfo {
  final String dbPath;
  final bool testMode;

  const EngineInfo({required this.dbPath, required this.testMode});

  factory EngineInfo.fromJson(Map<String, dynamic> json) {
    return EngineInfo(
      dbPath: json['db_path'] as String,
      testMode: json['test_mode'] as bool? ?? false,
    );
  }
}
