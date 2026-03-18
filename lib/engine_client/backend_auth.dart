// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendAuthResponse {
  final String token;
  final int expiresAt;
  final String scope;
  // Nullable: not all endpoints return identity fields (e.g. 2FA setup).
  final String? username;
  final String? email;
  final List<String>? backupCodes;
  final String? deviceId;
  final String? totpUri;
  final String? secret;

  const BackendAuthResponse({
    required this.token,
    required this.expiresAt,
    required this.scope,
    this.username,
    this.email,
    this.backupCodes,
    this.deviceId,
    this.totpUri,
    this.secret,
  });

  factory BackendAuthResponse.fromJson(Map<String, dynamic> json) {
    return BackendAuthResponse(
      token: json['token'] as String,
      expiresAt: json['expires_at'] as int,
      scope: json['scope'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      backupCodes: (json['backup_codes'] as List<dynamic>?)?.cast<String>(),
      deviceId: json['device_id'] as String?,
      totpUri: json['totp_uri'] as String?,
      secret: json['secret'] as String?,
    );
  }
}

/// Response from the 2FA setup endpoint, which does NOT issue a new token.
class Setup2faResponse {
  final String totpUri;
  final String secret;

  const Setup2faResponse({required this.totpUri, required this.secret});

  factory Setup2faResponse.fromJson(Map<String, dynamic> json) {
    return Setup2faResponse(
      totpUri: json['totp_uri'] as String,
      secret: json['secret'] as String,
    );
  }
}

class BackendAuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? field;

  const BackendAuthException(this.message, {this.statusCode, this.field});

  @override
  String toString() => 'BackendAuthException($statusCode): $message';
}

/// HTTP client for direct communication with the d:spatch backend auth
/// endpoints. Used during the multi-step login/register flow before the
/// engine is involved.
class BackendAuth {
  final String baseUrl;
  final http.Client _httpClient;

  BackendAuth({required this.baseUrl, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Login with username + password. If [deviceId], [deviceSignature], and
  /// [deviceTimestamp] are provided, they are included as the Ed25519 device
  /// proof required by the backend for accounts with registered devices.
  Future<BackendAuthResponse> login({
    required String username,
    required String password,
    String? deviceId,
    String? deviceSignature,
    int? deviceTimestamp,
  }) async {
    return _post('/api/auth/login', body: {
      'username': username,
      'password': password,
      'device_id': ?deviceId,
      'device_signature': ?deviceSignature,
      'device_timestamp': ?deviceTimestamp,
    });
  }

  Future<BackendAuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _post('/api/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<BackendAuthResponse> verifyEmail({
    required String token,
    required String code,
  }) async {
    return _post('/api/auth/verify-email', body: {'code': code}, token: token);
  }

  Future<void> resendVerification({required String token}) async {
    await _postRaw('/api/auth/resend-verification', token: token);
  }

  Future<Setup2faResponse> setup2fa({required String token}) async {
    final json = await _postRaw('/api/auth/2fa/setup', token: token);
    return Setup2faResponse.fromJson(json);
  }

  Future<BackendAuthResponse> confirm2fa({
    required String token,
    required String code,
  }) async {
    return _post('/api/auth/2fa/confirm-setup',
        body: {'code': code}, token: token);
  }

  Future<BackendAuthResponse> verify2fa({
    required String token,
    required String code,
    bool isBackupCode = false,
    String? deviceId,
    String? deviceSignature,
  }) async {
    return _post('/api/auth/2fa/verify', body: {
      'code': code,
      'is_backup_code': isBackupCode,
      'device_id': ?deviceId,
      'device_signature': ?deviceSignature,
    }, token: token);
  }

  Future<BackendAuthResponse> registerDevice({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    return _post('/api/auth/devices/register', body: body, token: token);
  }

  Future<BackendAuthResponse> refreshToken({required String token}) async {
    return _post('/api/auth/refresh', token: token);
  }

  /// Check the current auth status against the backend (ground truth).
  /// Returns `{ "scope": "full"|"device_pairing"|..., "username": ..., "email": ... }`.
  Future<Map<String, dynamic>> checkStatus({required String token}) async {
    return _getRaw('/api/auth/status', token: token);
  }

  /// Initiate pairing for a new device (requires DevicePairing scope token).
  Future<Map<String, dynamic>> initiatePairing({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    return _postRaw('/api/devices/pairing/initiate', body: body, token: token);
  }

  /// Poll pairing status for a new device.
  Future<Map<String, dynamic>> pairingStatus({
    required String token,
    required String deviceId,
  }) async {
    return _getRaw('/api/devices/pairing/status/$deviceId', token: token);
  }

  /// Approve a pending device pairing (existing device, requires Full scope).
  Future<Map<String, dynamic>> approvePairing({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    return _postRaw('/api/devices/pairing/approve', body: body, token: token);
  }

  /// Confirm or reject SAS verification (existing device).
  Future<Map<String, dynamic>> verifySas({
    required String token,
    required String deviceId,
    required bool sasConfirmed,
  }) async {
    return _postRaw('/api/devices/pairing/verify-sas', body: {
      'device_id': deviceId,
      'sas_confirmed': sasConfirmed,
    }, token: token);
  }

  /// List all devices for the authenticated user.
  /// Returns a raw JSON array (the backend returns `[{...}, ...]` directly).
  Future<List<dynamic>> listDevices({required String token}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/devices');
      final response = await _httpClient
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }

      _throwError(response);
    } on BackendAuthException {
      rethrow;
    } catch (e) {
      throw BackendAuthException('Failed to connect to backend: $e');
    }
  }

  /// Revoke (delete) a device.
  Future<void> revokeDevice({
    required String token,
    required String deviceId,
  }) async {
    await _deleteRaw('/api/devices/$deviceId', token: token);
  }

  void dispose() {
    _httpClient.close();
  }

  /// GET that returns raw JSON.
  Future<Map<String, dynamic>> _getRaw(
    String path, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      _throwError(response);
    } on BackendAuthException {
      rethrow;
    } catch (e) {
      throw BackendAuthException('Failed to connect to backend: $e');
    }
  }

  /// DELETE that returns nothing.
  Future<void> _deleteRaw(
    String path, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      _throwError(response);
    } on BackendAuthException {
      rethrow;
    } catch (e) {
      throw BackendAuthException('Failed to connect to backend: $e');
    }
  }

  /// POST that returns raw JSON without parsing as [BackendAuthResponse].
  /// Used for endpoints that return non-standard shapes (e.g. `{ok: true}`,
  /// `{totp_uri, secret}`).
  Future<Map<String, dynamic>> _postRaw(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      _throwError(response);
    } on BackendAuthException {
      rethrow;
    } catch (e) {
      throw BackendAuthException('Failed to connect to backend: $e');
    }
  }

  Future<BackendAuthResponse> _post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendAuthResponse.fromJson(json);
      }

      _throwError(response);
    } on BackendAuthException {
      rethrow;
    } catch (e) {
      throw BackendAuthException(
        'Failed to connect to backend: $e',
      );
    }
  }

  Never _throwError(http.Response response) {
    String errorMessage;
    String? field;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage =
          json['error'] as String? ?? json['message'] as String? ?? response.body;
      field = json['field'] as String?;
    } catch (_) {
      errorMessage = response.body;
    }

    throw BackendAuthException(
      errorMessage,
      statusCode: response.statusCode,
      field: field,
    );
  }
}
