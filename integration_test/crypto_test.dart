// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
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
    test('encrypt returns value different from plaintext', () async {
      final result = await harness.client.sendCommand(
        'encrypt_string',
        {'plaintext': 'hello world'},
      );

      final encrypted = result['encrypted'] as String;
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals('hello world')));
    });

    test('decrypt returns original plaintext', () async {
      final encResult = await harness.client.sendCommand(
        'encrypt_string',
        {'plaintext': 'secret message'},
      );

      final encrypted = encResult['encrypted'] as String;

      final decResult = await harness.client.sendCommand(
        'decrypt_string',
        {'ciphertext': encrypted},
      );

      expect(decResult['plaintext'], equals('secret message'));
    });

    test('decrypt garbage data returns error', () async {
      expect(
        () => harness.client.sendCommand(
          'decrypt_string',
          {'ciphertext': 'not-valid-encrypted-data'},
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('round-trip with special characters', () async {
      const original = 'héllo 🌍 wörld — "quotes"';

      final encResult = await harness.client.sendCommand(
        'encrypt_string',
        {'plaintext': original},
      );

      final encrypted = encResult['encrypted'] as String;

      final decResult = await harness.client.sendCommand(
        'decrypt_string',
        {'ciphertext': encrypted},
      );

      expect(decResult['plaintext'], equals(original));
    });

    test('encrypt empty string', () async {
      try {
        final encResult = await harness.client.sendCommand(
          'encrypt_string',
          {'plaintext': ''},
        );

        final encrypted = encResult['encrypted'] as String;

        final decResult = await harness.client.sendCommand(
          'decrypt_string',
          {'ciphertext': encrypted},
        );

        expect(decResult['plaintext'], equals(''));
      } on EngineException {
        // Empty string encryption throwing is also acceptable behavior.
      }
    });
  });
}
