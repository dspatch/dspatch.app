// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';
import '../../engine_client/backend_auth.dart';
import '../../engine_client/engine_connection.dart';
import '../../engine_client/models/auth_phase.dart';
import '../../engine_client/models/auth_token.dart';
import '../../engine_client/models/db_state.dart';
import '../../engine_client/secure_token_store.dart';
import '../../models/commands/session.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<void> build() async {
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });
  }

  BackendAuth get _backend => ref.read(backendAuthProvider);
  EngineConnection get _connection => ref.read(engineConnectionProvider);
  SecureTokenStore get _tokenStore => ref.read(secureTokenStoreProvider);

  Timer? _refreshTimer;

  /// Starts a timer to refresh the backend token before it expires.
  /// Called when phase reaches ready with a BackendToken.
  void startRefreshTimer() {
    _refreshTimer?.cancel();
    final token = ref.read(authTokenProvider);
    if (token is! BackendToken) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final refreshAt = token.expiresAt - 300; // 5 minutes before expiry
    final delaySeconds = refreshAt - now;

    if (delaySeconds <= 0) {
      // Already expired or about to — refresh immediately.
      _refreshToken();
      return;
    }

    _refreshTimer = Timer(Duration(seconds: delaySeconds), _refreshToken);
  }

  Future<void> _refreshToken() async {
    // Guard against race with logout — if we're no longer in ready state,
    // the refresh is stale.
    if (ref.read(authPhaseProvider) != AuthPhase.ready) return;

    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) return;

      final response = await _backend.refreshToken(token: token.token);
      final username = response.username ?? token.username;
      final email = response.email ?? token.email;

      final newToken = BackendToken(
        token: response.token,
        expiresAt: response.expiresAt,
        scope: 'full',
        username: username,
        email: email,
      );

      ref.read(authTokenProvider.notifier).state = newToken;

      await _tokenStore.saveSession(
        backendToken: response.token,
        expiresAt: response.expiresAt,
        scope: 'full',
        username: username,
        email: email,
      );

      // Update engine's cached credentials via typed command.
      try {
        final client = ref.read(engineClientProvider);
        await client.send(RefreshCredentials(backendToken: response.token));
      } catch (_) {}

      // Schedule next refresh.
      startRefreshTimer();
    } catch (e) {
      debugPrint('[AUTH] Token refresh failed: $e');
      // Refresh failed — force re-login.
      await logout();
    }
  }

  /// Sets phase and token atomically. The router only watches authPhaseProvider,
  /// so setting token first ensures credentials are available before the
  /// router reacts to the phase change.
  void _transition(AuthPhase phase, {AuthToken? token, bool clearToken = false}) {
    debugPrint('[AUTH] transition -> $phase');
    if (clearToken) {
      ref.read(authTokenProvider.notifier).state = null;
    } else if (token != null) {
      ref.read(authTokenProvider.notifier).state = token;
    }
    ref.read(authPhaseProvider.notifier).state = phase;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    debugPrint('[LOGIN] login() called for user=$username');
    state = const AsyncLoading();
    try {
      String? deviceId;
      String? deviceSignature;
      int? deviceTimestamp;

      final deviceCreds = await _tokenStore.loadDeviceCredentials();
      if (deviceCreds != null) {
        debugPrint('[LOGIN] Found stored device credentials, signing proof...');
        deviceTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final message = 'login:$username:$deviceTimestamp';

        final seed = _hexToBytes(deviceCreds.identityKeyHex);
        final ed25519 = Ed25519();
        final keyPair = await ed25519.newKeyPairFromSeed(seed);
        final signature = await ed25519.sign(
          utf8.encode(message),
          keyPair: keyPair,
        );
        deviceSignature = base64.encode(signature.bytes);
        deviceId = deviceCreds.deviceId;
      }

      final response = await _backend.login(
        username: username,
        password: password,
        deviceId: deviceId,
        deviceSignature: deviceSignature,
        deviceTimestamp: deviceTimestamp,
      );

      await _handleAuthResponse(response);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      debugPrint('[LOGIN] login() FAILED: $e\n$st');
      state = AsyncError(e, st);
      return false;
    }
  }

  static List<int> _hexToBytes(String hex) {
    return List.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await _backend.register(
          username: username, email: email, password: password);
      await _handleAuthResponse(response);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> verifyEmail(String code) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) throw StateError('No backend token');
      final response =
          await _backend.verifyEmail(token: token.token, code: code);
      await _handleAuthResponse(response);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> resendVerification() async {
    final token = ref.read(authTokenProvider);
    if (token is! BackendToken) throw StateError('No backend token');
    await _backend.resendVerification(token: token.token);
  }

  Future<Map<String, dynamic>> setup2fa() async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) throw StateError('No backend token');
      final response = await _backend.setup2fa(token: token.token);
      state = const AsyncData(null);
      return {'totp_uri': response.totpUri, 'secret': response.secret};
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> confirm2fa(String code) async {
    state = const AsyncLoading();
    try {
      final backendToken = ref.read(authTokenProvider);
      if (backendToken is! BackendToken) throw StateError('No backend token');

      final response =
          await _backend.confirm2fa(token: backendToken.token, code: code);
      final codes = response.backupCodes;
      ref.read(pendingBackupCodesProvider.notifier).state = codes;

      final username = response.username ?? backendToken.username;
      final email = response.email ?? backendToken.email;

      final token = BackendToken(
        token: response.token,
        expiresAt: response.expiresAt,
        scope: 'awaiting_backup_confirmation',
        username: username,
        email: email,
      );

      await _tokenStore.saveSession(
        backendToken: response.token,
        expiresAt: response.expiresAt,
        scope: 'awaiting_backup_confirmation',
        username: username,
        email: email,
      );

      _transition(AuthPhase.backupCodes, token: token);

      state = const AsyncData(null);
      return {'backup_codes': codes};
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> acknowledgeBackupCodes() async {
    state = const AsyncLoading();
    final token = ref.read(authTokenProvider);
    if (token is! BackendToken) throw StateError('No backend token');

    final updated = BackendToken(
      token: token.token,
      expiresAt: token.expiresAt,
      scope: 'device_registration',
      username: token.username,
      email: token.email,
    );

    ref.read(pendingBackupCodesProvider.notifier).state = null;
    _transition(AuthPhase.deviceRegistration, token: updated);
    state = const AsyncData(null);
  }

  Future<bool> verify2fa({
    required String code,
    bool isBackupCode = false,
  }) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) throw StateError('No backend token');
      final response = await _backend.verify2fa(
        token: token.token,
        code: code,
        isBackupCode: isBackupCode,
      );
      await _handleAuthResponse(response);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> registerDevice(
    Map<String, dynamic> request, {
    required String identityKeyHex,
  }) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authTokenProvider);
      if (token is! BackendToken) throw StateError('No backend token');
      final response = await _backend.registerDevice(
        token: token.token,
        body: request,
      );

      final deviceId = response.deviceId;
      if (deviceId != null) {
        await _tokenStore.saveDeviceCredentials(
          deviceId: deviceId,
          identityKeyHex: identityKeyHex,
        );
      }

      await _handleAuthResponse(response);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Enter anonymous mode. The setup screen will obtain an anonymous token
  /// from the engine and establish the WS connection.
  Future<void> enterAnonymousMode() async {
    _transition(AuthPhase.authenticated, clearToken: true);
  }

  /// Stores an anonymous session token obtained by SetupScreen.
  /// Maintains the single-writer invariant for authTokenProvider.
  void setAnonymousToken({required String token, required int expiresAt}) {
    ref.read(authTokenProvider.notifier).state = AnonymousToken(
      token: token,
      expiresAt: expiresAt,
    );
  }

  /// Updates dbStateProvider. Called by SetupScreen when the engine
  /// command returns a state before the WS event arrives (fallback path).
  void setDbState(DbState state) {
    ref.read(dbStateProvider.notifier).state = state;
  }

  /// Called by SetupScreen after /auth/connect + WS handshake.
  void setConnecting() => _transition(AuthPhase.connecting);

  /// Called by SetupScreen when engine signals migration_pending.
  void setMigrating() => _transition(AuthPhase.migrating);

  /// Called by SetupScreen after DB is opened and preferences loaded.
  void setReady() => _transition(AuthPhase.ready);

  Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    state = const AsyncLoading();

    // Fire-and-forget logout command.
    try {
      _connection.sendRaw(
        '{"type":"command","id":"logout","method":"logout","params":{}}',
      );
    } catch (_) {}

    await _connection.disconnect();

    // Clear keyring (preserves device credentials).
    await _tokenStore.clearSession();

    // Reset engine state.
    ref.read(dbStateProvider.notifier).state = DbState.unknown;
    ref.read(engineSessionProvider.notifier).state = false;
    ref.read(databaseReadyProvider.notifier).state = false;

    // Atomic: clear token, then set phase. Router reacts to phase only.
    _transition(AuthPhase.unauthenticated, clearToken: true);

    state = const AsyncData(null);
  }

  /// Maps a backend auth response to the correct phase + token.
  Future<void> _handleAuthResponse(BackendAuthResponse response) async {
    final existing = ref.read(authTokenProvider);
    final username = response.username ??
        (existing is BackendToken ? existing.username : '');
    final email = response.email ??
        (existing is BackendToken ? existing.email : '');

    final token = BackendToken(
      token: response.token,
      expiresAt: response.expiresAt,
      scope: response.scope,
      username: username,
      email: email,
    );

    // Persist to keyring.
    await _tokenStore.saveSession(
      backendToken: response.token,
      expiresAt: response.expiresAt,
      scope: response.scope,
      username: username,
      email: email,
    );

    // Map backend scope to AuthPhase.
    final phase = switch (response.scope) {
      'email_verification' => AuthPhase.verifyEmail,
      'setup_2fa' => AuthPhase.setup2fa,
      'partial_2fa' => AuthPhase.verify2fa,
      'device_registration' => AuthPhase.deviceRegistration,
      'full' => AuthPhase.authenticated,
      _ => AuthPhase.unauthenticated,
    };

    _transition(phase, token: token);
  }
}
