// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists backend auth tokens and credentials in the OS keyring.
///
/// Uses macOS Keychain, Windows Credential Manager, or Linux libsecret
/// via [FlutterSecureStorage]. All values are encrypted at rest by the OS.
///
/// Writes are sequential (not concurrent) to avoid race conditions on
/// platforms where the backing store is a single file (e.g. Windows DPAPI).
class SecureTokenStore {
  static const _keyPrefix = 'dspatch_auth_';
  static const _tokenKey = '${_keyPrefix}backend_token';
  static const _expiresAtKey = '${_keyPrefix}expires_at';
  static const _scopeKey = '${_keyPrefix}scope';
  static const _usernameKey = '${_keyPrefix}username';
  static const _emailKey = '${_keyPrefix}email';
  static const _sessionTokenKey = '${_keyPrefix}session_token';
  final FlutterSecureStorage _storage;

  /// Device credential keys are scoped per-user so that multiple accounts
  /// on the same OS user can each have their own device identity.
  static String _deviceIdKey(String username) =>
      '$_keyPrefix${username}_device_id';
  static String _identityKeyHexKey(String username) =>
      '$_keyPrefix${username}_identity_key_hex';

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
    debugPrint('[TOKEN_STORE] saveSession: scope=$scope, user=$username');
    // Sequential writes — concurrent Future.wait can race on Windows where
    // the backing store is a single DPAPI-encrypted file.
    await _storage.write(key: _tokenKey, value: backendToken);
    await _storage.write(key: _expiresAtKey, value: expiresAt.toString());
    await _storage.write(key: _scopeKey, value: scope);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _emailKey, value: email);
    if (sessionToken != null) {
      await _storage.write(key: _sessionTokenKey, value: sessionToken);
    }
    debugPrint('[TOKEN_STORE] saveSession: done');
  }

  /// Retrieves the stored session, or null if no session is stored
  /// or the token has expired.
  Future<StoredSession?> loadSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      debugPrint('[TOKEN_STORE] loadSession: no token stored');
      return null;
    }

    final expiresAtStr = await _storage.read(key: _expiresAtKey);
    if (expiresAtStr == null) {
      debugPrint('[TOKEN_STORE] loadSession: no expiresAt stored');
      return null;
    }

    final expiresAt = int.tryParse(expiresAtStr);
    if (expiresAt == null) {
      debugPrint('[TOKEN_STORE] loadSession: invalid expiresAt=$expiresAtStr');
      return null;
    }

    // Check if the token has expired.
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowSeconds >= expiresAt) {
      debugPrint('[TOKEN_STORE] loadSession: token expired '
          '(now=$nowSeconds, expiresAt=$expiresAt)');
      await clearSession();
      return null;
    }

    final scope = await _storage.read(key: _scopeKey);
    final username = await _storage.read(key: _usernameKey);
    final email = await _storage.read(key: _emailKey);
    final sessionToken = await _storage.read(key: _sessionTokenKey);

    if (scope == null || username == null || email == null) {
      debugPrint('[TOKEN_STORE] loadSession: missing fields '
          '(scope=$scope, username=$username, email=$email)');
      await clearSession();
      return null;
    }

    debugPrint('[TOKEN_STORE] loadSession: scope=$scope, user=$username, '
        'isFullyAuthenticated=${scope == 'full'}');
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
  ///
  /// Credentials are keyed by [username] so each account on the same machine
  /// maintains its own device identity.
  Future<void> saveDeviceCredentials({
    required String username,
    required String deviceId,
    required String identityKeyHex,
  }) async {
    debugPrint('[TOKEN_STORE] saveDeviceCredentials: user=$username, deviceId=$deviceId');
    await _storage.write(key: _deviceIdKey(username), value: deviceId);
    await _storage.write(key: _identityKeyHexKey(username), value: identityKeyHex);
    debugPrint('[TOKEN_STORE] saveDeviceCredentials: done');
  }

  /// Loads the stored device credentials for [username], or null if this
  /// device has not been registered for that account yet.
  Future<StoredDeviceCredentials?> loadDeviceCredentials(String username) async {
    final deviceId = await _storage.read(key: _deviceIdKey(username));
    final identityKeyHex = await _storage.read(key: _identityKeyHexKey(username));
    debugPrint('[TOKEN_STORE] loadDeviceCredentials($username): '
        'deviceId=${deviceId != null ? 'present' : 'null'}, '
        'identityKeyHex=${identityKeyHex != null ? 'present' : 'null'}');
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
    debugPrint('[TOKEN_STORE] clearSession');
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _scopeKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _sessionTokenKey);
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
