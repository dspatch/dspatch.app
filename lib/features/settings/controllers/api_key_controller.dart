// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'dart:typed_data';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/providers.dart';

part 'api_key_controller.g.dart';

/// HKDF info parameter for API key encryption/decryption.
const _kApiKeyCryptoContext = 'api_key';

@riverpod
class ApiKeyController extends _$ApiKeyController {
  @override
  FutureOr<void> build() {}

  Future<bool> createApiKey({
    required String name,
    required String providerLabel,
    required String plaintext,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final sdk = ref.read(sdkProvider);
      final encrypted = await sdk.encryptString(
        plaintext: plaintext,
        keyId: _kApiKeyCryptoContext,
      );
      await sdk.createApiKey(
        name: name,
        providerLabel: providerLabel,
        encryptedKey: encrypted,
        displayHint: _buildDisplayHint(plaintext),
      );
    });
    if (state.hasError) {
      toast('Failed to save API key', type: ToastType.error);
      return false;
    }
    toast('API key saved', type: ToastType.success);
    return true;
  }

  Future<bool> deleteApiKey(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sdkProvider).deleteApiKey(id: id);
    });
    if (state.hasError) {
      toast('Failed to delete API key', type: ToastType.error);
      return false;
    }
    toast('API key deleted', type: ToastType.success);
    return true;
  }

  /// Builds a masked preview like `sk-...abc1` from the plaintext key.
  /// Shows the first prefix (up to the first dash or 3 chars) and last 4 chars.
  static String _buildDisplayHint(String plaintext) {
    if (plaintext.length <= 8) return '\u2022' * plaintext.length;
    final dashIndex = plaintext.indexOf('-');
    final prefixEnd = (dashIndex > 0 && dashIndex <= 6) ? dashIndex + 1 : 3;
    final prefix = plaintext.substring(0, prefixEnd);
    final suffix = plaintext.substring(plaintext.length - 4);
    return '$prefix...$suffix';
  }

  Future<String?> decryptApiKey(Uint8List encryptedKey) async {
    try {
      return await ref.read(sdkProvider).decryptString(
            blob: encryptedKey,
            keyId: _kApiKeyCryptoContext,
          );
    } catch (e) {
      toast('Failed to decrypt API key', type: ToastType.error);
      return null;
    }
  }
}
