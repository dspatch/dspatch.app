// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/models/commands/commands.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  late TestHarness harness;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Crypto', () {
    test('encrypt returns ciphertext different from plaintext', () async {
      final result = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': 'hello world'},
      ))).data;

      final ciphertext = result['ciphertext'] as String;
      expect(ciphertext, isNotEmpty);
      expect(ciphertext, isNot(equals('hello world')));
    });

    test('decrypt returns original plaintext', () async {
      final encResult = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': 'secret message'},
      ))).data;

      final ciphertext = encResult['ciphertext'] as String;

      final decResult = (await harness.client.send(RawEngineCommand(
        method: 'decrypt_string',
        params: {'ciphertext': ciphertext},
      ))).data;

      expect(decResult['plaintext'], equals('secret message'));
    });

    test('decrypt garbage data returns error', () async {
      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'decrypt_string',
          params: {'ciphertext': 'not-valid-hex-data'},
        )),
        throwsA(isA<EngineException>()),
      );
    });

    test('round-trip with special characters', () async {
      const original = 'hello world -- "quotes" & <angle> \\ backslash';

      final encResult = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': original},
      ))).data;

      final ciphertext = encResult['ciphertext'] as String;

      final decResult = (await harness.client.send(RawEngineCommand(
        method: 'decrypt_string',
        params: {'ciphertext': ciphertext},
      ))).data;

      expect(decResult['plaintext'], equals(original));
    });

    test('encrypt empty string round-trips', () async {
      final encResult = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': ''},
      ))).data;

      final ciphertext = encResult['ciphertext'] as String;
      expect(ciphertext, isNotEmpty);

      final decResult = (await harness.client.send(RawEngineCommand(
        method: 'decrypt_string',
        params: {'ciphertext': ciphertext},
      ))).data;

      expect(decResult['plaintext'], equals(''));
    });

    test('nonce uniqueness: same plaintext produces different ciphertexts',
        () async {
      const plaintext = 'identical input';

      final enc1 = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': plaintext},
      ))).data;
      final enc2 = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': plaintext},
      ))).data;

      final ct1 = enc1['ciphertext'] as String;
      final ct2 = enc2['ciphertext'] as String;

      // AES-256-GCM uses a random nonce, so ciphertexts must differ.
      expect(ct1, isNot(equals(ct2)));
    });

    test('tamper detection: modified ciphertext fails to decrypt', () async {
      final encResult = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': 'tamper test'},
      ))).data;

      final ciphertext = encResult['ciphertext'] as String;

      // Flip the last character to simulate tampering.
      final lastChar = ciphertext[ciphertext.length - 1];
      final flipped = lastChar == '0' ? '1' : '0';
      final tampered =
          ciphertext.substring(0, ciphertext.length - 1) + flipped;

      expect(
        () => harness.client.send(RawEngineCommand(
          method: 'decrypt_string',
          params: {'ciphertext': tampered},
        )),
        throwsA(isA<EngineException>()),
      );
    });

    test('unicode round-trip: emoji and CJK characters', () async {
      // Emoji, CJK, Arabic, accented Latin, newlines.
      const original = 'Hello \u{1F600} \u4E16\u754C \u0645\u0631\u062D\u0628\u0627 caf\u00E9\nnewline';

      final encResult = (await harness.client.send(RawEngineCommand(
        method: 'encrypt_string',
        params: {'plaintext': original},
      ))).data;

      final ciphertext = encResult['ciphertext'] as String;

      final decResult = (await harness.client.send(RawEngineCommand(
        method: 'decrypt_string',
        params: {'ciphertext': ciphertext},
      ))).data;

      expect(decResult['plaintext'], equals(original));
    });
  });
}
