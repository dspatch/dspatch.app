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

  const AuthResult({
    required this.sessionToken,
    required this.authMode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      sessionToken: json['session_token'] as String,
      authMode: json['auth_mode'] as String,
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

  /// Authenticates with username and password.
  ///
  /// Requires the engine to have backend connectivity.
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    return _postAuth('/auth/login', {
      'username': username,
      'password': password,
    });
  }

  /// Registers a new account.
  ///
  /// Requires the engine to have backend connectivity.
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _postAuth('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
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

  void dispose() {
    _httpClient.close();
  }
}
