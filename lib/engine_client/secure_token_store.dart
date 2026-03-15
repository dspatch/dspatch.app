// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists backend auth tokens and credentials in the OS keyring.
///
/// Uses macOS Keychain, Windows Credential Manager, or Linux libsecret
/// via [FlutterSecureStorage]. All values are encrypted at rest by the OS.
class SecureTokenStore {
  static const _keyPrefix = 'dspatch_auth_';
  static const _tokenKey = '${_keyPrefix}backend_token';
  static const _expiresAtKey = '${_keyPrefix}expires_at';
  static const _scopeKey = '${_keyPrefix}scope';
  static const _usernameKey = '${_keyPrefix}username';
  static const _emailKey = '${_keyPrefix}email';
  static const _sessionTokenKey = '${_keyPrefix}session_token';
  static const _deviceIdKey = '${_keyPrefix}device_id';
  static const _identityKeyHexKey = '${_keyPrefix}identity_key_hex';

  final FlutterSecureStorage _storage;

  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Stores a complete auth session after successful login/connect.
  Future<void> saveSession({
    required String backendToken,
    required int expiresAt,
    required String scope,
    required String username,
    required String email,
    String? sessionToken,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: backendToken),
      _storage.write(key: _expiresAtKey, value: expiresAt.toString()),
      _storage.write(key: _scopeKey, value: scope),
      _storage.write(key: _usernameKey, value: username),
      _storage.write(key: _emailKey, value: email),
      if (sessionToken != null)
        _storage.write(key: _sessionTokenKey, value: sessionToken),
    ]);
  }

  /// Retrieves the stored session, or null if no session is stored
  /// or the token has expired.
  Future<StoredSession?> loadSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    final expiresAtStr = await _storage.read(key: _expiresAtKey);
    if (expiresAtStr == null) return null;

    final expiresAt = int.tryParse(expiresAtStr);
    if (expiresAt == null) return null;

    // Check if the token has expired.
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowSeconds >= expiresAt) {
      await clearSession();
      return null;
    }

    final scope = await _storage.read(key: _scopeKey);
    final username = await _storage.read(key: _usernameKey);
    final email = await _storage.read(key: _emailKey);
    final sessionToken = await _storage.read(key: _sessionTokenKey);

    if (scope == null || username == null || email == null) {
      await clearSession();
      return null;
    }

    return StoredSession(
      backendToken: token,
      expiresAt: expiresAt,
      scope: scope,
      username: username,
      email: email,
      sessionToken: sessionToken,
    );
  }

  /// Stores the device's Ed25519 private key and backend-assigned device ID
  /// after successful device registration. These are used to construct the
  /// device proof required on subsequent logins.
  Future<void> saveDeviceCredentials({
    required String deviceId,
    required String identityKeyHex,
  }) async {
    await Future.wait([
      _storage.write(key: _deviceIdKey, value: deviceId),
      _storage.write(key: _identityKeyHexKey, value: identityKeyHex),
    ]);
  }

  /// Loads the stored device credentials, or null if this device has not
  /// been registered yet.
  Future<StoredDeviceCredentials?> loadDeviceCredentials() async {
    final deviceId = await _storage.read(key: _deviceIdKey);
    final identityKeyHex = await _storage.read(key: _identityKeyHexKey);
    if (deviceId == null || identityKeyHex == null) return null;
    return StoredDeviceCredentials(
      deviceId: deviceId,
      identityKeyHex: identityKeyHex,
    );
  }

  /// Clears all stored auth credentials (on logout).
  /// Device credentials are preserved — they're tied to this device's
  /// identity, not the session, and are needed for future logins.
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _scopeKey),
      _storage.delete(key: _usernameKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _sessionTokenKey),
    ]);
  }
}

/// A session restored from the OS keyring.
class StoredSession {
  final String backendToken;
  final int expiresAt;
  final String scope;
  final String username;
  final String email;
  final String? sessionToken;

  const StoredSession({
    required this.backendToken,
    required this.expiresAt,
    required this.scope,
    required this.username,
    required this.email,
    this.sessionToken,
  });

  bool get isFullyAuthenticated => scope == 'full';
}

/// Device identity credentials restored from the OS keyring.
class StoredDeviceCredentials {
  final String deviceId;
  final String identityKeyHex;

  const StoredDeviceCredentials({
    required this.deviceId,
    required this.identityKeyHex,
  });
}
