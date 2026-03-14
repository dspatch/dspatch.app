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

  group('Backend auth (requires localhost:3000)', () {
    test('login with invalid credentials returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('login', {
          'username': 'nonexistent_test_user_xyz',
          'password': 'wrong',
        }),
        throwsA(isA<EngineException>()),
      );
    });

    test('register with invalid email returns validation error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('register', {
          'username': 'test_user',
          'email': 'not-an-email',
          'password': 'short',
        }),
        throwsA(isA<EngineException>()),
      );
    });

    test('register with empty username returns error', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      expect(
        () => harness.client.sendCommand('register', {
          'username': '',
          'email': 'test@test.com',
          'password': 'validpass123',
        }),
        throwsA(isA<EngineException>()),
      );
    });

    test('auth_status without backend auth returns anonymous', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      final result = await harness.client.sendCommand('auth_status', {});

      // Without having logged in, the engine should report anonymous/unauthenticated.
      expect(result, contains('auth_mode'));
      expect(result['auth_mode'], equals('anonymous'));
    });

    test('logout without being logged in is graceful', () async {
      if (!await harness.isBackendAvailable()) {
        markTestSkipped('Backend not available at localhost:3000');
        return;
      }

      // Should either succeed as a no-op or throw a specific error, but not crash.
      try {
        final result = await harness.client.sendCommand('logout', {});
        // If it succeeds, that's fine — it's a graceful no-op.
        expect(result, isA<Map<String, dynamic>>());
      } on EngineException catch (e) {
        // A specific error is acceptable (e.g., "not logged in"),
        // as long as it doesn't crash the engine.
        expect(e.code, isNotEmpty);
      }
    });
  });
}
