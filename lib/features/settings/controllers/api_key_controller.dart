// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/providers.dart';
import '../../../engine_client/engine_client.dart';
import '../../../models/commands/commands.dart';

part 'api_key_controller.g.dart';

@riverpod
class ApiKeyController extends _$ApiKeyController {
  @override
  Future<void> build() async {}

  EngineClient get _client => ref.read(engineClientProvider);

  Future<bool> createApiKey({
    required String name,
    required String providerLabel,
    required String plaintext,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Encrypt the key via the engine.
      final encrypted = await _client.send(EncryptString(plaintext: plaintext));
      final encryptedValue = encrypted.ciphertext;
      await _client.send(CreateApiKey(name: name, value: encryptedValue, providerName: providerLabel));
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
      await _client.send(DeleteApiKey(id: id));
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
  static String buildDisplayHint(String plaintext) {
    if (plaintext.length <= 8) return '\u2022' * plaintext.length;
    final dashIndex = plaintext.indexOf('-');
    final prefixEnd = (dashIndex > 0 && dashIndex <= 6) ? dashIndex + 1 : 3;
    final prefix = plaintext.substring(0, prefixEnd);
    final suffix = plaintext.substring(plaintext.length - 4);
    return '$prefix...$suffix';
  }

  Future<String?> decryptApiKey(String encryptedValue) async {
    try {
      final result = await _client.send(DecryptString(ciphertext: encryptedValue));
      return result.plaintext;
    } catch (e) {
      toast('Failed to decrypt API key', type: ToastType.error);
      return null;
    }
  }
}
