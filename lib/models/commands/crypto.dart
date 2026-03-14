// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for encryption/decryption.
///
/// Bug fix: `encrypt_string` takes only `plaintext` (no `key_id`).
/// Bug fix: `decrypt_string` takes `ciphertext` (not `value`).
library;

import '../engine_responses.dart';
import 'command.dart';

/// Bug fix: Rust expects only `plaintext`, not `plaintext` + `key_id`.
class EncryptString extends EngineCommand<EncryptionResult> {
  EncryptString({required this.plaintext});
  final String plaintext;

  @override
  String get method => 'encrypt_string';

  @override
  Map<String, dynamic> get params => {'plaintext': plaintext};

  @override
  EncryptionResult parseResponse(Map<String, dynamic> result) =>
      EncryptionResult.fromJson(result);
}

/// Bug fix: Rust expects `ciphertext`, not `value`.
class DecryptString extends EngineCommand<DecryptionResult> {
  DecryptString({required this.ciphertext});
  final String ciphertext;

  @override
  String get method => 'decrypt_string';

  @override
  Map<String, dynamic> get params => {'ciphertext': ciphertext};

  @override
  DecryptionResult parseResponse(Map<String, dynamic> result) =>
      DecryptionResult.fromJson(result);
}
