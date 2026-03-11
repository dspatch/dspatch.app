// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_sdk/dspatch_sdk.dart';
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/providers.dart';

part 'auth_controller.g.dart';

/// Delegates all auth operations to [RustSdk] and exposes
/// an [AsyncValue] loading/error state for UI consumption.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(sdkProvider).login(
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
      await ref.read(sdkProvider).verify2Fa(
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
      await ref.read(sdkProvider).register(
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
      await ref.read(sdkProvider).verifyEmail(code: code);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<TotpSetupData?> setup2fa() async {
    state = const AsyncLoading();
    try {
      final data = await ref.read(sdkProvider).setup2Fa();
      state = const AsyncData(null);
      return data;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<BackupCodesData?> confirm2fa(String code) async {
    state = const AsyncLoading();
    try {
      final data = await ref.read(sdkProvider).confirm2Fa(code: code);
      // Stash backup codes so BackupCodesScreen can display them.
      ref.read(pendingBackupCodesProvider.notifier).state = data.backupCodes;
      state = const AsyncData(null);
      return data;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> acknowledgeBackupCodes() async {
    state = const AsyncLoading();
    await ref.read(sdkProvider).acknowledgeBackupCodes();
    state = const AsyncData(null);
  }

  Future<bool> registerDevice(DeviceRegistrationRequest request) async {
    state = const AsyncLoading();
    try {
      await ref.read(sdkProvider).registerDevice(request: request);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(sdkProvider).logout();
    state = const AsyncData(null);
  }
}
