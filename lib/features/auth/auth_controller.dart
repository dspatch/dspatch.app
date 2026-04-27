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
import '../hub/hub_providers.dart';

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

  /// In-flight refresh completer — any concurrent call joins this future
  /// instead of issuing a second request to the backend.
  Completer<void>? _refreshCompleter;

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

    // Concurrency guard — if a refresh is already in flight, join it
    // instead of issuing a duplicate request.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<void>();

    try {
      await _doRefresh();
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _doRefresh() async {
    const maxRetries = 3;
    int attempt = 0;

    while (true) {
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
        } catch (e) {
          debugPrint('[AUTH] Engine credential update failed (non-fatal): $e');
        }

        // Schedule next refresh.
        startRefreshTimer();
        return;
      } catch (e) {
        // 401/403 means the token is definitively rejected — log out immediately.
        if (_isAuthError(e)) {
          debugPrint('[AUTH] Token refresh rejected (${_statusCode(e)}), logging out');
          await logout();
          return;
        }

        attempt++;
        if (attempt >= maxRetries) {
          debugPrint('[AUTH] Token refresh failed after $maxRetries attempts: $e');
          await logout();
          return;
        }

        // Transient error — wait briefly and retry.
        debugPrint('[AUTH] Token refresh attempt $attempt failed (transient): $e — retrying');
        await Future.delayed(Duration(seconds: attempt * 2));

        // If we got logged out or the phase changed while waiting, abort.
        if (ref.read(authPhaseProvider) != AuthPhase.ready) return;
      }
    }
  }

  /// Returns true if [e] represents a definitive auth rejection (401/403).
  bool _isAuthError(Object e) {
    final code = _statusCode(e);
    return code == 401 || code == 403;
  }

  /// Attempts to extract an HTTP status code from [e], or returns null.
  int? _statusCode(Object e) {
    // BackendAuth throws exceptions whose toString contains the status code.
    // Match patterns like "401", "403", "status 401", etc.
    final s = e.toString();
    final match = RegExp(r'\b(4\d{2})\b').firstMatch(s);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
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

      final deviceCreds = await _tokenStore.loadDeviceCredentials(username);
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
      rethrow;
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

      // Sign the JWT with the device key if credentials are available.
      // The backend requires a device proof for accounts with registered
      // devices — the signed message is the raw Bearer token itself.
      String? deviceId;
      String? deviceSignature;
      final deviceCreds = await _tokenStore.loadDeviceCredentials(token.username);
      if (deviceCreds != null) {
        debugPrint('[AUTH] verify2fa: signing device proof');
        final seed = _hexToBytes(deviceCreds.identityKeyHex);
        final ed25519 = Ed25519();
        final keyPair = await ed25519.newKeyPairFromSeed(seed);
        final signature = await ed25519.sign(
          utf8.encode(token.token),
          keyPair: keyPair,
        );
        deviceSignature = base64.encode(signature.bytes);
        deviceId = deviceCreds.deviceId;
      }

      final response = await _backend.verify2fa(
        token: token.token,
        code: code,
        isBackupCode: isBackupCode,
        deviceId: deviceId,
        deviceSignature: deviceSignature,
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
      final username = response.username ??
          ((ref.read(authTokenProvider)) is BackendToken
              ? (ref.read(authTokenProvider) as BackendToken).username
              : '');
      debugPrint('[AUTH] registerDevice: deviceId=${deviceId ?? 'NULL'}, user=$username');
      if (deviceId != null && username.isNotEmpty) {
        await _tokenStore.saveDeviceCredentials(
          username: username,
          deviceId: deviceId,
          identityKeyHex: identityKeyHex,
        );
      } else {
        debugPrint('[AUTH] WARNING: backend did not return device_id — '
            'device credentials will not be saved');
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

  /// Resets app state for a fresh engine setup pass.
  ///
  /// Called when the engine session is lost (e.g., engine restarted and wiped
  /// its in-memory session store) but the user's backend token is still valid.
  /// Resets all engine-specific state so [SetupScreen] can re-establish the
  /// connection from scratch.
  void resetForReSetup() {
    debugPrint('[AUTH] resetForReSetup() — engine session lost, redirecting to setup');
    _refreshTimer?.cancel();
    _refreshTimer = null;

    ref.read(dbStateProvider.notifier).state = DbState.unknown;
    ref.read(engineSessionProvider.notifier).state = false;
    ref.read(databaseReadyProvider.notifier).state = false;

    // Phase → authenticated: has backend token, needs engine connection.
    // Router redirects to /setup, which creates a fresh SetupScreen.
    ref.read(authPhaseProvider.notifier).state = AuthPhase.authenticated;
  }

  Future<void> logout() async {
    debugPrint('[AUTH] logout()');
    _refreshTimer?.cancel();
    _refreshTimer = null;
    state = const AsyncLoading();

    // Fire-and-forget logout command.
    try {
      _connection.sendRaw(
        '{"type":"command","id":"logout","method":"logout","params":{}}',
      );
    } catch (e) {
      debugPrint('[AuthController] logout send failed (non-fatal): $e');
    }

    await _connection.disconnect();

    // Clear keyring (preserves device credentials).
    await _tokenStore.clearSession();

    // Reset engine state.
    ref.read(dbStateProvider.notifier).state = DbState.unknown;
    ref.read(engineSessionProvider.notifier).state = false;
    ref.read(databaseReadyProvider.notifier).state = false;

    // Clear liked slugs so they don't bleed into the next session.
    ref.read(likedAgentSlugsProvider.notifier).state = {};
    ref.read(likedWorkspaceSlugsProvider.notifier).state = {};

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
      'device_pairing' => AuthPhase.devicePairing,
      'full' => AuthPhase.authenticated,
      _ => AuthPhase.unauthenticated,
    };

    _transition(phase, token: token);
  }
}
