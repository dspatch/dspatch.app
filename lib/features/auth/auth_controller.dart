// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';
import '../../engine_client/backend_auth.dart';
import '../../engine_client/engine_connection.dart';
import '../../engine_client/models/backend_auth_state.dart';
import '../../engine_client/secure_token_store.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<void> build() async {}

  BackendAuth get _backend => ref.read(backendAuthProvider);
  EngineConnection get _connection => ref.read(engineConnectionProvider);
  SecureTokenStore get _tokenStore => ref.read(secureTokenStoreProvider);

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    debugPrint('[LOGIN] login() called for user=$username');
    state = const AsyncLoading();
    try {
      // If this device has been registered before, construct the Ed25519
      // device proof that the backend requires for accounts with devices.
      String? deviceId;
      String? deviceSignature;
      int? deviceTimestamp;

      final deviceCreds = await _tokenStore.loadDeviceCredentials();
      if (deviceCreds != null) {
        debugPrint('[LOGIN] Found stored device credentials, signing proof...');
        deviceTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final message = 'login:$username:$deviceTimestamp';

        // Reconstruct the Ed25519 key pair from the stored private key seed.
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

      debugPrint('[LOGIN] Sending POST to backend...');
      final response = await _backend.login(
        username: username,
        password: password,
        deviceId: deviceId,
        deviceSignature: deviceSignature,
        deviceTimestamp: deviceTimestamp,
      );
      debugPrint(
        '[LOGIN] Backend responded: scope=${response.scope}, '
        'expiresAt=${response.expiresAt}, hasToken=${response.token.isNotEmpty}',
      );
      await _handleAuthResponse(response);
      // Clear loggedOut AFTER auth state is set so the router never sees
      // loggedOut=false with a null backendAuthState (which would let the
      // stale anonymous WS session through to /setup → workspaces).
      ref.read(loggedOutProvider.notifier).state = false;
      debugPrint('[LOGIN] login() complete, setting AsyncData');
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      debugPrint('[LOGIN] login() FAILED: $e\n$st');
      state = AsyncError(e, st);
      return false;
    }
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
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
      ref.read(loggedOutProvider.notifier).state = false;
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
      final backendState = ref.read(backendAuthStateProvider)!;
      final response =
          await _backend.verifyEmail(token: backendState.token, code: code);
      await _handleAuthResponse(response);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> resendVerification() async {
    final backendState = ref.read(backendAuthStateProvider)!;
    await _backend.resendVerification(token: backendState.token);
  }

  Future<Map<String, dynamic>> setup2fa() async {
    state = const AsyncLoading();
    try {
      final backendState = ref.read(backendAuthStateProvider)!;
      final response = await _backend.setup2fa(token: backendState.token);
      // setup2fa does NOT issue a new token — it only returns TOTP details.
      // The existing partial token remains valid.
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
      final backendState = ref.read(backendAuthStateProvider)!;
      final response =
          await _backend.confirm2fa(token: backendState.token, code: code);
      final codes = response.backupCodes;
      ref.read(pendingBackupCodesProvider.notifier).state = codes;

      // The backend returns scope 'device_registration', but we need to show
      // the backup codes screen first. Save the new token but use the
      // synthetic 'awaiting_backup_confirmation' scope locally. The
      // acknowledgeBackupCodes() method advances to 'device_registration'.
      final username =
          response.username ?? backendState.username;
      final email = response.email ?? backendState.email;

      await _tokenStore.saveSession(
        backendToken: response.token,
        expiresAt: response.expiresAt,
        scope: 'awaiting_backup_confirmation',
        username: username,
        email: email,
      );
      ref.read(backendAuthStateProvider.notifier).state = BackendAuthState(
        token: response.token,
        expiresAt: response.expiresAt,
        scope: 'awaiting_backup_confirmation',
        username: username,
        email: email,
      );

      state = const AsyncData(null);
      return {'backup_codes': codes};
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> acknowledgeBackupCodes() async {
    state = const AsyncLoading();
    final backendState = ref.read(backendAuthStateProvider)!;
    ref.read(backendAuthStateProvider.notifier).state = BackendAuthState(
      token: backendState.token,
      expiresAt: backendState.expiresAt,
      scope: 'device_registration',
      username: backendState.username,
      email: backendState.email,
    );
    ref.read(pendingBackupCodesProvider.notifier).state = null;
    state = const AsyncData(null);
  }

  Future<bool> verify2fa({
    required String code,
    bool isBackupCode = false,
  }) async {
    state = const AsyncLoading();
    try {
      final backendState = ref.read(backendAuthStateProvider)!;
      final response = await _backend.verify2fa(
        token: backendState.token,
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
      final backendState = ref.read(backendAuthStateProvider)!;
      final response = await _backend.registerDevice(
        token: backendState.token,
        body: request,
      );

      // Persist the device's Ed25519 private key and backend-assigned device
      // ID so that subsequent logins can construct the required device proof.
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

  Future<void> enterAnonymousMode() async {
    ref.read(loggedOutProvider.notifier).state = false;
    ref.read(backendAuthStateProvider.notifier).state = null;
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    // Fire the logout command without awaiting the response. Awaiting
    // would let the engine close the WS server-side, triggering
    // _onDisconnected → auto-reconnect before disconnect() runs.
    try {
      _connection.sendRaw(
        '{"type":"command","id":"logout","method":"logout","params":{}}',
      );
    } catch (_) {
      // Best-effort — the engine may already be unreachable.
    }

    // Disconnect immediately after sending. This bumps the epoch so any
    // in-flight auto-reconnect is invalidated.
    await _connection.disconnect();

    ref.read(backendAuthStateProvider.notifier).state = null;
    await _tokenStore.clearSession();

    // Mark DB as not ready and signal logout so the router redirects to
    // /auth/login instead of /setup (which would auto-connect as anonymous).
    ref.read(databaseReadyProvider.notifier).state = false;
    ref.read(loggedOutProvider.notifier).state = true;

    state = const AsyncData(null);
  }

  /// Saves the auth response to the keyring and updates the backend auth
  /// state provider. Engine reconnection (for scope == 'full') is handled
  /// by SetupScreen — the gateway all authenticated routes pass through.
  Future<void> _handleAuthResponse(BackendAuthResponse response) async {
    // Carry forward identity fields from the current state when the
    // backend response omits them (e.g. 2FA setup/confirm endpoints).
    final existing = ref.read(backendAuthStateProvider);
    final username = response.username ?? existing?.username ?? '';
    final email = response.email ?? existing?.email ?? '';

    debugPrint(
      '[LOGIN] _handleAuthResponse: scope=${response.scope}, '
      'username=$username, email=$email',
    );
    debugPrint('[LOGIN] Saving session to keyring...');
    await _tokenStore.saveSession(
      backendToken: response.token,
      expiresAt: response.expiresAt,
      scope: response.scope,
      username: username,
      email: email,
    );
    debugPrint('[LOGIN] Session saved. Updating backendAuthStateProvider...');

    ref.read(backendAuthStateProvider.notifier).state = BackendAuthState(
      token: response.token,
      expiresAt: response.expiresAt,
      scope: response.scope,
      username: username,
      email: email,
    );
    debugPrint('[LOGIN] backendAuthStateProvider updated');
  }
}
