// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';
import '../../engine_client/engine_client.dart';

part 'auth_controller.g.dart';

/// Delegates all auth operations to [EngineClient] and exposes
/// an [AsyncValue] loading/error state for UI consumption.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  EngineClient get _client => ref.read(engineClientProvider);

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.login(
            username: username,
            password: password,
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> verify2fa({
    required String code,
    bool isBackupCode = false,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.verify2Fa(
            code: code,
            isBackupCode: isBackupCode,
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.register(
            username: username,
            email: email,
            password: password,
          );
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
      await _client.verifyEmail(code: code);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<Map<String, dynamic>?> setup2fa() async {
    state = const AsyncLoading();
    try {
      final data = await _client.setup2Fa();
      state = const AsyncData(null);
      return data;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Map<String, dynamic>?> confirm2fa(String code) async {
    state = const AsyncLoading();
    try {
      final data = await _client.confirm2Fa(code: code);
      // Stash backup codes so BackupCodesScreen can display them.
      final codes = (data['backup_codes'] as List<dynamic>?)?.cast<String>();
      ref.read(pendingBackupCodesProvider.notifier).state = codes;
      state = const AsyncData(null);
      return data;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> acknowledgeBackupCodes() async {
    state = const AsyncLoading();
    await _client.acknowledgeBackupCodes();
    state = const AsyncData(null);
  }

  Future<bool> registerDevice(Map<String, dynamic> request) async {
    state = const AsyncLoading();
    try {
      await _client.registerDevice(request: request);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _client.logout();
    state = const AsyncData(null);
  }
}
